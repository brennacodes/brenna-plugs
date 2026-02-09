# Preparation Strategy

Framework for building company-specific interview preparation plans.

## Value Mapping Process

### Step 1: Identify Company Values
Extract from the company profile (or build from job listing if custom):
- Explicit values with behavioral indicators
- Interview signals that demonstrate each value
- Anti-patterns that signal misalignment

### Step 2: Map Values to Arsenal
For each value, search the user's arsenal for evidence:
- Direct evidence: accomplishment explicitly demonstrates the value
- Indirect evidence: accomplishment demonstrates a related skill
- Gap: no relevant accomplishment found

### Step 3: Rank by Interview Weight
Not all values are weighted equally in interviews:
- **Primary values** (asked about in every round): highest priority for preparation
- **Stage-specific values** (tested in particular rounds): prepare for the right stage
- **Culture values** (implicit, not directly asked): weave into all answers naturally

## Story Preparation Framework

Each company value should have 2-3 prepared stories:

### Story Selection Criteria
1. **Recency:** Prefer accomplishments from the last 2 years
2. **Relevance:** Direct match to the value being demonstrated
3. **Impact level:** Higher impact = more compelling evidence
4. **Uniqueness:** Avoid using the same story for multiple values
5. **Depth:** Story should support 2-3 follow-up questions

### Story Adaptation
The same accomplishment can demonstrate different values depending on framing:
- **For "Ownership":** Emphasize going beyond what was asked
- **For "Customer Obsession":** Emphasize user impact and customer-centric decisions
- **For "Technical Excellence":** Emphasize architecture decisions and tradeoffs

But never stretch a story to fit a value it doesn't naturally support.

## Timeline-Based Preparation

### 1+ Month Out
- **Focus:** Arsenal building and broad practice
- Log 2-3 accomplishments per week targeting gap values
- Practice all question categories (2-3 questions/day)
- One mock per week, rotating stages
- Read about the company's engineering blog, tech stack, and recent challenges

### 2-4 Weeks Out
- **Focus:** Company-specific drilling
- Daily practice with company-value-weighted questions
- Two mocks per week, focusing on weakest stages
- Refine top stories for each value
- Practice transitions between stories

### 1 Week Out
- **Focus:** Polish and confidence
- One full mock per day for different stages
- Review all session feedback for persistent anti-patterns
- Practice the 2-minute version of every story
- Prepare questions to ask interviewers (company-specific)

### This Week
- **Focus:** Warm-up and mental preparation
- Light practice (1-2 questions/day, familiar categories)
- Review your strongest stories
- Get sleep and rest
- Don't try to learn new things — use what you have

## Custom Company Profile Generation

When the user provides a job listing instead of using a built-in profile, extract:

1. **Company name and role**
2. **Values/culture signals** from the listing language
3. **Required skills** → map to question categories
4. **Preferred skills** → identify for bonus preparation
5. **Level signals** from scope, autonomy, and leadership language
6. **Interview process** (if described in listing, otherwise estimate from company size/type)

Structure the extracted data to match the company profile YAML schema so it can be reused.
