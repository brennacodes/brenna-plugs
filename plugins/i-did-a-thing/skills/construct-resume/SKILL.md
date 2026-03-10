---
name: construct-resume
description: "Build a tailored resume from your logged evidence - accomplishments, lessons, expertise, decisions, and insights - matched against a specific job listing"
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, WebFetch
argument-hint: "[job listing URL or paste the listing]"
---

<purpose>
Analyze a job listing, match it against the user's logged evidence, and produce a tailored resume that speaks directly to what the role demands. Evidence comes in different types -- accomplishments, lessons, expertise, decisions, influence, and insights -- and the resume should draw on all of them.
</purpose>

<steps>

  <step id="load-configuration" number="1">
    <description>Load Configuration</description>

    <load-config>
      <action>Resolve the user's home directory.</action>
      <command language="bash" output="home" tool="Bash">echo $HOME</command>
      <constraint>Never pass `~` to the Read tool.</constraint>

      <read path="<home>/.things/config.json" output="config" />
      <if condition="config-missing">Tell the user: "Run `/things:setup-things` first." Then stop.<exit /></if>

      <read path="<home>/.things/shared/professional-profile.json" output="profile" />

      <read path="<home>/.things/i-did-a-thing/preferences.json" output="preferences" />
      <if condition="preferences-missing">Tell the user: "Run `/setup-idat` first." Then stop.<exit /></if>
    </load-config>
  </step>

  <step id="load-arsenal" number="2">
    <description>Load the Arsenal</description>

    <read path="<home>/.things/i-did-a-thing/index.json" output="index" />
    <read path="<home>/.things/i-did-a-thing/arsenal/" output="arsenal" />

    <constraint>The index.json contains all log data inline -- no need to open individual log files. Use the professional profile from `shared/professional-profile.json` (`current_role`, `target_roles`, `building_skills`, etc.).</constraint>

    <if condition="fewer-than-3-entries">
      <output>
      You only have N logged entries. I can work with this, but your resume will be stronger with more evidence. Consider running `/thing-i-did` a few more times to build your arsenal.
      </output>
    </if>
  </step>

  <step id="get-job-listing" number="3">
    <description>Get the Job Listing</description>

    <if condition="url-provided">Use WebFetch to retrieve it.</if>
    <if condition="text-pasted">Use that directly.</if>
    <if condition="no-listing-provided">
      <ask-user-question>
        <question>Paste the job listing or give me a URL and I'll pull it for you.</question>
        <option-with-text-input>Paste listing</option-with-text-input>
      </ask-user-question>
    </if>
  </step>

  <step id="analyze-job-listing" number="4">
    <description>Analyze the Job Listing</description>

    <action>Parse the listing to extract:</action>
    - Role title and level
    - Required skills (hard and soft)
    - Preferred/nice-to-have skills
    - Key responsibilities
    - Company values or culture signals
    - Industry/domain context

    <output>
    Here's what I see in this listing:

    Role: (title)
    Must-haves: (skills)
    Nice-to-haves: (skills)
    Key themes: (themes)

    Let me match this against your arsenal.
    </output>
  </step>

  <step id="match-against-arsenal" number="5">
    <description>Match Against Arsenal</description>

    <action>For each required and preferred skill in the listing, search and score against the user's logged evidence.</action>

    <substep name="search-arsenal">
      <description>Search Arsenal Files</description>
      <action>Search arsenal files for matching skills.</action>
    </substep>

    <substep name="search-logs">
      <description>Search Log Index</description>
      <action>Search log frontmatter for matching `skills_used`, `tags`, `category`, and `evidence_type`.</action>
    </substep>

    <substep name="score-relevance">
      <description>Score Relevance</description>
      <action>Score each log's relevance to the listing, weighting evidence types by what the listing emphasizes:</action>
      - Listing asks for "learning agility," "growth mindset," or "adaptability" -> weight `lesson` entries higher
      - Listing asks for "technical depth," "domain expertise," or "subject matter expert" -> weight `expertise` entries higher
      - Listing asks for "sound judgment," "strategic thinking," or "architectural decisions" -> weight `decision` entries higher
      - Listing asks for "influence," "leadership without authority," or "mentorship" -> weight `influence` entries higher
      - Listing asks for "vision," "innovation," or "strategic direction" -> weight `insight` entries higher
      - Standard behavioral requirements -> weight `accomplishment` entries as default
    </substep>

    <substep name="classify-matches">
      <description>Classify Matches</description>
      <action>Identify strong matches (direct evidence), partial matches (related evidence), and gaps (no evidence).</action>
    </substep>

    <output>
    Strong matches (you have direct evidence):
    - (skill): N entries, best example: "(log title)" (`evidence_type`)

    Partial matches (related experience):
    - (skill): closest evidence is (description)

    Gaps (no logged evidence):
    - (skill): consider logging relevant experience or highlighting transferable skills
    </output>
  </step>

  <step id="build-resume" number="6">
    <description>Build the Resume</description>

    <constraint>Use the template in `references/resume-format.md` to construct the resume.</constraint>

    <constraint>
    Resume construction rules:
    1. Tailor the summary to echo the listing's language and priorities
    2. Order experience sections by relevance to this role, not chronologically
    3. Pull resume bullets directly from log files' "Resume Bullets" sections, using the type-appropriate format:
       - Accomplishment entries -> STAR-format bullets
       - Lesson entries -> "Learned X from Y, now apply Z" format
       - Expertise entries -> "Deep expertise in X, demonstrated through Y" format
       - Decision entries -> "Evaluated X, Y, Z; chose Z based on A, B, C" format
       - Influence entries -> "Drove adoption of X, resulting in Y" format
       - Insight entries -> "Identified pattern X, proposed Y" format
    4. Adapt bullets to use keywords from the job listing where truthful
    5. Quantify everything possible using metrics from logs
    6. Include skills section ordered by listing priority, only including skills with evidence
    7. Match tone to the company's culture signals
    </constraint>

    <ask-user-question>
      <question>Resume format preference?</question>
      <option>`traditional` -- clean, professional, ATS-friendly</option>
      <option>`narrative` -- summary-driven with accomplishment highlights</option>
      <option>`technical` -- skills-forward with project details</option>
    </ask-user-question>
  </step>

  <step id="write-resume" number="7">
    <description>Write the Resume</description>

    <write path="<home>/.things/i-did-a-thing/resumes/<date>-<company-slug>.md">

    <schema name="resume-frontmatter">
    Include a metadata header (not part of the resume itself):
    ```yaml
    ---
    target_role: "<role title>"
    target_company: "<company>"
    listing_url: "<url if provided>"
    date_generated: <date>
    match_score: "<strong_matches>/<total_requirements>"
    evidence_types_used:
      accomplishment: <n>
      lesson: <n>
      expertise: <n>
      decision: <n>
      influence: <n>
      insight: <n>
    logs_referenced:
      - "<log filename>"
      - "<log filename>"
    gaps_identified:
      - "<skill>"
    ---
    ```
    </schema>

    </write>
  </step>

  <step id="review-with-user" number="8">
    <description>Review with User</description>

    <ask-user-question>
      <question>How does this look?</question>
      <option>Looks great -- save it</option>
      <option-with-text-input>I want to adjust some sections</option-with-text-input>
      <option>Regenerate with a different format</option>
      <option>Let me add more evidence first</option>
    </ask-user-question>

    <if condition="user-wants-adjustments">Use AskUserQuestion to identify which sections, then Edit the file.</if>
  </step>

  <step id="cover-letter-seed" number="9">
    <description>Generate a Cover Letter Seed (Optional)</description>

    <ask-user-question>
      <question>Want me to draft cover letter talking points too?</question>
      <option>Yes -- give me bullet points I can use</option>
      <option>Yes -- draft a full cover letter</option>
      <option>No -- just the resume</option>
    </ask-user-question>

    <if condition="user-wants-cover-letter">
      <action>Generate talking points or a full draft.</action>
      <constraint>
      - Reference specific entries from logs (not just accomplishments)
      - Connect the user's trajectory to the role
      - Use the company's own language from the listing
      - Emphasize the strongest matches
      </constraint>

      <write path="<home>/.things/i-did-a-thing/resumes/<date>-<company-slug>-cover.md" />
    </if>
  </step>

  <step id="gap-action-plan" number="10">
    <description>Gap Action Plan</description>

    <completion-message>
    To strengthen your candidacy for this role:

    1. Log these existing experiences (you probably have them, just haven't documented them):
       - (suggested entries to log, specifying evidence type)
       - e.g., "Log an expertise entry about your distributed systems knowledge"
       - e.g., "Log a decision entry about the database migration approach you chose"

    2. Build these skills (gaps you could fill):
       - (skill): (suggestion for how to build evidence)

    3. Diversify your evidence (types you're missing):
       - e.g., "You have strong accomplishments in distributed systems but no logged expertise entries -- consider logging your deep knowledge as an expertise entry"
       - e.g., "For 'sound judgment,' a decision entry would be more compelling than another accomplishment"

    4. Practice these interview questions (likely to come up for this role):
       - "(question from question bank that tests a key requirement)"

    Run `/practice-wdyd` to drill specific questions, or `/prep-for-wdyd` to build a full preparation plan for this company.
    </completion-message>
  </step>

</steps>
