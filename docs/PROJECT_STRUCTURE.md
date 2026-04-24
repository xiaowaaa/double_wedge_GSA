# Project Structure

This file explains the current folder classification and the few top-level exceptions that remain intentional.

## Root Production Files

- `main_double_wedge_part1.m`
- `main_double_wedge_part2.m`
- `main_double_wedge_part3.m`
- `main_double_wedge_part4.m`
- `Main_DoubleWedge_Part1_v6.m` to `Main_DoubleWedge_Part4_v6.m`
- `Main_DoubleWedge_Part3_v6_pre_pressure_fix_20260414.m`
- `setup_double_wedge_paths.m`
- `double_wedge_baseflow.dat`
- `Diagnose_MatrixHealth.m`

These remain at the repository root because they are direct production, compatibility, path, input, or diagnostic entry points. There is intentionally no root-level `run.m`; use `run/run_all.m`, `run/run_phase2_validation.m`, or the explicit Part scripts.

## Root Metadata

- `AGENTS.md`: repo-wide working agreement for agents.
- `README.md`: general project overview.
- `README_codex_handoff.md`: compact onboarding page for a fresh Codex session.

Do not keep duplicate root task logs, migration reports, fix logs, or temporary plans after their useful content has been folded into `docs/coordination/` and `docs/audit.md`.

## Code And Workflows

- `run/`: user-facing scripts, scans, workflow runners, and validation drivers.
- `src/core/`: reusable reader, preprocessing, operator, BC, SAV, descriptor, ranking, plotting, and audit helpers.
- `tests/`: MATLAB unit, regression, and smoke checks.

Prefer shared helpers under `src/core/` over duplicated logic in scripts. Keep root Part scripts as stable production wrappers.

## Documentation

- `docs/coordination/`: active context, work queue, concise task log, and coordination workflow.
- `docs/audit.md`: major technical history, solver assumptions, and validation-relevant change notes.
- `docs/background/`: long-lived investigations, literature notes, and validation background.
- `docs/prompts/`: saved prompts or request snapshots.
- `docs/PROJECT_STRUCTURE.md`: this file.

## Literature

- `paper/`: reference PDFs and related notes.
- `paper/notes/`: literature comparison notes and longer reading summaries.

Do not keep transient extracted page-image folders here unless they are actively referenced by code or documentation.

## Outputs And Evidence

- `outputs/`: generated figures, MAT artifacts, run summaries, and logs.
- `outputs/logs/`: generated diary/text logs.
- `results/`: lightweight copies or summaries of selected results for quick review.
- `archive/`: retained historical results and user-provided evidence.
- `_to_review/`: uncertain side material that is not required by the current production path.

Do not store generated outputs under `docs/`, `run/`, `src/`, or `tests/`. Do not keep long-lived full-repository mirror copies under `outputs/`; create transfer bundles on demand outside the main workspace.
