# AGENTS

## Repository Working Agreement

- Prioritize correctness, consistency, maintainability, and long-term extensibility over minimal edits.
- Medium-to-large refactors are explicitly allowed when they remove fragile structure, duplicated logic, dead code, or unclear interfaces.
- When there is a conflict between a minimal patch and a reasonable structural refactor, prefer the structural refactor.
- Any refactor must carry the full call chain with it:
  configuration, helper functions, scripts, tests, documentation, and outputs must be updated together.
- Do not trust screenshots alone for stability conclusions.
  All debugging and fixes must trace back to original arrays, matrices, eigenpairs, and plotting/provenance metadata.
- For the current double-wedge stability workflow, the production path is the root legacy4 chain:
  `main_double_wedge_part1.m -> main_double_wedge_part2.m -> main_double_wedge_part3.m -> main_double_wedge_part4.m`.
- High-priority failure modes to audit first:
  1. semi-artificial viscosity not truly entering the effective linear operator,
  2. semi-artificial viscosity entering the wrong model or wrong scaling,
  3. dominant-mode ranking selecting a compact pseudo-mode,
  4. field extraction / normalization / plotting mismatch,
  5. boundary labeling or BC row overwrite mismatch.

## Refactor Expectations

- Prefer shared helpers over duplicated logic between root scripts and `src/core`.
- Keep result provenance explicit:
  figures, MAT outputs, config snapshots, and audit tables should live together and be traceable to one run directory.
- Keep long-lived document types grouped by purpose:
  background investigations under `docs/background/`, active handoff and task tracking under `docs/coordination/`, and major technical history in `docs/audit.md`.
- Do not accumulate temporary one-off `PLAN.md`, `DEBUG_REPORT.md`, or `FIX_LOG.md` files once their contents have been absorbed into the coordination or audit docs; delete or fold them back into the canonical logs instead.
- When the user asks to move the solver to another computer, prepare one dedicated transfer folder that preserves the repo-relative layout required by `setup_double_wedge_paths.m`.
  Include the root solver entry files, `run/`, `src/`, `tests/`, `docs/`, `paper/`, key README files, and a transfer README; exclude bulky `outputs/` unless the user explicitly asks for historical results too.
- New diagnostics should default behind config/debug flags when they change output volume, but important correctness guards may fail hard.
- Legacy4 with nonzero `beta` must not silently continue unless true spanwise terms are implemented.
