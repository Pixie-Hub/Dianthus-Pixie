---
trigger: always_on
---

- Tasks live in `docs/design/PROMPT_*.md` and `docs/design/PERSON_TASKS.md`.
  Before implementing, read the relevant PROMPT file and cross-check scope.
- Respect task IDs (e.g., CORE-07, PLANT-01, DIFF-01). Leave `TODO: <TASK-ID>` stubs
  for work explicitly deferred to another task, never silently skip.
- After completing a task, update the memory record with created/modified files.
 