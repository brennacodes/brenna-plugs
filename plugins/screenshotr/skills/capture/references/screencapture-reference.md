# screencapture Reference

macOS built-in screen capture utility. No installation required.

## Flags

| Flag | Description |
|------|-------------|
| `-l <windowid>` | Capture a specific window by CGWindowID |
| `-R <x,y,w,h>` | Capture a rectangular region (origin at top-left of main display) |
| `-D <display>` | Capture a specific display (1-based numbering) |
| `-T <seconds>` | Delay before capture |
| `-t <format>` | Output format: `png` (default), `jpg`, `heic`, `pdf`, `tiff`, `gif` |
| `-o` | Exclude window shadow from capture |
| `-x` | Suppress the capture sound |
| `-m` | Capture the main monitor only (fullscreen mode) |
| `-c` | Send capture to clipboard instead of file |

## Usage Patterns

```bash
# Fullscreen (silent, no shadow)
screencapture -x -o /path/to/output.png

# Specific window by ID
screencapture -x -o -l 12345 /path/to/output.png

# Region capture
screencapture -x -R 100,200,800,600 /path/to/output.png

# Specific display
screencapture -x -D 2 /path/to/output.png

# With delay and format
screencapture -x -T 3 -t jpg /path/to/output.jpg
```

## Format Notes

- **png** — lossless, supports transparency, largest file size. Best default.
- **jpg** — lossy compression, no transparency, smaller files. Good for photos/screenshots shared online.
- **heic** — efficient compression, good quality. macOS-native but less portable.
- **pdf** — vector-capable, good for documentation. Captures at screen resolution.
- **tiff** — lossless, large files. Rarely needed.
- **gif** — static only (no animation capture). Limited color palette.

## Limitations

- No built-in resize or crop — use `sips` for post-processing
- No URL/web page capture — must open in browser first, then capture the window
- Window must be on-screen to capture with `-l` (can be partially occluded)
- Retina displays capture at 2x resolution (a 1440px-wide screen produces a 2880px-wide image)
- Interactive modes (`-i`, `-W`) require user mouse input — not suitable for automation
