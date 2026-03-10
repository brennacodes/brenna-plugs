---
name: list-windows
description: List open windows with app names, titles, and window IDs for targeted capture.
disable-model-invocation: false
allowed-tools: Read, Bash
---

<purpose>
List the currently open windows on the user's Mac so they can identify targets for `/capture-ss`.
</purpose>

<steps>

  <step id="get-window-list" number="1">
    <description>Get Window List</description>

    <action>Run the list-windows script.</action>

    <command language="bash" tool="Bash">
    bash "${CLAUDE_PLUGIN_ROOT}/scripts/list-windows.sh"
    </command>

    This outputs `APP_NAME|WINDOW_TITLE|WINDOW_ID|ON_SCREEN` lines.
  </step>

  <step id="format-as-table" number="2">
    <description>Format as Table</description>

    <action>Parse the output and display as a readable table.</action>

    <output-format>
    | App Name | Window Title | Window ID |
    |----------|--------------|-----------|
    | Finder | Documents | 1234 |
    | Safari | GitHub - brennacodes | 5678 |
    </output-format>

    <constraint>Only show on-screen windows. Sort by app name.</constraint>
  </step>

  <step id="suggest-follow-up" number="3">
    <description>Suggest Follow-Up</description>

    <completion-message>
    To capture a specific window:
    ```
    /capture-ss window "AppName"
    ```

    If there are multiple windows for the same app, the capture skill will let you choose which one.
    </completion-message>
  </step>

</steps>
