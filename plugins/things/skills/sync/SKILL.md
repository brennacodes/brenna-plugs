---
name: sync
description: "Git push/pull/status for the .things/ repository. Use when user says 'sync things', 'push things', 'pull things', 'things git status'."
disable-model-invocation: true
allowed-tools: Read, Bash, AskUserQuestion
argument-hint: "<push|pull|status>"
---

<purpose>
Git workflow for the `.things/` repository.
</purpose>

<steps>

  <step id="load-config" number="1">
    <description>Load Configuration</description>

    <load-config>
    Resolve the user's home directory (run `echo $HOME` via Bash). Use this absolute path for all file operations below -- never pass `~` to the Read tool.

    1. Read `<home>/.things/config.json`

    <if condition="config-missing">Tell the user to run `/things:setup`.</if>

    <validate>
    Check that a git remote is configured in `config.json`.
    <if condition="no-remote-configured">
    <output>No git remote configured for `.things/`. Use `/things:setup reconfigure` to add one.</output>
    </if>
    </validate>
    </load-config>
  </step>

  <step id="parse-arguments" number="2">
    <description>Parse Arguments</description>

    Parse `$ARGUMENTS` for subcommand: `push`, `pull`, or `status`.

    <if condition="no-argument">
    <ask-user>
    Ask via AskUserQuestion:
    <options>
    - Status -- see current git state
    - Pull -- fetch and merge remote changes
    - Push -- commit and push local changes
    </options>
    </ask-user>
    </if>
  </step>

  <step id="execute-subcommand" number="3">
    <description>Execute Subcommand</description>

    <step name="exec-status">
    Subcommand: `status`

    ```bash
    git -C <home>/.things status
    git -C <home>/.things log --oneline -5
    ```

    <if condition="remote-configured">

    ```bash
    git -C <home>/.things fetch --dry-run 2>&1
    ```

    </if>

    <extract>Show: current branch, uncommitted changes, last 5 commits, ahead/behind remote.</extract>
    </step>

    <step name="exec-pull">
    Subcommand: `pull`

    ```bash
    git -C <home>/.things pull --rebase 2>&1
    ```

    <if condition="merge-conflicts">
    <phase name="show-conflicts" number="1">
    Show the conflicting files.
    </phase>

    <phase name="resolve-conflicts" number="2">
    <ask-user>
    Ask the user via AskUserQuestion:
    <options>
    - Abort the rebase and keep my local changes
    - Accept remote changes for all conflicts
    - Let me resolve manually
    </options>
    </ask-user>
    </phase>

    <if condition="user-chose-abort">

    ```bash
    git -C <home>/.things rebase --abort
    ```

    </if>

    <if condition="user-chose-accept-remote">
    For each conflicting file:

    ```bash
    git -C <home>/.things checkout --theirs <file> && git -C <home>/.things add <file>
    ```

    Then:

    ```bash
    git -C <home>/.things rebase --continue
    ```

    </if>
    </if>
    </step>

    <step name="exec-push">
    Subcommand: `push`

    <phase name="pull-first" number="1">
    Pull first (rebase):

    ```bash
    git -C <home>/.things pull --rebase 2>/dev/null || true
    ```
    </phase>

    <phase name="stage-changes" number="2">
    Stage all changes:

    ```bash
    git -C <home>/.things add -A
    ```
    </phase>

    <phase name="check-for-changes" number="3">
    Check if there are changes to commit:

    ```bash
    git -C <home>/.things diff --cached --quiet
    ```
    </phase>

    <phase name="commit" number="4">
    <if condition="changes-to-commit">
    Commit:

    ```bash
    git -C <home>/.things commit -m "sync: $(date +%Y-%m-%d\ %H:%M)"
    ```

    </if>
    </phase>

    <phase name="push" number="5">
    Push:

    ```bash
    git -C <home>/.things push
    ```
    </phase>
    </step>
  </step>

  <step id="confirm" number="4">
    <description>Confirm</description>

    <completion-message>
    Show the result of the operation and current git state.
    </completion-message>
  </step>

</steps>
