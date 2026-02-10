---
name: list-windows
description: List open windows with app names, titles, and window IDs for targeted capture.
disable-model-invocation: false
allowed-tools: Read, Bash
---

# List Windows

You are listing the currently open windows on the user's Mac so they can identify targets for `/screenshotr:capture`.

## Steps

### 1. Get Window List

Run the list-windows script:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/list-windows.sh"
```

This outputs `APP_NAME|WINDOW_TITLE|WINDOW_ID|ON_SCREEN` lines.

### 2. Format as Table

Parse the output and display as a readable table:

| App Name | Window Title | Window ID |
|----------|--------------|-----------|
| Finder | Documents | 1234 |
| Safari | GitHub - brennacodes | 5678 |

Only show on-screen windows. Sort by app name.

### 3. Suggest Follow-Up

After the table, suggest usage:

> To capture a specific window:
> ```
> /screenshotr:capture window "AppName"
> ```

If there are multiple windows for the same app, note that the capture skill will let them choose which one.
