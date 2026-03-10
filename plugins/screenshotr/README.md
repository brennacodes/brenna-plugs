# screenshotr

Precise screenshot capabilities for macOS - capture screens, windows, regions, or URLs with resize, crop, delay, and format control.

Built on macOS-native `screencapture` and `sips` - zero external dependencies.

## Installation

```
/plugin install screenshotr@brenna-plugs
```

## Skills

### Setup

Configure output directory, format, naming conventions, and capture preferences.

```
/setup-ss
```

### Capture

Full-control screenshot capture with target selection, post-processing, and format options.

```
/capture-ss
```

```
/capture-ss window "Safari"
```

```
/capture-ss region 100,200,800,600
```

```
/capture-ss url "https://example.com"
```

```
/capture-ss display 2
```

```
/capture-ss window "Xcode" --format jpg --resize 1280 --name xcode-debug
```

### List Windows

List open windows with app names, titles, and window IDs.

```
/list-windows
```

### Screenshot (Auto-Invoked)

Claude can invoke this automatically when conversation context suggests a screenshot is needed - "let me see what that looks like", "capture the current state", etc.

## Agent

### Capture Workflow

Multi-screenshot workflows for documentation:

- **Step-by-Step Tutorial** - capture at each step with sequential naming
- **Responsive Breakpoints** - resize browser and capture at multiple viewport widths
- **Before/After** - capture two states of a change
- **App Tour** - capture every window for an app
- **Timed Interval** - periodic captures at configurable intervals

## Requirements

- macOS (uses `screencapture` and `sips`)
- Screen Recording permission (System Preferences > Privacy & Security)
- Python3 with PyObjC recommended for reliable window detection (ships with Xcode CLI tools), JXA fallback available
