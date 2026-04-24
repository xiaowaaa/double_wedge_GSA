# Coordination Workflow

Purpose: give every Codex account or human maintainer one stable place to recover current project context quickly.

## Canonical Files

- `ACTIVE_CONTEXT.md`: current solver state, latest evidence, risks, and recommended next task.
- `WORK_QUEUE.md`: prioritized future work and blocked items.
- `TASK_LOG.md`: concise completed-task milestone ledger.
- `../audit.md`: major technical history, solver assumptions, and validation-relevant change notes.
- `../PROJECT_STRUCTURE.md`: directory ownership and root-file policy.

## Update Rules

- Append one concise dated entry to `TASK_LOG.md` after each completed task.
- Update `ACTIVE_CONTEXT.md` when the active state, latest validation, or recommended next task changes.
- Update `WORK_QUEUE.md` when priorities or blockers change.
- Append `../audit.md` only for major solver, validation, or method changes.
- Store generated text logs under `outputs/logs/`, not in the repository root.

## Cleanup Rule

Root-level migration reports, duplicate task logs, temporary plans, and debug reports should not accumulate. Once useful content is absorbed into these canonical files, remove the duplicate.
