#!/usr/bin/env bash
# Records the example gallery's demo scripts on an iOS simulator and converts
# them to GIFs in doc/gifs/. macOS only. Needs Xcode, Flutter, ffmpeg, gifsicle.
#
#   tool/record_gifs.sh                  # every demo, light + dark
#   tool/record_gifs.sh messenger team   # selected demos
#   THEMES=light tool/record_gifs.sh     # light only
#   SIMULATOR_UDID=<udid> tool/record_gifs.sh
#   RECORD_LOG_DIR=<dir> tool/record_gifs.sh   # keep per-run logs after exit
#   RUN_TIMEOUT=<seconds> tool/record_gifs.sh  # per-demo timeout (default 900)
#   RUN_RETRIES=<n> tool/record_gifs.sh        # infra-failure retries (default 1)
#
# A failed run leaves <demo>-<theme>.log, a -failure.png screenshot and the
# partial .mp4 in RECORD_LOG_DIR. A run that fails before DEMO_SCRIPT_START
# appears in the log (an infrastructure failure, e.g. a simulator/tooling
# glitch) is retried; its log/screenshot are kept as
# <demo>-<theme>-attemptN.log/.png.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/doc/gifs"
WORK="$(mktemp -d)"
LOG_DIR="${RECORD_LOG_DIR:-$WORK}"
mkdir -p "$LOG_DIR"
cleanup() {
  # Stop any recording/test processes we may have left running, best-effort.
  # (No xargs here: xargs -r is a GNU extension that macOS/BSD xargs rejects.)
  local pids
  pids="$(jobs -p)"
  if [ -n "$pids" ]; then
    kill $pids 2>/dev/null || true
  fi
  if [ -n "${UDID:-}" ]; then
    xcrun simctl status_bar "$UDID" clear 2>/dev/null || true
  fi
  rm -rf "$WORK"
}
trap cleanup EXIT
ALL_DEMOS=(quickstart messenger team telegram custom theming)
ALL_THEMES=(light dark)
if [ "$#" -gt 0 ]; then DEMOS=("$@"); else DEMOS=("${ALL_DEMOS[@]}"); fi
read -r -a THEME_LIST <<< "${THEMES:-light dark}"
MAX_BYTES=$((1500 * 1024))

is_in() {
  local needle="$1"; shift
  local hay
  for hay in "$@"; do
    [ "$hay" = "$needle" ] && return 0
  done
  return 1
}

# Validate arguments before touching any macOS-only tool, so a typo fails
# fast (and fails the same way in CI and locally).
for demo in "${DEMOS[@]}"; do
  if ! is_in "$demo" "${ALL_DEMOS[@]}"; then
    echo "error: unknown demo '$demo' (valid: ${ALL_DEMOS[*]})" >&2
    exit 2
  fi
done
for theme in "${THEME_LIST[@]}"; do
  if ! is_in "$theme" "${ALL_THEMES[@]}"; then
    echo "error: unknown theme '$theme' (valid: ${ALL_THEMES[*]})" >&2
    exit 2
  fi
done

for tool in xcrun flutter ffmpeg gifsicle python3; do
  command -v "$tool" >/dev/null || { echo "error: $tool not found" >&2; exit 1; }
done

# Newest available "iPhone <n> Pro" simulator on a runtime no newer than the
# default Xcode's SDK. GitHub's macOS images can have beta simulator runtimes
# installed that are newer than the default Xcode's SDK; `flutter test` fails
# against those at the xcodebuild step, so they must be excluded.
pick_simulator() {
  local sdk_version
  sdk_version="$(xcrun --sdk iphonesimulator --show-sdk-version)"
  xcrun simctl list devices available --json | python3 -c '
import json, re, sys

sdk = tuple(int(p) for p in sys.argv[1].split(".")[:2])
best = None
for runtime, devices in json.load(sys.stdin)["devices"].items():
    m = re.search(r"iOS-(\d+)-(\d+)", runtime)
    if not m:
        continue
    version = (int(m.group(1)), int(m.group(2)))
    if version > sdk:
        continue
    for d in devices:
        name = d["name"]
        if name.startswith("iPhone") and name.endswith(" Pro"):
            key = (version, name)
            if best is None or key > best[0]:
                best = (key, d["udid"])
if best is None:
    sys.exit("no available iPhone Pro simulator at or below SDK " + sys.argv[1])
print(best[1])
' "$sdk_version"
}

UDID="${SIMULATOR_UDID:-$(pick_simulator)}"
echo "Using simulator $UDID"
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b
xcrun simctl status_bar "$UDID" override --time 9:41 --dataNetwork wifi \
  --wifiBars 3 --cellularBars 4 --batteryState charged --batteryLevel 100

mkdir -p "$OUT"
cd "$ROOT/example"
flutter pub get >/dev/null

# The example app's iOS bundle id (Runner's PRODUCT_BUNDLE_IDENTIFIER), used
# to stop the app after each run so the next one starts clean.
APP_BUNDLE_ID="$(sed -n 's/.*PRODUCT_BUNDLE_IDENTIFIER = \([^;]*\);.*/\1/p' \
  "$ROOT/example/ios/Runner.xcodeproj/project.pbxproj" | tr -d '\r' |
  grep -v RunnerTests | head -n 1 || true)"
