# Contributing

Thanks for improving `java-development`. Keep the skill useful for all Java developers, not only one framework stack.

## Principles

- General Java first; framework-specific rules only when the project uses that framework.
- Existing project conventions beat skill defaults.
- One focused change per PR: one rule, one fix, or one documentation update.
- Rules must be actionable, concise, and verifiable.
- Prefer automation for mechanical checks; use prose for judgment calls.

## Rule file structure

Every rule under `core/`, `build-tools/`, `spring-boot/`, `code-review/`, `testing/`, or `jvm/` must start with flat YAML frontmatter:

```markdown
---
title: Short Rule Name
impact: HIGH | MEDIUM | LOW
impactDescription: Concrete harm if this rule is ignored
tags: comma, separated, tags
description: One-sentence summary
---

## Short Rule Name

### Why it matters
Concrete harm, not generic best-practice language.

### Correct
Actionable guidance or a concise example.

### When NOT to use
Boundary conditions and cases where the rule should not be applied.

### Context
Version notes, references, and cross-refs to related rules.
```

Section rules (enforced by `scripts/validate-skill.py`):

- Headings may continue after the standard prefix (e.g. `### Correct — layered config`, `### When NOT to use — migration`), but every rule file must contain all four prefixes: `### Why it matters`, `### Correct`, `### When NOT to use`, `### Context`.
- `Why it matters` must state concrete production harm or maintenance cost — no generic best-practice filler.
- Prefer `// Bad (Avoid)` / `// Good (Preferred)` minimal contrasts inside `Correct` sections.
- Do not add `alwaysApply`. Route rules from `SKILL.md` so the agent loads only what the current task needs.

## Metadata and counts

- When adding or removing a rule file, update the `ruleCounts` object in `metadata.json` (total plus the affected directory) and the README markers — the validator compares them against the real file counts.
- Every rule file must be routed from `SKILL.md` (no orphan files), and every path referenced in backticks must exist.
- Distribution is whitelist-based: `install.sh` copies only `SKILL.md`, `metadata.json`, `agents/`, `assets/`, and the six rule directories. Never broaden the copy to include repository-management files.

## Code style for examples

- Preserve the existing project stack and build tool.
- Do not introduce Spring Boot, Lombok, MyBatis-Plus, JPA, Testcontainers, or Java 17+ syntax unless the example explicitly targets that stack.
- In DI examples, prefer constructor injection.
- Use Lombok only in examples that state the project already uses Lombok.
- Use the existing logging facade; avoid production `System.out.println`.
- Preserve Maven/Gradle conventions such as BOMs, version catalogs, scopes, and toolchains.

## Validation

Run before opening a PR:

```bash
python scripts/validate-skill.py
python -m unittest scripts/test-validate-skill.py -v
bash scripts/test-install.sh

# Optional open-standard validation when skills-ref is installed:
skills-ref validate .
```

Also run `git diff --check` before publishing.

## What gets rejected

- Framework-first advice that applies Spring Boot/MyBatis-Plus/Lombok to unrelated Java projects.
- Rules without a concrete `Why it matters` / `impactDescription`.
- Broad rewrites, marketing language, or duplicated guidance already covered by another rule.
- Stale README/metadata counts after adding or removing rule files.

## Commit messages

Use Conventional Commits:

- `feat: add gradle build hygiene rule`
- `fix: clarify spring boot 4 migration baseline`
- `docs: update rule index counts`

---

# Contributing (English Translation)

Thanks for improving `java-development`. Keep the skill useful for all Java developers, not only one framework stack.

## Principles

- General Java first; framework-specific rules only when the project uses that framework.
- Existing project conventions beat skill defaults.
- One focused change per PR: one rule, one fix, or one documentation update.
- Rules must be actionable, concise, and verifiable.
- Prefer automation for mechanical checks; use prose for judgment calls.

## Rule file structure

Every rule under `core/`, `build-tools/`, `spring-boot/`, `code-review/`, `testing/`, or `jvm/` must start with flat YAML frontmatter:

```markdown
---
title: Short Rule Name
impact: HIGH | MEDIUM | LOW
impactDescription: Concrete harm if this rule is ignored
tags: comma, separated, tags
description: One-sentence summary
---

## Short Rule Name

### Why it matters
Concrete harm, not generic best-practice language.

### Correct
Actionable guidance or a concise example.

### When NOT to use
Boundary conditions and cases where the rule should not be applied.

### Context
Version notes, references, and cross-refs to related rules.
```

Section rules (enforced by `scripts/validate-skill.py`):

- Headings may continue after the standard prefix (e.g. `### Correct — layered config`, `### When NOT to use — migration`), but every rule file must contain all four prefixes: `### Why it matters`, `### Correct`, `### When NOT to use`, `### Context`.
- `Why it matters` must state concrete production harm or maintenance cost — no generic best-practice filler.
- Prefer `// Bad (Avoid)` / `// Good (Preferred)` minimal contrasts inside `Correct` sections.
- Do not add `alwaysApply`. Route rules from `SKILL.md` so the agent loads only what the current task needs.

## Metadata and counts

- When adding or removing a rule file, update the `ruleCounts` object in `metadata.json` (total plus the affected directory) and the README markers — the validator compares them against the real file counts.
- Every rule file must be routed from `SKILL.md` (no orphan files), and every path referenced in backticks must exist.
- Distribution is whitelist-based: `install.sh` copies only `SKILL.md`, `metadata.json`, `agents/`, `assets/`, and the six rule directories. Never broaden the copy to include repository-management files.

## Code style for examples

- Preserve the existing project stack and build tool.
- Do not introduce Spring Boot, Lombok, MyBatis-Plus, JPA, Testcontainers, or Java 17+ syntax unless the example explicitly targets that stack.
- In DI examples, prefer constructor injection.
- Use Lombok only in examples that state the project already uses Lombok.
- Use the existing logging facade; avoid production `System.out.println`.
- Preserve Maven/Gradle conventions such as BOMs, version catalogs, scopes, and toolchains.

## Validation

Run before opening a PR:

```bash
python scripts/validate-skill.py
python -m unittest scripts/test-validate-skill.py -v
bash scripts/test-install.sh

# Optional open-standard validation when skills-ref is installed:
skills-ref validate .
```

Also run `git diff --check` before publishing.

## What gets rejected

- Framework-first advice that applies Spring Boot/MyBatis-Plus/Lombok to unrelated Java projects.
- Rules without a concrete `Why it matters` / `impactDescription`.
- Broad rewrites, marketing language, or duplicated guidance already covered by another rule.
- Stale README/metadata counts after adding or removing rule files.

## Commit messages

Use Conventional Commits:

- `feat: add gradle build hygiene rule`
- `fix: clarify spring boot 4 migration baseline`
- `docs: update rule index counts`
