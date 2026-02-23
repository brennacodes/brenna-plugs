# think-like

Apply expert thinking profiles to code reviews, architecture evaluation, and security audits.

## Installation

```
/plugin install think-like@brenna-plugs
```

## What it does

think-like lets you review code through the lens of a specific expert's thinking. Build a profile for DHH, Sandi Metz, or anyone else - capturing their philosophy, communication style, and specific stances. Then apply that profile to your code for a review that reflects their perspective.

Every review ends with a mandatory **counterpoint** - a genuine critique of the expert's blind spots applied to your specific code. You get the strong opinion AND its limitations.

## Skills

| Skill | Description |
|-------|-------------|
| `/setup-tl` | Initialize think-like, register with things, install starter profiles |
| `/profile` | Apply a profile to code - the main entry point |
| `/create-profile` | Build a new expert profile from research and references |
| `/browse-profiles` | Preview and install bundled starter profiles |
| `/manage-profiles` | List, edit, delete, export, or compare profiles |

## Quick Start

```
/setup-tl
```

```
/profile dhh code-review src/
```

```
/profile sandi-metz code-smell
```

```
/create-profile kent-beck
```

## Starter Profiles

| Profile | Actions | Focus |
|---------|---------|-------|
| **DHH** | code-review, architecture | Convention over configuration, majestic monolith, simplicity |
| **Sandi Metz** | code-review, code-smell | Message-passing, small objects, cost of change |
| **Strict Security Lead** | security-audit, code-review | Threat modeling, OWASP, defense in depth |

## How Profiles Work

Each profile has two parts:

1. **Person profile** (`shared/people/{id}/`) - Who they are, their philosophy, communication style. Shared across plugins.
2. **Action files** (`think-like/profiles/{id}/`) - Self-contained files with voice, structure, and instructions baked in. Each action file captures how the expert approaches a specific activity - their lens, priorities, typical questions, red flags, and blind spots.

When you run `/profile dhh code-review`, think-like reads the action file directly and Claude follows it as instructions. There is no subagent or routing layer - the action file itself contains everything needed to execute the review in that expert's voice.

### Builder Agents

Profile creation uses specialized builder agents (`agents/builders/`) to produce action files:

- **code-review** - Generates code review action files
- **security-analysis** - Generates security audit action files
- **architecture-plan** - Generates architecture evaluation action files
- **debug** - Generates debugging action files
- **agent-builder** - Meta builder that creates new builder agents

When you run `/create-profile`, the profile builder researches the person, then invokes the appropriate builder agents to produce each action file.

## Requirements

- things plugin (manages `.things/` infrastructure)
