---
description: Dianthus Pixie agent workflows for task orientation, feature implementation, bug fixing, UI editing, Git committing, and task breakdown syncing.
---

# Dianthus Pixie — Agent Workflows

These workflows define how agents should approach common task types in this project.
Use the matching workflow for each category of work. They are not optional — treat every step as a hard rule.

---

## /pre-task — Pre-Task Orientation Workflow

> Use this at the **start of every session or task** before writing any code.

1. Run `git status --short` to identify existing uncommitted changes unrelated to the current task.
2. Read `docs/design/TASK_BREAKDOWN.md` and locate the matching Task ID by title or feature area.
3. Check the task's **Status**, **Dependencies**, **Priority**, and **Acceptance Criteria**.
4. If Status is `Not Started` and dependencies are unmet, flag this before coding.
5. Read the relevant source files (script **and** scene) before editing anything.
6. If the task touches an autoload, cross-reference the autoload table in `rules.md` before modifying it.
7. If the prompt is ambiguous (unclear target scene, player flow, asset choice, or scope), ask before implementing.

---

## /implement — Feature Implementation Workflow

> Use when implementing any new feature or task from `TASK_BREAKDOWN.md`.

1. Identify the smallest feature folder that owns the work (`player/`, `combat/`, `ui/`, etc.).
2. Work inside that folder — do not introduce new global systems unless no suitable local one exists.
3. Follow the existing script style: typed GDScript 2.0, `@export`, `@onready`, `class_name`, signal declarations.
4. Use existing autoloads (see autoload table in `rules.md`); never create a duplicate singleton.
5. Preserve existing signal names, input action names, and resource paths unless the request requires changing them.
6. After edits, validate:
   - Run a headless Godot startup check if possible.
   - Otherwise, do static verification with targeted `grep` searches.
7. Stage only the files changed for this task: `git add <specific files>`.
8. Commit with a clear player-facing or developer-facing message (see `/commit` workflow).
9. Update `TASK_BREAKDOWN.md` status only if **all** acceptance criteria are fully met.

---

## /bugfix — Bug Fix Workflow

> Use when diagnosing and resolving runtime errors, scene wiring issues, or logic bugs.

1. Identify the **runtime source of truth** — which autoload or scene owns the broken state.
2. For scene-related bugs: inspect both the `.gd` script and the `.tscn` node wiring.
3. For `%NodeName` failures: verify `unique_name_in_owner` is set in the scene editor for that node.
4. For Dialogic issues: confirm `Dialogic.current_timeline != null` before starting a new timeline; never run two timelines simultaneously.
5. For typed `Array` issues: explicitly rebuild typed arrays — do not rely on `map()` return type when assigning to `Array[String]` or similar.
6. Fix **only** the reported issue; do not refactor surrounding unrelated code unless explicitly asked.
7. Commit the fix with a message that names both the symptom and the root cause.

---

## /ui — UI / HUD Workflow

> Use when editing anything inside `ui/`, `accessibility/`, or any HUD/screen/component.

1. Check `process_mode` on the node — pause-exempt nodes must be explicitly set to `PROCESS_MODE_ALWAYS`.
2. Verify `PauseManager` owns pause state; do not introduce a competing pause flag.
3. Route all audio through `SfxManager` and `MusicManager` — never play audio ad-hoc from a UI node.
4. Confirm all interactive elements have unique, descriptive node IDs.
5. For HUD elements tied to signals (HP, energy, wave count): verify signal names match `QuestManager`, `DayNightCycle`, or the relevant manager's signal contract before wiring.
6. For overlapping screens: account for the existing pause ownership pattern — a screen should not pause or unpause without going through `PauseManager`.
7. After edits, confirm scene path, node names, and all signal connections in the `.tscn` inspector.

---

## /commit — Git Commit Workflow

> Use at the **end of every completed change** before reporting back to the user.

1. Run `git status --short` to confirm only intended files are staged.
2. Do **NOT** stage: `.godot/` cache files, `.uid` files, `.import` files, or unrelated user changes.
3. Use commit messages in this format:
   - `feat(area): short description of player-facing change`
   - `fix(area): short description of symptom and what fixed it`
   - `docs: update TASK_BREAKDOWN.md to reflect [Task ID] completion`
4. Stage only: `git add <specific changed files>` — never `git add .` blindly.
5. Commit: `git commit -m "<message>"`
6. Report the **commit hash** in the final response summary.
7. Never use `git reset --hard` or `git checkout --` without explicit user confirmation.

---

## /sync-tasks — Task Breakdown Sync Workflow

> Use after completing a full task or when the user asks for a documentation update.

1. Open `docs/design/TASK_BREAKDOWN.md` and locate the matching Task ID.
2. Only mark Status as `Done` when **all** acceptance criteria from that row are met.
3. If partially implemented, set Status to `In Progress` and note what remains in a comment or adjacent note.
4. If new sub-tasks or dependencies were discovered during the work, add new rows — do not silently absorb them.
5. Update the `Last Updated` date at the top of the file.
6. Never mark tasks `Done` as a planning or aspirational update unless the user explicitly requests it.
7. Commit the updated `TASK_BREAKDOWN.md` as its own commit or alongside the feature commit.

---

## Quick Reference

| Slash Command  | When to Use                                      |
|----------------|--------------------------------------------------|
| `/pre-task`    | Start of every session or before any coding      |
| `/implement`   | New feature from TASK_BREAKDOWN                  |
| `/bugfix`      | Runtime errors, scene wiring, logic bugs         |
| `/ui`          | Any ui/, hud/, pause, screen, or signal work     |
| `/commit`      | End of every task before reporting back          |
| `/sync-tasks`  | After completing a full task or updating docs    |
