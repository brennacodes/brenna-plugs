# Source Validation

Rules for validating external question sources and ensuring quality.

## Trusted Source Validation

### Domain Matching
Check the URL's domain against `trusted_sources.domains` in config:
- Extract the domain from the URL (e.g., `leetcode.com` from `https://leetcode.com/problems/...`)
- Match against the domains list (exact match or subdomain match)
- `www.` prefix is stripped before matching

### URL Matching
Check the full URL against `trusted_sources.urls` in config:
- Exact URL match (query parameters ignored)
- Useful for specific pages on otherwise untrusted domains

### Rejection
If neither domain nor URL matches:
- Reject with a clear message
- Suggest adding the source via setup
- Do NOT fetch the content

## Question Quality Validation

### Required Fields
Every question must have all schema fields populated:

```yaml
- id: <unique identifier>
  text: <question text, must end with ?>
  category: <behavioral|technical|system-design|leadership|situational>
  subcategory: <free text>
  skills_tested: [<at least 2 skills>]
  level: [<at least 1 of: mid, senior, staff, principal>]
  stages: [<at least 1 of: phone-screen, technical, onsite, bar-raiser>]
  interviewer_types: [<at least 1 persona type>]
  follow_ups:
    - text: <follow-up question>
      depth: 2
  difficulty: <1-5>
  expected_format: <narrative|whiteboard|coding>
  time_budget_minutes: <integer>
  red_flags: [<at least 1>]
  green_flags: [<at least 1>]
  source: <url or "manual" or "built-in">
  added_date: <YYYY-MM-DD>
```

### Quality Checks
1. **Question text** must be a genuine interview question (not a statement or instruction)
2. **Skills tested** must map to known skill tags (warn on new tags, don't reject)
3. **Follow-ups** should probe deeper, not repeat the original question
4. **Red/green flags** should be observable in an answer, not subjective judgments
5. **Time budget** should be realistic for the question type

### Deduplication
Compare new questions against existing ones:
- **Exact match:** Same question text (case-insensitive) → skip
- **Near match:** >80% word overlap → flag as potential duplicate, let user decide
- **Theme match:** Same skills_tested + same subcategory → note but allow (different angles on same topic are valuable)

## ID Generation

### Built-in questions
Format: `<category-prefix>-<3-digit-seq>`
- `beh-001`, `tech-001`, `sd-001`, `lead-001`, `sit-001`

### External questions
Format: `ext-<source-hash>-<seq>`
- Source hash: first 6 chars of MD5 of the source URL
- Seq: sequential within that source

### Manual questions
Format: `custom-<3-digit-seq>`
- Sequential across all manual entries

## Content Extraction Patterns

When parsing external URLs, look for questions in these formats:
- Numbered lists with question marks
- Quoted text blocks with attribution
- H2/H3 headers followed by bullet point questions
- "Tell me about a time..." or "How would you..." patterns
- Q&A format sections

Skip non-question content:
- Advertisements
- Navigation elements
- Author bios
- Comments sections (unless they contain curated questions)