# `flutter test` output lines that mean the run failed. The expanded reporter
# prints "Test failed." / "Some tests failed."; the github reporter (the
# default on GitHub Actions) prints "0 tests passed, 1 failed.".
FAIL_PATTERN='Test failed\.|Some tests failed|tests? passed, [0-9]+ failed'
# Log lines that mean the simulator/tooling failed before the demo script
# itself ran (a known intermittent iOS-simulator issue, not a demo failure).
# A run ended by one of these is retried when DEMO_SCRIPT_START never
# appeared (see attempt_once/record below).
INFRA_PATTERN='No tests ran\.|Error waiting for a debug connection'

# Sends SIGTERM to $1 and its children, waits up to $2 seconds for it to exit,
# then SIGKILLs whatever is left.
stop_process() {
  local pid="$1" grace="$2" waited=0
  kill -0 "$pid" 2>/dev/null || return 0
  pkill -TERM -P "$pid" 2>/dev/null || true
  kill -TERM "$pid" 2>/dev/null || true
  while kill -0 "$pid" 2>/dev/null && [ "$waited" -lt "$grace" ]; do
    sleep 1
    waited=$((waited + 1))
  done
  if kill -0 "$pid" 2>/dev/null; then
    pkill -9 -P "$pid" 2>/dev/null || true
    kill -9 "$pid" 2>/dev/null || true
  fi
}

# Runs one attempt at recording $demo/$theme, writing the flutter-test log to
# $log and, on failure, a screenshot to $png. Returns 0 on success, 1 on a
# real demo failure (a failure line appeared after DEMO_SCRIPT_START, so a
# retry would not help), or 2 on an infrastructure failure (DEMO_SCRIPT_START
# never appeared in the log, e.g. a simulator/tooling glitch). On a return of
# 1 or 2, sets the global ATTEMPT_REASON to the log line (or condition) that
# ended the run, for the caller to report.
ATTEMPT_REASON=""
attempt_once() {
  local demo="$1" theme="$2" log="$3" png="$4"
  local video="$WORK/$demo-$theme.mp4"
  local gif="$OUT/${demo}_${theme}.gif"
  local rec_pid="" test_pid size
  local run_timeout="${RUN_TIMEOUT:-900}"
  local start timed_out=0 failed=0 waited
  echo "==> $demo ($theme)"
  xcrun simctl ui "$UDID" appearance "$theme"
  flutter test integration_test/demo_script_test.dart -d "$UDID" \
    --reporter expanded \
    --dart-define=DEMO="$demo" --dart-define=THEME="$theme" >"$log" 2>&1 &
  test_pid=$!
  start="$SECONDS"
  # Poll until the run is over: the test process exited, DEMO_SCRIPT_END, a
  # failure line, or an infrastructure-failure line shows up in the log, or
  # the per-run timeout elapses -- whichever comes first. `flutter test` on a
  # simulator does not always exit on its own once the Dart test body is done
  # (a hung run must not block the rest of the demos), so we can't just
  # `wait` for it.
  while kill -0 "$test_pid" 2>/dev/null; do
    if [ -z "$rec_pid" ] && grep -qs DEMO_SCRIPT_START "$log"; then
      xcrun simctl io "$UDID" recordVideo --codec=h264 --force "$video" &
      rec_pid=$!
    fi
    if grep -Eqs "DEMO_SCRIPT_END|All tests passed!|$FAIL_PATTERN|$INFRA_PATTERN" "$log"; then
      break
    fi
    if [ "$((SECONDS - start))" -ge "$run_timeout" ]; then
      echo "error: $demo ($theme) exceeded ${run_timeout}s without finishing" >&2
      timed_out=1
      break
    fi
    sleep 0.2
  done

  # Pass only if the script reached its end and no failure was reported. The
  # exit code is not used: a hung run has to be killed, and a killed process's
  # status says nothing about the demo. (Checked again after the process has
  # exited, since failure lines can follow DEMO_SCRIPT_END.)
  if [ "$timed_out" -eq 1 ] || ! grep -qs DEMO_SCRIPT_END "$log" ||
    grep -Eqs "$FAIL_PATTERN|$INFRA_PATTERN" "$log"; then
    failed=1
    # Capture what the simulator shows before anything is torn down.
    xcrun simctl io "$UDID" screenshot "$png" >/dev/null 2>&1 || true
  fi

  # Stop the recording (best-effort: it may never have started, e.g. on a
  # failure before DEMO_SCRIPT_START). SIGINT makes simctl finalize the file.
  if [ -n "$rec_pid" ]; then
    kill -INT "$rec_pid" 2>/dev/null || true
    waited=0
    while kill -0 "$rec_pid" 2>/dev/null && [ "$waited" -lt 10 ]; do
      sleep 1
      waited=$((waited + 1))
    done
    kill -9 "$rec_pid" 2>/dev/null || true
    wait "$rec_pid" 2>/dev/null || true
  fi
  if [ "$failed" -eq 1 ] && [ -f "$video" ]; then
    # $WORK is deleted on exit; keep the partial video with the logs.
    cp "$video" "$LOG_DIR/" 2>/dev/null || true
  fi

  # Give flutter test up to 60s to exit on its own now that the run is over
  # (right away on failure); then stop it and any children it spawned (e.g.
  # xcodebuild) so a hung or timed-out run can never block the remaining
  # demos, and stop the app so the next run starts clean.
  waited=0
  while [ "$failed" -eq 0 ] && kill -0 "$test_pid" 2>/dev/null &&
    [ "$waited" -lt 60 ]; do
    sleep 1
    waited=$((waited + 1))
  done
  if kill -0 "$test_pid" 2>/dev/null; then
    echo "warning: flutter test for $demo ($theme) did not exit, stopping it" >&2
    stop_process "$test_pid" 5
  fi
  wait "$test_pid" 2>/dev/null || true
  if [ -n "$APP_BUNDLE_ID" ]; then
    xcrun simctl terminate "$UDID" "$APP_BUNDLE_ID" >/dev/null 2>&1 || true
  fi

  if [ "$failed" -eq 0 ] && grep -Eqs "$FAIL_PATTERN|$INFRA_PATTERN" "$log"; then
    failed=1
  fi
  if [ "$failed" -eq 0 ] && [ -z "$rec_pid" ]; then
    failed=1
  fi

  if [ "$failed" -eq 0 ]; then
    ffmpeg -loglevel error -y -i "$video" -vf \
      "fps=20,scale=320:-1:flags=lanczos,split[a][b];[a]palettegen=stats_mode=diff[p];[b][p]paletteuse=dither=bayer:bayer_scale=5" \
      "$WORK/raw.gif"
    gifsicle -O3 --lossy=40 -o "$gif" "$WORK/raw.gif"
    size=$(wc -c <"$gif")
    echo "    $(basename "$gif"): $((size / 1024)) KB"
    if [ "$size" -gt "$MAX_BYTES" ]; then
      echo "warning: $(basename "$gif") is larger than 1.5 MB" >&2
    fi
    return 0
  fi

  # A failure before DEMO_SCRIPT_START ever appeared is an infrastructure
  # failure (simulator/tooling), regardless of which line or condition ended
  # the run; a failure after DEMO_SCRIPT_START is a real demo failure.
  if [ "$timed_out" -eq 1 ]; then
    ATTEMPT_REASON="exceeded ${run_timeout}s without finishing"
  else
    ATTEMPT_REASON="$(grep -Em1 "$FAIL_PATTERN|$INFRA_PATTERN" "$log" 2>/dev/null || true)"
    [ -n "$ATTEMPT_REASON" ] || ATTEMPT_REASON="DEMO_SCRIPT_END not found in log"
  fi
  if [ -z "$rec_pid" ]; then
    return 2
  fi
  cat "$log"
  echo "error: demo script failed: $demo ($theme)" >&2
  return 1
}

