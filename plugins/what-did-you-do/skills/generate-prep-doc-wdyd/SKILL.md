---
name: generate-prep-doc-wdyd
description: "Generate a detailed, personalized prep document for a specific upcoming conversation -- coffee chats, phone screens, or any interview-adjacent interaction"
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, WebFetch, WebSearch
argument-hint: "<company> [--contact <name>] [--role <target role>] [--type coffee-chat|phone-screen|technical|onsite|bar-raiser]"
---

<references>
  - references/prep-doc-structure.md
</references>

<purpose>
Generate a comprehensive, personalized prep document for a specific upcoming interaction with a company. Unlike `/prep-for-wdyd` which builds a general preparation plan, this skill creates a targeted document for a specific conversation -- incorporating the contact person, the backstory of how the interaction started, the user's arsenal evidence mapped to the company's values, concrete talking points, and questions to ask. Output is a markdown file saved to `~/.things/what-did-you-do/prep-docs/`.
</purpose>

<steps>

  <step id="load-config" number="1">
    <description>Load Configuration</description>

    <load-config>
      <action>Resolve the user's home directory.</action>
      <command language="bash" output="home" tool="Bash">echo $HOME</command>
      <constraint>Never pass `~` to the Read tool.</constraint>

      <read path="<home>/.things/config.json" output="config" />
      <if condition="config-missing">Tell the user: "Run `/things:setup-things` first." Then stop.</if>

      <read path="<home>/.things/shared/professional-profile.json" output="profile" />

      <read path="<home>/.things/what-did-you-do/preferences.json" output="preferences" />
      <if condition="preferences-missing">Tell the user: "Run `/setup-wdyd` first." Then stop.</if>

      <command language="bash" tool="Bash">mkdir -p <home>/.things/what-did-you-do/prep-docs</command>
    </load-config>
  </step>

  <step id="load-company-profile" number="2">
    <description>Load Company Profile</description>

    <if condition="company-provided">
      <read path="<home>/.things/shared/companies/<company>.yaml" output="company-profile" />
    </if>

    <if condition="no-company-specified">
      <action>List available company profiles from `<home>/.things/shared/companies/`.</action>
      <ask-user>
      Which company is this interaction with?

      <options>
      - <dynamically list available company profiles>
      - Custom -- I'll provide details
      </options>
      </ask-user>
    </if>

    <if condition="company-profile-missing">
      <action>Search the web for the company's engineering culture, values, and interview process. Build an ad-hoc profile. Offer to save it to `<home>/.things/shared/companies/<company>.yaml` for future use.</action>
    </if>
  </step>

  <step id="gather-context" number="3">
    <description>Gather Interaction Context</description>

    <if condition="contact-not-provided">
      <ask-user>
      Who are you meeting with? Include their name, title, and how they reached out if relevant.
      (Free text -- e.g., "Tan Doan, Staff Software Engineer, reached out on LinkedIn after seeing my Bivvy post")
      </ask-user>
    </if>

    <if condition="type-not-provided">
      <ask-user>
      What type of interaction is this?

      <options>
      - Coffee chat -- informal, exploratory conversation
      - Phone screen -- recruiter or hiring manager initial screen
      - Technical -- coding or system design focused
      - Onsite -- formal interview round
      - Bar raiser -- cross-functional deep dive
      </options>
      </ask-user>
    </if>

    <ask-user>
    Is there any backstory I should know? Paste any relevant context -- LinkedIn messages, email threads, job listings, referral details, etc.
    (Free text -- or "no additional context")
    </ask-user>

    <if condition="role-not-provided-and-not-in-context">
      <ask-user>
      What role is this for?
      (Free text -- e.g., "Mid-Senior Infra/Platform Engineer")
      </ask-user>
    </if>

    <action>Extract from the backstory context:
    - How the interaction originated (inbound vs outbound, referral, organic)
    - What the contact already knows about the user
    - Any concerns or gaps already surfaced
    - Any shared interests or connection points
    - The user's leverage and position in the process
    </action>
  </step>

  <step id="load-arsenal" number="4">
    <description>Load Arsenal and Session History</description>

    <action>Read all arsenal files from `<home>/.things/i-did-a-thing/arsenal/`.</action>
    <action>Read any existing session history from `<home>/.things/what-did-you-do/sessions/`.</action>
    <action>Check for an existing prep plan for this company: `<home>/.things/what-did-you-do/<company>-prep-plan.md`.</action>
  </step>

  <step id="analyze-position" number="5">
    <description>Analyze the User's Position</description>

    <action>Based on the backstory and context, determine:</action>

    <substep name="leverage-assessment">
      <description>Assess the user's leverage in this interaction.</description>
      <rubric>
      - **Strong**: Contact reached out to them, their work is already validated, they have a champion inside
      - **Neutral**: Mutual connection, referral, or applied and got a callback
      - **Building**: Cold application, no prior relationship
      </rubric>
    </substep>

    <substep name="known-concerns">
      <description>Identify any concerns or gaps already surfaced in prior communication.</description>
      <action>For each concern, prepare a concrete framing strategy using arsenal evidence and the company's values.</action>
    </substep>

    <substep name="shared-ground">
      <description>Identify shared interests, tools, problems, or experiences between the user and the contact.</description>
    </substep>
  </step>

  <step id="map-arsenal-to-company" number="6">
    <description>Map Arsenal to Company Values and Role</description>

    <for-each item="value" source="company-values">
      <substep name="find-evidence">
        <description>Search arsenal for entries that demonstrate this value's interview signals.</description>
      </substep>
      <substep name="classify">
        <description>Classify coverage as Strong, Partial, or Gap.</description>
      </substep>
    </for-each>

    <action>Select the top 3-4 arsenal stories most relevant to this specific interaction, considering:
    - The contact's role and what they'd care about
    - The interaction type (casual vs formal)
    - Any concerns already raised
    - Shared interests identified in the backstory
    </action>

    <constraint>When matching, consider which evidence types are most relevant:
    - Values about learning, adaptability, resilience -> `lesson` entries
    - Values about technical depth, expertise -> `expertise` entries
    - Values about judgment, ownership -> `decision` entries
    - Values about influence, leadership, mentorship -> `influence` entries
    - Values about vision, innovation, curiosity -> `insight` entries
    - Values about delivery, results, bias for action -> `accomplishment` entries
    </constraint>
  </step>

  <step id="build-prep-doc" number="7">
    <description>Build the Prep Document</description>

    <action>Construct the full prep document following the structure in `references/prep-doc-structure.md`.</action>

    <constraint>The tone and depth should match the interaction type:
    - **Coffee chat**: Conversational, peer-to-peer framing. Emphasize shared interests, natural conversation flow, and mutual evaluation. No STAR-format drilling.
    - **Phone screen**: Concise talking points, elevator pitch ready, motivational framing. Why this company, why this role.
    - **Technical**: Arsenal stories focused on system design tradeoffs, architecture decisions, technical depth. Include concrete technical details.
    - **Onsite**: Full behavioral prep with value mapping, multiple stories per value, anti-pattern awareness.
    - **Bar raiser**: Cross-functional depth, judgment under ambiguity, long-term thinking emphasis.
    </constraint>

    <constraint>Every section must be actionable. No filler. The user should be able to read this 30 minutes before the interaction and feel prepared.</constraint>

    <constraint>Questions to ask should be specific to this interaction -- not generic interview questions. They should reflect the backstory, the contact's role, and what the user genuinely needs to learn to evaluate fit.</constraint>
  </step>

  <step id="write-prep-doc" number="8">
    <description>Write Prep Document</description>

    <write path="<home>/.things/what-did-you-do/prep-docs/<date>-<company>-<type>-prep.md">
      <schema name="prep-doc-frontmatter">
      ```yaml
      ---
      type: <interaction type>
      company: "<company>"
      date: <today>
      scheduled: "<date and time if known>"
      contact: "<name> (<title>)"
      role: "<target role>"
      source: "<how the interaction originated>"
      status: prep
      ---
      ```
      </schema>

      <action>Write the full prep document body below the frontmatter.</action>
    </write>
  </step>

  <step id="git-workflow" number="9">
    <description>Handle Git Workflow</description>

    <git-workflow>
      <command language="bash" tool="Bash">git -C <home>/.things pull --rebase 2>/dev/null || true</command>

      <action>Based on the `git_workflow` setting (from config.json):</action>

      <if condition="workflow-auto">
        <action>Automatically `git add` the prep doc, `git commit -m "prep-doc: <company> <type>"`, and `git push`.</action>
      </if>
      <if condition="workflow-ask">
        <ask-user>Use AskUserQuestion -- "Would you like to commit and push this prep doc?"</ask-user>
      </if>
      <if condition="workflow-manual">
        <action>Tell the user the prep doc has been saved and they can commit when ready.</action>
      </if>
    </git-workflow>
  </step>

  <step id="confirm-and-next-steps" number="10">
    <description>Confirm and Offer Next Steps</description>

    <template name="confirmation">

    > Your prep doc is ready: `<home>/.things/what-did-you-do/prep-docs/<filename>`
    >
    > To create a printable version: `/print-prep <filename>`
    > To practice with a relevant persona: `/practice-wdyd --persona <suggested persona>`
    > To run a mock for this stage: `/mock-wdyd <company> --stage <stage>`

    </template>

    <ask-user>
    What would you like to do next?

    <options>
    - Create a printable version (`/print-prep`)
    - Practice with a relevant persona
    - I'm good -- I'll review the doc
    </options>
    </ask-user>
  </step>

</steps>
