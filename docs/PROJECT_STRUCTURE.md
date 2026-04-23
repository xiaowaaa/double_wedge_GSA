# Project Structure

This file explains the current folder classification and the few top-level exceptions that remain intentional.

## Root-Level Production Solver Files

- `main_double_wedge_part1.m`
- `main_double_wedge_part2.m`
- `main_double_wedge_part3.m`
- `main_double_wedge_part4.m`

These remain at the repository root because the active production solver path still runs through them directly.

There is intentionally no root-level `run.m` anymore. Use `run/run_all.m`, `run/run_phase2_validation.m`, or the explicit `main_double_wedge_part*.m` scripts so MATLAB's built-in `run(...)` stays available.

## Root-Level Project Metadata Kept Intentionally

- `AGENTS.md`
- `README.md`
- `README_codex_handoff.md`

`AGENTS.md` must stay at the repository root so Codex and other agents can pick up the repo-wide instructions automatically.

## Modular And Reusable Code

- `src/core/`

Put new reusable implementation files here unless the task specifically extends the active root-level production path.

## Run And Workflow Scripts

- `run/`

Put scripted entry points, validation drivers, and post-processing scripts here.

## Tests

- `tests/`

Put validation and smoke checks here. Follow the required validation order from `AGENTS.md`.

## Documentation And Handoff

- `docs/audit.md` for major technical audit notes and solver-change history
- `docs/coordination/` for cross-account handoff, current status, task log, and work queue
- `docs/background/` for retained investigation reports, literature surveys, and other long-lived background notes
- `docs/prompts/` for saved task prompts and request snapshots
- `README_codex_handoff.md` as the top-level quick entry page for a new Codex session

Do not keep iterative one-off `PLAN.md`, `DEBUG_REPORT.md`, or `FIX_LOG.md` files once their useful content has already been absorbed into `docs/coordination/` and `docs/audit.md`.

## Literature

- `paper/`

Local references live here. The main method reference is `paper/A.pdf`.

- `paper/*.pdf` stores the reference PDFs themselves.
- `paper/notes/` stores literature comparison notes and longer reading summaries.

Do not keep transient extracted page-image folders here unless they are actively referenced by code or documentation.

## Generated Outputs

- `outputs/figs/` for figures
- `outputs/mat/` for MAT artifacts
- `outputs/logs/` for diary and text logs

Do not store generated outputs under `docs/`, `run/`, `src/`, or `tests/`.
Do not keep long-lived full-repository mirror copies under `outputs/` either; create transfer bundles on demand outside the main workspace or archive them externally after handoff.
