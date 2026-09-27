#!/usr/bin/env bash
# Records the example gallery's demo scripts on an iOS simulator and converts
# them to GIFs in doc/gifs/. macOS only. Needs Xcode, Flutter, ffmpeg, gifsicle.
#
#   tool/record_gifs.sh                  # every demo, light + dark
#   tool/record_gifs.sh messenger team   # selected demos
#   THEMES=light tool/record_gifs.sh     # light only
#   SIMULATOR_UDID=<udid> tool/record_gifs.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/doc/gifs"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
ALL_DEMOS=(quickstart messenger team telegram custom theming)
if [ "$#" -gt 0 ]; then DEMOS=("$@"); else DEMOS=("${ALL_DEMOS[@]}"); fi
read -r -a THEME_LIST <<< "${THEMES:-light dark}"
MAX_BYTES=$((1500 * 1024))

for tool in xcrun flutter ffmpeg gifsicle python3; do
  command -v "$tool" >/dev/null || { echo "error: $tool not found" >&2; exit 1; }
done

# Newest available "iPhone <n> Pro" simulator on the newest iOS runtime.
pick_simulator() {
  xcrun simctl list devices available --json | python3 -c '
import json, re, sys
best = None
for runtime, devices in json.load(sys.stdin)["devices"].items():
    m = re.search(r"iOS-(\d+)-(\d+)", runtime)
    if not m:
        continue
    version = (int(m.group(1)), int(m.group(2)))
    for d in devices:
        name = d["name"]
        if name.startswith("iPhone") and name.endswith(" Pro"):
            key = (version, name)
            if best is None or key > best[0]:
                best = (key, d["udid"])
if best is None:
    sys.exit("no available iPhone Pro simulator")
print(best[1])
'
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
  local log="$WORK/$demo-$theme.log"
  local video="$WORK/$demo-$theme.mp4"
  local gif="$OUT/${demo}_${theme}.gif"
  local rec_pid="" test_pid size
  echo "==> $demo ($theme)"
  xcrun simctl ui "$UDID" appearance "$theme"
  flutter test integration_test/demo_script_test.dart -d "$UDID" \
    --dart-define=DEMO="$demo" --dart-define=THEME="$theme" >"$log" 2>&1 &
  test_pid=$!
  # Start recording at DEMO_SCRIPT_START, stop at DEMO_SCRIPT_END.
  while kill -0 "$test_pid" 2>/dev/null; do
    if [ -z "$rec_pid" ] && grep -q DEMO_SCRIPT_START "$log"; then
      xcrun simctl io "$UDID" recordVideo --codec=h264 --force "$video" &
      rec_pid=$!
    fi
    if [ -n "$rec_pid" ] && grep -q DEMO_SCRIPT_END "$log"; then
      break
    fi
    sleep 0.2
  done
  if [ -n "$rec_pid" ]; then
    kill -INT "$rec_pid"
    wait "$rec_pid" || true
  fi
  if ! wait "$test_pid"; then
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