# Runs $demo/$theme, retrying up to RUN_RETRIES times (default 1) when a run
# fails as an infrastructure failure (see attempt_once). A real demo failure
# is never retried.
record() {
  local demo="$1" theme="$2"
  local run_retries="${RUN_RETRIES:-1}"
  local log="$LOG_DIR/$demo-$theme.log"
  local png="$LOG_DIR/$demo-$theme-failure.png"
  local attempt=1 status

  while true; do
    ATTEMPT_REASON=""
    status=0
    attempt_once "$demo" "$theme" "$log" "$png" || status=$?
    if [ "$status" -eq 0 ]; then
      return 0
    fi
    if [ "$status" -eq 2 ] && [ "$attempt" -le "$run_retries" ]; then
      echo "retrying $demo ($theme) after infrastructure failure: $ATTEMPT_REASON"
      mv -f "$log" "$LOG_DIR/$demo-$theme-attempt${attempt}.log" 2>/dev/null || true
      if [ -f "$png" ]; then
        mv -f "$png" "$LOG_DIR/$demo-$theme-attempt${attempt}.png" 2>/dev/null || true
      fi
      # Give the simulator a clean slate before retrying: a debug-connection
      # or "no tests ran" failure can leave it in a bad state.
      xcrun simctl shutdown "$UDID" 2>/dev/null || true
      xcrun simctl boot "$UDID" 2>/dev/null || true
      xcrun simctl bootstatus "$UDID" -b
      xcrun simctl status_bar "$UDID" override --time 9:41 --dataNetwork wifi \
        --wifiBars 3 --cellularBars 4 --batteryState charged --batteryLevel 100
      attempt=$((attempt + 1))
      continue
    fi
    if [ "$status" -eq 2 ]; then
      cat "$log"
      echo "error: DEMO_SCRIPT_START marker not seen for $demo ($theme) after $attempt attempt(s)" >&2
    fi
    return 1
  done
}

for demo in "${DEMOS[@]}"; do
  for theme in "${THEME_LIST[@]}"; do
    record "$demo" "$theme"
  done
done

xcrun simctl status_bar "$UDID" clear
echo "GIFs written to $OUT"
