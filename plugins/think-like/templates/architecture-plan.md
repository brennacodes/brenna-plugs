# Architecture - Context Template

Defines the structure and execution phases for architecture evaluation action files. Builder agents use this template when constructing person-specific architecture actions.

## Phases

### Phase 1: Orientation (Internal)
- Map system components - services, databases, queues, caches, external dependencies
- Trace data flow through the system
- Identify deployment topology and operational characteristics
- Understand team structure and constraints if visible
- Note the system's age and evolution history

### Phase 2: Analysis (Internal)
- Evaluate against the profile's priorities:
  - Component boundaries - are they in the right places?
  - Dependency direction - does everything depend in the right direction?
  - Data flow - is data moving efficiently and safely?
  - Evolution potential - how hard is it to change this system?
  - Operational complexity - how many things need to be running?
  - Simplicity - is the complexity proportional to the problem?
- Consider forces: team size, scale requirements, regulatory constraints, deployment environment

### Phase 3: Findings (Output)

Structure findings as:

**Assessment**: 2-3 sentences - overall architectural health in the profile's voice.

**Structural Observations**: What the architecture IS - components, boundaries, dependencies. Neutral description before evaluation.

**Key Concerns**: Issues with the current architecture. Each includes:
- What: the structural problem
- Why it matters: concrete consequences (not theoretical)
- Suggested evolution: incremental steps, not rewrites

**What's Working**: Architectural decisions that are sound - acknowledge good structure.

**Evolution Guidance**: Recommended next steps, ordered by impact and feasibility.

### Phase 4: Counterpoint (Mandatory - Never Skip)
- Surface the profile's blind spots for this system's context
- Consider organizational constraints the profile might underweight
- Acknowledge tradeoffs where the current architecture's choices may be justified
- Suggest what a different architectural philosophy might prioritize

## Output Format

Use markdown. Include diagrams (text-based) when they clarify component relationships. Focus on forces and tradeoffs, not just patterns.

## Scope Rules

- **Module/directory**: Evaluate architecture within that boundary
- **Full system**: Map the complete picture - components, data flow, deployment
- **Specific concern** (e.g., "scaling," "data flow"): Focus analysis on that aspect across the system

## Variants

- `architecture`: Full system structure evaluation - boundaries, dependencies, evolution
- `api-design`: Focus on the public surface area - naming, consistency, error patterns, versioning, consumer experience. Treat the API as a product.
