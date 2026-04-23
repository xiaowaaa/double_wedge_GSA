# Coordination Workflow

Purpose: give multiple Codex accounts one stable place to recover project context quickly and leave clean handoff notes.

Read these files before starting work:
1. `docs/coordination/ACTIVE_CONTEXT.md`
2. `docs/coordination/WORK_QUEUE.md`
3. the most recent entry in `docs/coordination/TASK_LOG.md`
4. `docs/audit.md` for solver-change history
5. `docs/PROJECT_STRUCTURE.md` if file ownership or locations are unclear
6. `docs/background/` only when older investigation context or literature notes are specifically relevant

Update these files after every completed task:
1. append one dated entry to `docs/coordination/TASK_LOG.md`
2. update `docs/coordination/ACTIVE_CONTEXT.md` if the current status, risks, or recommended next task changed
3. update `docs/coordination/WORK_QUEUE.md` if priorities or blockers changed
4. append `docs/audit.md` when the task makes a major solver, validation, or workflow change
5. save any generated diary or text logs under `outputs/logs/`

Keep the coordination notes concise:
- `ACTIVE_CONTEXT.md` is the current snapshot
- `WORK_QUEUE.md` is the prioritized next-work list
- `TASK_LOG.md` is append-only and records what was finished
- one-off plans or temporary debug diaries should not live beside these files once their contents have been absorbed into `WORK_QUEUE.md`, `TASK_LOG.md`, or `docs/audit.md`

Do not use these files to replace technical validation:
- solver assumptions and major code-change history still belong in `docs/audit.md`
- generated run artifacts still belong under `outputs/`
