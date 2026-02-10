#!/usr/bin/env bash
# capture.sh — Central wrapper for screencapture + sips post-processing
# Usage: capture.sh --target <type> [options] --output <path>
# Output on success: OK|<path>|<WxH>|<bytes>|<format>
# Exit codes: 0 = success, 1 = capture failed, 2 = post-processing failed, 3 = usage error

set -euo pipefail

# Defaults
TARGET=""
WINDOW_ID=""
REGION=""
DISPLAY_NUM=""
FORMAT="png"
DELAY=""
NO_SHADOW=false
SILENT=true
RESIZE=""
CROP=""
OUTPUT=""

usage() {
  cat >&2 << 'EOF'
Usage: capture.sh --target <type> [options] --output <path>

Targets:
  --target fullscreen    Capture the full screen
  --target window        Capture a specific window (requires --window-id)
  --target region        Capture a region (requires --region)
  --target display       Capture a specific display (requires --display)

Options:
  --window-id <id>       CGWindowID for window capture
  --region <x,y,w,h>     Rectangle for region capture
  --display <n>          Display number (1-based)
  --format <fmt>         Output format: png, jpg, heic, pdf, tiff, gif (default: png)
  --delay <sec>          Delay before capture in seconds
  --no-shadow            Exclude window shadow
  --silent               Suppress capture sound (default)
  --no-silent            Play capture sound
  --resize <WxH|MAX>     Resize after capture: WxH for exact, single number for max dimension
  --crop <WxH>           Center-crop after capture
  --output <path>        Output file path (required)
EOF
  exit 3
}

# Parse arguments
while [ $# -gt 0 ]; do
  case "$1" in
    --target)     TARGET="$2"; shift 2 ;;
    --window-id)  WINDOW_ID="$2"; shift 2 ;;
    --region)     REGION="$2"; shift 2 ;;
    --display)    DISPLAY_NUM="$2"; shift 2 ;;
    --format)     FORMAT="$2"; shift 2 ;;
    --delay)      DELAY="$2"; shift 2 ;;
    --no-shadow)  NO_SHADOW=true; shift ;;
    --silent)     SILENT=true; shift ;;
    --no-silent)  SILENT=false; shift ;;
    --resize)     RESIZE="$2"; shift 2 ;;
    --crop)       CROP="$2"; shift 2 ;;
    --output)     OUTPUT="$2"; shift 2 ;;
    -h|--help)    usage ;;
    *)            echo "Unknown option: $1" >&2; usage ;;
  esac
done

# Validate required args
if [ -z "$TARGET" ]; then
  echo "Error: --target is required" >&2
  usage
fi

if [ -z "$OUTPUT" ]; then
  echo "Error: --output is required" >&2
  usage
fi

# Ensure output directory exists
mkdir -p "$(dirname "$OUTPUT")"

# Build screencapture command
CMD=(screencapture)

# Silent mode
if $SILENT; then
  CMD+=(-x)
fi

# No shadow
if $NO_SHADOW; then
  CMD+=(-o)
fi

# Delay
if [ -n "$DELAY" ]; then
  CMD+=(-T "$DELAY")
fi

# Format
CMD+=(-t "$FORMAT")

# Target-specific flags
case "$TARGET" in
  fullscreen)
    # No extra flags needed for fullscreen
    ;;
  window)
    if [ -z "$WINDOW_ID" ]; then
      echo "Error: --window-id required for window capture" >&2
      exit 3
    fi
    CMD+=(-l "$WINDOW_ID")
    ;;
  region)
    if [ -z "$REGION" ]; then
      echo "Error: --region required for region capture" >&2
      exit 3
    fi
    CMD+=(-R "$REGION")
    ;;
  display)
    if [ -n "$DISPLAY_NUM" ]; then
      CMD+=(-D "$DISPLAY_NUM")
    fi
    ;;
  *)
    echo "Error: unknown target '$TARGET'. Use fullscreen, window, region, or display." >&2
    exit 3
    ;;
esac

# Output path
CMD+=("$OUTPUT")

# Execute capture
if ! "${CMD[@]}"; then
  echo "Error: screencapture failed" >&2
  exit 1
fi

# Verify file was created
if [ ! -f "$OUTPUT" ]; then
  echo "Error: capture file was not created at $OUTPUT" >&2
  exit 1
fi

# Post-processing with sips
if [ -n "$RESIZE" ]; then
  if [[ "$RESIZE" =~ ^[0-9]+$ ]]; then
    # Single number = max dimension (aspect-preserving)
    if ! sips -Z "$RESIZE" "$OUTPUT" --out "$OUTPUT" >/dev/null 2>&1; then
      echo "Error: sips resize (-Z $RESIZE) failed" >&2
      exit 2
    fi
  elif [[ "$RESIZE" =~ ^[0-9]+x[0-9]+$ ]]; then
    # WxH = exact resize
    W="${RESIZE%%x*}"
    H="${RESIZE##*x}"
    if ! sips -z "$H" "$W" "$OUTPUT" --out "$OUTPUT" >/dev/null 2>&1; then
      echo "Error: sips resize (-z $H $W) failed" >&2
      exit 2
    fi
  else
    echo "Error: invalid --resize format '$RESIZE'. Use a single number (max dim) or WxH." >&2
    exit 3
  fi
fi

if [ -n "$CROP" ]; then
  if [[ "$CROP" =~ ^[0-9]+x[0-9]+$ ]]; then
    W="${CROP%%x*}"
    H="${CROP##*x}"
    if ! sips -c "$H" "$W" "$OUTPUT" --out "$OUTPUT" >/dev/null 2>&1; then
      echo "Error: sips crop (-c $H $W) failed" >&2
      exit 2
    fi
  else
    echo "Error: invalid --crop format '$CROP'. Use WxH." >&2
    exit 3
  fi
fi

# Get final dimensions and size
PIXEL_W=$(sips -g pixelWidth "$OUTPUT" 2>/dev/null | tail -1 | awk '{print $2}')
PIXEL_H=$(sips -g pixelHeight "$OUTPUT" 2>/dev/null | tail -1 | awk '{print $2}')
FILE_SIZE=$(stat -f%z "$OUTPUT" 2>/dev/null || stat -c%s "$OUTPUT" 2>/dev/null || echo "unknown")

echo "OK|${OUTPUT}|${PIXEL_W}x${PIXEL_H}|${FILE_SIZE}|${FORMAT}"
