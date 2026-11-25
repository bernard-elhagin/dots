# Issue tracker

Use GitHub Issues for `bernard-elhagin/dots`. Pass `-R bernard-elhagin/dots`
to `gh issue` commands so the target is explicit.

- Publish specs and tickets with `gh issue create`. Use `--body-file` for multiline text.
- Read issues and comments with `gh issue view`. Find open work with `gh issue list`.
- Use `gh issue comment` for updates and `gh issue edit` for labels and assignments.
- Post the resolution before closing an issue.

**PRs as a request surface: no.**

## Wayfinding

Use a `wayfinder:map` issue for the effort and child issues for individual
tickets. Use GitHub sub-issues and issue dependencies where available.
Otherwise, record the parent and blockers in the child issue. Claim a ticket
by assigning it before work starts. Record the answer on the ticket, close
it, and add a link and short summary to the map.
