# Quiz Rubric

Reference for scoring quiz answers and generating dynamic questions.

## Scoring Dimensions

Same five dimensions as explore sessions, applied to individual question answers:

### Depth (1-5)

| Score | In a quiz context |
|-------|------------------|
| 1 | Can't answer — no knowledge of the concept |
| 2 | Recalls a fact or definition but can't elaborate |
| 3 | Explains the concept correctly at a working level |
| 4 | Explains internals, edge cases, or non-obvious implications |
| 5 | Explains the "why" behind the "what" — design rationale, historical context, alternatives considered |

### Accuracy (1-5)

| Score | In a quiz context |
|-------|------------------|
| 1 | Answer is wrong or based on a misconception |
| 2 | Contains significant inaccuracies alongside some correct points |
| 3 | Mostly correct, imprecise on some details |
| 4 | Accurate, with only minor imprecisions |
| 5 | Technically precise at every level |

### Connections (1-5)

| Score | In a quiz context |
|-------|------------------|
| 1 | Answers in isolation — no references to anything else |
| 2 | Mentions that related things exist |
| 3 | Names related concepts but doesn't explain the relationship |
| 4 | Draws meaningful connections and references personal experience |
| 5 | Builds a connected web — relates to theory, practice, and personal experience across contexts |

### Application (1-5)

| Score | In a quiz context |
|-------|------------------|
| 1 | Can't apply the concept — theoretical only |
| 2 | Can apply in the exact context they've seen |
| 3 | Can reason about application in a new context with prompting |
| 4 | Proactively applies to new scenarios |
| 5 | Identifies non-obvious applications and creative adaptations |

### Articulation (1-5)

| Score | In a quiz context |
|-------|------------------|
| 1 | Incoherent or unintelligible answer |
| 2 | Disorganized — jumps between points |
| 3 | Gets the point across but could be clearer |
| 4 | Well-structured, easy to follow |
| 5 | Would make an excellent teaching example — clear, progressive, uses analogies |

## Question Generation Patterns

### From accomplishment entries
- "What technical challenges did you face in [project]? How did you solve them?"
- "You achieved [metric]. What would you do differently if the target was 10x higher?"

### From lesson entries
- "You learned [lesson] from [experience]. What signals would you look for to prevent this in the future?"
- "How would you apply [lesson] in a completely different context?"

### From expertise entries
- "Explain [technology/concept from expertise entry] to someone with no background."
- "What are the limitations of [technology]? When would you NOT use it?"

### From decision entries
- "You chose [option] over [alternatives]. What new information would change your mind?"
- "Walk me through the decision framework you'd use for a similar choice today."

### From influence entries
- "How would you make the same argument to a more skeptical audience?"
- "What's the strongest counterargument to [position you advocated]?"

### From insight entries
- "You observed [pattern]. What would disprove your thesis?"
- "How would you test whether [insight] holds true in [different context]?"

## Spaced Repetition Weighting

Questions should be weighted for selection based on:

1. **Time since last quiz on topic**: longer gap → higher weight
2. **Previous score**: lower score → higher weight for re-testing
3. **Concept strength**: gap > partial > strong for re-testing priority
4. **Goal alignment**: skills in `building_skills` or `aspirational_skills` → bonus weight
5. **Evidence type diversity**: untested evidence types → bonus weight
