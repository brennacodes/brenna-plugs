---
name: import-ftr
description: "Import existing documentation files from any directory into for-the-record with auto-generated frontmatter and tags. User specifies the source."
disable-model-invocation: false
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "[<path>] [--dry-run]"
---

<purpose>
Import existing documentation files into `for-the-record/docs/`. The user specifies where to import from -- there is no default source directory. Generates proper frontmatter for each imported file.
</purpose>

<steps>

  <step id="load-config" number="1">
    <description>Load Configuration</description>

    <load-config>
      <action>Resolve the user's home directory.</action>
      <command language="bash" output="home" tool="Bash">echo $HOME</command>
      <constraint>Never pass `~` to the Read tool.</constraint>

      <read path="<home>/.things/config.json" output="config" />
      <if condition="config-missing">Tell the user: "Run `/things:setup-things` first." Then stop.<exit /></if>

      <read path="<home>/.things/for-the-record/preferences.json" output="preferences" />
      <if condition="preferences-missing">Tell the user: "Run `/setup-ftr` first." Then stop.<exit /></if>
    </load-config>
  </step>

  <step id="get-source" number="2">
    <description>Get Source Directory</description>

    <if condition="path-argument-provided">
      <action>Use the provided path as the source directory.</action>
    </if>

    <if condition="no-path-argument">
      <ask-user-question>
        <question>Where are the files you'd like to import?</question>
      </ask-user-question>
    </if>

    <action>Verify the path exists and is a directory.</action>
    <if condition="path-not-found">Tell the user: "Directory not found: <path>." Then stop.<exit /></if>
  </step>

  <step id="scan-source" number="3">
    <description>Scan Source Directory</description>

    <action>Scan the source directory for `.md` files. For each file, read the first ~10 lines to extract a brief description (first heading or first paragraph).</action>

    <if condition="no-files-found">Tell the user: "No markdown files found in <path>." Then stop.<exit /></if>

    <action>Show a numbered list:</action>
    <output>
    Files found in <source_dir>:
      1. filename.md -- "Brief description from content"
      2. another-file.md -- "Brief description"
      ...
    </output>

    <ask-user-question>
      <question>Which files would you like to import? Enter numbers (e.g., "1,3,5"), a range (e.g., "1-5"), or "all".</question>
    </ask-user-question>

    <if condition="--dry-run">
      <action>Show what WOULD happen for each selected file (generated filename, inferred tags, title) but don't write anything. Stop here.</action>
    </if>
  </step>

  <step id="import-files" number="4">
    <description>Import Selected Files</description>

    <action>For each selected file:</action>

    1. Read the full content
    2. Check if it already has YAML frontmatter
       - If yes: preserve existing frontmatter, add any missing required fields (`date`, `tags`)
       - If no: generate frontmatter:
         - `title`: from first `#` heading, or from filename (de-slugified)
         - `date`: from file modification time (`stat -f %Sm -t %Y-%m-%d <file>` on macOS)
         - `description`: first non-heading paragraph, truncated to 2 sentences
         - `detail_level`: `"detailed"` (imported files are typically full documents)
         - `source_type`: `"import"`
         - `tags`: auto-generated from content (technologies, keywords)
    3. Generate filename: `<date>-<slugified-title>.md`
    4. Write to `<home>/.things/for-the-record/docs/<filename>`

    <constraint>Do not delete source files. Imports are copies.</constraint>
  </step>

  <step id="git-workflow" number="5">
    <description>Handle Git Workflow</description>

    <git-workflow>
      <action>Read git workflow from `config.json` (`git.workflow`).</action>

      <if condition="workflow-auto">Automatically `git add`, `git commit -m "import: <N> documents into for-the-record"`, and `git push`.</if>
      <if condition="workflow-ask">
        <ask-user-question>
          <question>Commit and push the imported documents?</question>
          <option>Yes -- commit and push</option>
          <option>Commit only</option>
          <option>No -- I'll handle git myself</option>
        </ask-user-question>
      </if>
      <if condition="workflow-manual">Tell the user the files have been saved.</if>
    </git-workflow>
  </step>

  <step id="confirm" number="6">
    <description>Confirm</description>

    <completion-message>
    Imported <N> documents into for-the-record:

    <list of imported files with their generated titles and tags>

    Find them: `/things:search-things --tag <tag>` or browse `~/.things/for-the-record/docs/`
    </completion-message>
  </step>

</steps>
