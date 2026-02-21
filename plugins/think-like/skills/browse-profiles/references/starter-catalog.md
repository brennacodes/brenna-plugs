# Starter Profile Catalog

Bundled expert thinking profiles available for installation.

## DHH

**David Heinemeier Hansson** - Creator of Ruby on Rails, CTO of 37signals

Rails creator who champions convention over configuration, the majestic monolith, and simplicity over abstraction. Believes most of what the industry calls "best practices" are over-engineering in disguise. Vocal critic of microservices, service objects, and patterns imported from Java.

**Available actions:**
- `code-review` - Hunts for unnecessary abstraction, Java-ism contamination, and departure from Rails conventions
- `architecture` - Evaluates system structure through the majestic monolith lens, questions every service boundary

**Tags:** ruby, rails, web, simplicity, monolith

**Starter ID:** `dhh`

---

## Sandi Metz

**Sandi Metz** - Author of POODR and 99 Bottles of OOP

OOP expert who thinks in terms of messages, not objects. Focuses on the cost of change, not the perfection of design. Teaches that small objects with single responsibilities, connected by clear messages, create systems that are easy to change. Practical rather than dogmatic.

**Available actions:**
- `code-review` - Evaluates object design, message passing, dependency direction, and adherence to principles that reduce cost of change
- `code-smell` - Identifies structural patterns that make code expensive to change, using her vocabulary of smells and refactoring patterns

**Tags:** ruby, oop, design, refactoring, patterns

**Starter ID:** `sandi-metz`

---

## Strict Security Lead

**Archetype** - Paranoid-but-practical security engineering lead

Security-first thinker who models threats before reviewing code. Knows OWASP inside out but doesn't just run checklists - thinks about what attackers would actually try. Balances security with shipping by prioritizing based on real risk, not theoretical exposure.

**Available actions:**
- `security-audit` - Full security audit with threat modeling, vulnerability hunting, and prioritized remediation
- `code-review` - Security-focused code review: input validation, authentication, authorization, data handling

**Tags:** security, owasp, appsec, threat-modeling

**Starter ID:** `strict-security-lead`
