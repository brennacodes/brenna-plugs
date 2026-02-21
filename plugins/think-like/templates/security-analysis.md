# Security Analysis - Context Template

Defines the structure and execution phases for security audit action files. Builder agents use this template when constructing person-specific security analysis actions.

## Phases

### Phase 1: Orientation (Internal)
- Map the attack surface - entry points, trust boundaries, authentication mechanisms
- Identify the technology stack and its known vulnerability classes
- Understand the data flow - what's sensitive, where it enters, where it's stored, where it exits
- Note the deployment context if visible (cloud, on-prem, containers)

### Phase 2: Analysis (Internal)
- Systematic checks against the profile's priorities:
  - Input validation and injection points
  - Authentication and session management
  - Authorization and access control
  - Data protection (at rest, in transit, in logs)
  - Error handling and information leakage
  - Configuration and deployment security
  - Dependency vulnerabilities
  - Business logic abuse potential
- Trace attacker paths from each entry point
- Assess exploitability and impact for each finding

### Phase 3: Findings (Output)

Structure findings by severity:

**Executive Summary**: 2-3 sentences - overall security posture, highest-risk areas.

**Critical Findings**: Exploitable vulnerabilities with real impact. Each includes:
- Vulnerability description
- Location (file, line, endpoint)
- Attack scenario (how an attacker would exploit this)
- Impact (what they gain)
- Remediation (specific fix, not generic advice)

**Moderate Findings**: Issues that require specific conditions or combinations to exploit.

**Informational**: Hardening recommendations, defense-in-depth suggestions, best practice deviations.

**Positive Findings**: Security measures done well - acknowledge good patterns.

### Phase 4: Counterpoint (Mandatory - Never Skip)
- Surface the profile's blind spots for this specific codebase
- Note where security hardening conflicts with usability or velocity
- Acknowledge threat model assumptions that may not hold
- Suggest what a different security perspective might prioritize

## Output Format

Use markdown with clear severity labels. Each finding should be independently actionable. Avoid inflated severity - justify every rating. Include OWASP category references where applicable.

## Scope Rules

- **Single file**: Focus on that file's security boundaries
- **Directory/module**: Map trust boundaries within and across the module
- **Full application**: Threat model first, then targeted analysis of high-risk areas
- This is **static analysis only** - no active exploitation, no running code
