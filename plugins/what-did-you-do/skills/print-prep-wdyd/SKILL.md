---
name: print-prep-wdyd
description: "Create a styled, printable HTML version of a prep document and open it in the browser"
disable-model-invocation: true
allowed-tools: Read, Write, Bash, Glob, Grep, AskUserQuestion
argument-hint: "[filename or company name]"
---

<references>
  - references/printable-template.html
</references>

<purpose>
Convert a prep document from `~/.things/what-did-you-do/prep-docs/` into a styled, printable HTML file. The HTML uses a dark theme with readable typography and is optimized for both screen reading and printing. Output is saved to `~/.things/what-did-you-do/printable-prep-docs/` and opened in the default browser.
</purpose>

<steps>

  <step id="load-config" number="1">
    <description>Load Configuration</description>

    <load-config>
      <action>Resolve the user's home directory.</action>
      <command language="bash" output="home" tool="Bash">echo $HOME</command>
      <constraint>Never pass `~` to the Read tool.</constraint>

      <read path="<home>/.things/config.json" output="config" />

      <command language="bash" tool="Bash">mkdir -p <home>/.things/what-did-you-do/printable-prep-docs</command>
    </load-config>
  </step>

  <step id="resolve-source" number="2">
    <description>Resolve Source Prep Document</description>

    <if condition="argument-provided">
      <action>Check if the argument is an exact filename in `<home>/.things/what-did-you-do/prep-docs/`. If not, search for a file matching the argument as a substring (company name, date, etc.).</action>
    </if>

    <if condition="no-argument">
      <action>List all files in `<home>/.things/what-did-you-do/prep-docs/`.</action>

      <if condition="no-prep-docs-exist">
        <action>Tell the user: "No prep docs found. Run `/generate-prep-doc` first." Then stop.</action>
      </if>

      <if condition="one-prep-doc">
        <action>Use it automatically.</action>
      </if>

      <if condition="multiple-prep-docs">
        <ask-user>
        Which prep doc do you want to print?

        <options>
        - <dynamically list available prep docs with date and company>
        </options>
        </ask-user>
      </if>
    </if>

    <read path="<home>/.things/what-did-you-do/prep-docs/<resolved-filename>" output="prep-doc" />
  </step>

  <step id="parse-frontmatter" number="3">
    <description>Parse Frontmatter and Content</description>

    <action>Separate the YAML frontmatter from the markdown body. Extract:
    - `type` (interaction type)
    - `company`
    - `date`
    - `scheduled`
    - `contact`
    - `role`
    - `source`
    </action>
  </step>

  <step id="build-html" number="4">
    <description>Build Styled HTML Document</description>

    <action>Read the HTML template from @references/printable-template.html. This template contains the complete CSS styling (dark theme, print media query) and HTML structure. Replace `{{placeholders}}` with actual values from the frontmatter and convert the markdown body to HTML for the `{{content}}` placeholder.</action>

    <action>Convert the markdown body to HTML elements manually, element by element. Map:
    - `# heading` → `<h1>`
    - `## heading` → `<h2>`
    - `### heading` → `<h3>`
    - `**bold**` → `<strong>`
    - `*italic*` → `<em>`
    - `> blockquote` → `<blockquote><p>...</p></blockquote>`
    - `- list item` → `<ul><li>...</li></ul>`
    - `1. list item` → `<ol><li>...</li></ol>`
    - `| table |` → `<table>` with `<thead>` and `<tbody>`
    - `` `code` `` → `<code>`
    - `---` → `<hr>`
    - Paragraphs → `<p>`
    </action>

    <constraint>Do NOT use a markdown-to-HTML library or `npx marked`. Convert the markdown to HTML directly, element by element, to maintain full control over the output structure.</constraint>

    <constraint>The frontmatter MUST be rendered as the `.meta` grid at the top, NOT as raw text or an `<h2>`.</constraint>

    <constraint>The `body` has `padding: 1rem` and NO `max-width`. This is intentional for printability -- the document should fill the available width.</constraint>

    <constraint>Include the `@media print` block so the document prints cleanly on paper with light-theme colors.</constraint>
  </step>

  <step id="write-and-open" number="5">
    <description>Write HTML and Open in Browser</description>

    <action>Derive the output filename from the source filename, replacing `.md` with `.html`.</action>

    <write path="<home>/.things/what-did-you-do/printable-prep-docs/<filename>.html">
      <action>Write the complete HTML document.</action>
    </write>

    <command language="bash" tool="Bash">open <home>/.things/what-did-you-do/printable-prep-docs/<filename>.html</command>

    <template name="confirmation">

    > Printable prep doc created and opened:
    > `<home>/.things/what-did-you-do/printable-prep-docs/<filename>.html`

    </template>
  </step>

  <step id="git-workflow" number="6">
    <description>Handle Git Workflow</description>

    <git-workflow>
      <command language="bash" tool="Bash">git -C <home>/.things pull --rebase 2>/dev/null || true</command>

      <action>Based on the `git_workflow` setting (from config.json):</action>

      <if condition="workflow-auto">
        <action>Automatically `git add` the HTML file, `git commit -m "printable-prep: <company>"`, and `git push`.</action>
      </if>
      <if condition="workflow-ask">
        <ask-user>Use AskUserQuestion -- "Would you like to commit and push the printable prep doc?"</ask-user>
      </if>
      <if condition="workflow-manual">
        <action>Tell the user the file has been saved and they can commit when ready.</action>
      </if>
    </git-workflow>
  </step>

</steps>
