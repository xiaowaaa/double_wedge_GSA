# AGENTS

## Working Agreement

- Prioritize correctness, consistency, maintainability, and long-term extensibility over minimal edits.
- Medium-to-large refactors are allowed when they remove fragile structure, duplicated logic, dead code, or unclear interfaces.
- Carry the full call chain with any refactor: configuration, helpers, scripts, tests, documentation, and outputs must stay consistent.
- Do not trust screenshots alone for stability conclusions. Trace conclusions back to arrays, matrices, eigenpairs, fields, and provenance metadata.
- The current production path is the root `v6` chain:
  `main_double_wedge_part1.m -> main_double_wedge_part2.m -> main_double_wedge_part3.m -> main_double_wedge_part4.m`.

## Coordination Docs

- Start new work from `README_codex_handoff.md`, then read:
  `docs/coordination/ACTIVE_CONTEXT.md`, `docs/coordination/WORK_QUEUE.md`, `docs/coordination/TASK_LOG.md`, and `docs/audit.md`.
- Keep current status in `docs/coordination/ACTIVE_CONTEXT.md`.
- Keep next work in `docs/coordination/WORK_QUEUE.md`.
- Keep completed-task milestones in `docs/coordination/TASK_LOG.md`.
- Keep major solver, validation, and method history in `docs/audit.md`.
- Do not keep one-off root `PLAN.md`, `DEBUG_REPORT.md`, `FIX_LOG.md`, migration summaries, or duplicate task logs after their content has been folded into the canonical docs.

## Solver Guardrails

- Prefer shared helpers over duplicated logic between root scripts and `src/core`.
- Keep result provenance explicit: figures, MAT outputs, config snapshots, and audit tables should live together under one run directory.
- New diagnostics should default behind config/debug flags when they change output volume, but important correctness guards may fail hard.
- Legacy4 with nonzero `beta` must not silently continue unless true spanwise terms are implemented.

## High-Priority Failure Modes

- Semi-artificial viscosity not truly entering the effective linear operator.
- Semi-artificial viscosity entering the wrong model or wrong scaling.
- Dominant-mode ranking selecting a compact pseudo-mode.
- Field extraction, normalization, or plotting mismatching the selected eigenpair.
- Boundary labeling or BC row overwrite mismatch.
