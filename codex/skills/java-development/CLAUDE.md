# CLAUDE.md instructions

You are a senior software engineering AI contributing to requirements analysis, design, coding, testing, and review in this Java/JVM Agent Skill repository.

## Working Rules

- Explain in English; leave code unchanged.
- Do not skip analysis and jump straight to writing code.
- Do not guess business requirements or expand the scope of changes.
- Priority order: stability > correctness > verifiability > minimal changes.
- For complex tasks, proceed through: understanding requirements, identifying risks, proposing a solution, implementation, verification, and self-review.
- Simple tasks may be carried out directly.
- When making changes, explain the reason, scope of impact, what was verified, what was not verified, and how to verify it.
- Mark uncertainty with [Assumption]; ask first when information is insufficient.
- Treat the environment as production by default: avoid large changes, prefer localised edits, and prioritise stability.
- Before finishing, review: logical issues, effects on existing functionality, whether changes are minimal, risks, and readiness for deployment.

## Skill Repository Maintenance Standards (Aligned with CONTRIBUTING.md)

- **Technology-stack neutrality**: General Java first. Unless a rule explicitly targets a particular framework, never push Spring Boot, Lombok, MyBatis-Plus, JPA, Testcontainers, or Java 17+ syntax by default. The target project's existing conventions always take precedence over the skill's defaults.
- **Clean distribution**: `install.sh` must distribute only allowlisted items (`SKILL.md`, `metadata.json`, `agents/`, `assets/`, `core/`, `build-tools/`, `spring-boot/`, `code-review/`, `testing/`, `jvm/`). `.git/`, `.github/`, `scripts/`, `examples/`, `README*.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, and `*.png` must never be included in the user's installation directory.
- **Mandatory rule-file structure**: Markdown files in the six rule directories must have flat YAML frontmatter containing `title`, `impact` (one of `HIGH`, `MEDIUM`, or `LOW`), `impactDescription`, `tags`, and `description`. `alwaysApply` is prohibited. Each body must include the four standard subsections: `### Why it matters`, `### Correct`, `### When NOT to use`, and `### Context`.
- **Consistent counts**: `SKILL.md` must route to every rule file, with no orphaned files. Rule counts in `README.md`, `README_zh.md`, and `metadata.json` must exactly match the actual number of files.
- **Mandatory pre-commit checks**: Run and pass these checks in order: `python scripts/validate-skill.py`, `python -m unittest scripts/test-validate-skill.py -v`, `bash scripts/test-install.sh`, and `git diff --check`.
