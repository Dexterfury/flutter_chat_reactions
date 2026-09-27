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

record() {
  local demo="$1" theme="$2"
  local log="$LOG_DIR/$demo-$theme.log"
  local video="$WORK/$demo-$theme.mp4"
  local gif="$OUT/${demo}_${theme}.gif"
  local rec_pid="" test_pid size
  local run_timeout="${RUN_TIMEOUT:-900}"
  local start timed_out=0 waited
  echo "==> $demo ($theme)"
  xcrun simctl ui "$UDID" appearance "$theme"
  flutter test integration_test/demo_script_test.dart -d "$UDID" \
    --dart-define=DEMO="$demo" --dart-define=THEME="$theme" >"$log" 2>&1 &
  test_pid=$!
  start="$SECONDS"
  # Poll until the run is over: the test process exited, a pass/fail line
  # (or DEMO_SCRIPT_END) shows up in the log, or the per-run timeout elapses
  # -- whichever comes first. `flutter test` on a simulator does not always
  # exit on its own once the Dart test body is done (a hung run must not
  # block the rest of the demos), so we can't just `wait` for it.
  while kill -0 "$test_pid" 2>/dev/null; do
    if [ -z "$rec_pid" ] && grep -qs DEMO_SCRIPT_START "$log"; then
      xcrun simctl io "$UDID" recordVideo --codec=h264 --force "$video" &
      rec_pid=$!
    fi
    if grep -Eqs \
      'DEMO_SCRIPT_END|All tests passed!|tests passed, |Some tests failed|Test failed\.' \
      "$log"; then
      break
    fi
    if [ "$((SECONDS - start))" -ge "$run_timeout" ]; then
      echo "error: $demo ($theme) exceeded ${run_timeout}s without finishing" >&2
      timed_out=1
      break
    fi
    sleep 0.2
  done

  # Stop the recording (best-effort: it may never have started, e.g. on a
  # failure before DEMO_SCRIPT_START).
  if [ -n "$rec_pid" ]; then
    kill -INT "$rec_pid" 2>/dev/null || true
    wait "$rec_pid" 2>/dev/null || true
  fi

  # Give flutter test up to 60s to exit on its own now that the run is over;
  # otherwise kill it and any children it spawned (e.g. xcodebuild/the test
  # runner) so a hung or timed-out run can never block the remaining demos.
  waited=0
  while kill -0 "$test_pid" 2>/dev/null && [ "$waited" -lt 60 ]; do
    sleep 1
    waited=$((waited + 1))
  done
  if kill -0 "$test_pid" 2>/dev/null; then
    echo "warning: flutter test for $demo ($theme) did not exit, killing it" >&2
    pkill -P "$test_pid" 2>/dev/null || true
    kill -9 "$test_pid" 2>/dev/null || true
  fi
  wait "$test_pid" 2>/dev/null || true

  # Decide pass/fail from the log, not the exit code: once we've had to kill
  # a hung or timed-out run, its exit status no longer reflects whether the
  # demo script actually passed.
  if [ "$timed_out" -eq 1 ] || ! grep -qs 'All tests passed!' "$log" ||
    ! grep -qs DEMO_SCRIPT_END "$log"; then
    cat "$log"
    echo "error: demo script failed: $demo ($theme)" >&2
    return 1
  fi
  if [ -z "$rec_pid" ]; then
    cat "$log"
    echo "error: DEMO_SCRIPT_START marker not seen for $demo ($theme)" >&2
    return 1
  fi
  ffmpeg -loglevel error -y -i "$video" -vf \
    "fps=20,scale=320:-1:flags=lanczos,split[a][b];[a]palettegen=stats_mode=diff[p];[b][p]paletteuse=dither=bayer:bayer_scale=5" \
    "$WORK/raw.gif"
  gifsicle -O3 --lossy=40 -o "$gif" "$WORK/raw.gif"
  size=$(wc -c <"$gif")
  echo "    $(basename "$gif"): $((size / 1024)) KB"
  if [ "$size" -gt "$MAX_BYTES" ]; then
    echo "warning: $(basename "$gif") is larger than 1.5 MB" >&2
  fi
}

for demo in "${DEMOS[@]}"; do
  for theme in "${THEME_LIST[@]}"; do
    record "$demo" "$theme"
  done
done

xcrun simctl status_bar "$UDID" clear
echo "GIFs written to $OUT"
