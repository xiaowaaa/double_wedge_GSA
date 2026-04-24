# Task Log

This file is the concise coordination ledger. Detailed solver and validation history lives in `docs/audit.md`; background investigations live in `docs/background/`.

## 2026-04-03 to 2026-04-10 - Bootstrap, validation scaffolding, and v6 production chain

- Added explicit config validation, boundary-mask utilities, MATLAB R2020a compatibility fixes, and retained validation scaffolding.
- Introduced modular `run/`, `src/core/`, and `tests/` structure while keeping the root `main_double_wedge_part1.m` to `main_double_wedge_part4.m` production chain.
- Rebuilt the solver toward the `v6` primitive-five path and pruned older runnable legacy chains.
- Confirmed the bundled `double_wedge_baseflow.dat` is a `270 x 128` structural benchmark, not the final physical `812 x 382` case.

## 2026-04-11 to 2026-04-15 - Reader, SAV, shock, beta, and low-memory repairs

- Updated the PHengLEI reader for headered/headerless 11- and 12-column exports, including the optional `gama` column.
- Added shock-localized semi-artificial viscosity to the effective operator and fixed non-wrapping shock-mask dilation.
- Removed silent plotted-lead fallback so debug-only modes cannot become physical figures.
- Added low-memory descriptor fallback logic for large intended-case runs.
- Added beta-term and pressure-closure audits so expensive `Part4` runs are not the first inspection point.

## 2026-04-16 to 2026-04-17 - Plot contract, metadata, and boundary consistency

- Hardened MATLAB figure export text handling while preserving Chinese labels where intended.
- Split sorted-leading and plotted-leading metadata and added compatibility helpers for older results.
- Aligned shock-core masks with the protected shock band used in operator assembly.
- Fixed the north/top side-corner boundary contract to match deterministic corner ownership.
- Created transfer guidance, then established that transfer bundles should be generated on demand instead of kept as permanent repo mirrors.

## 2026-04-20 to 2026-04-22 - Path precedence, scans, workflows, and Sidharth contracts

- Hardened `setup_double_wedge_paths.m` so the active workspace wins over stale MATLAB path copies.
- Added forced low-memory runner controls, sigma-shift scan support, beta scans, resolvent scans, and a staged research workflow.
- Made `run/run_research_workflow_case_v6.m` conservative for intended `812 x 382` first passes: downsampled, Part3-first, refined Part4/resolvent disabled by default.
- Added explicit Sidharth benchmark/profile contracts, literature-facing tables, plot-provenance metadata, and publication-plot safeguards.
- Removed stale in-repo transfer mirrors and dead local-run helpers after replacing path-precedence tests with synthetic temp fixtures.

## 2026-04-23 - Pressure gates, lead provenance, beta fixes, and latest validation

- Added component-level checker diagnostics and pressure-specific gates for Sidharth plot eligibility.
- Kept residual-only fallback diagnostic-only and rewarded bubble-peaked candidates correctly during plot-lead selection.
- Switched production support fractions to component-energy support and made phase anchoring follow the requested reference component.
- Separated sorted lead, plot lead, and publication lead in saved summaries and runner outputs.
- Fixed confirmed `beta ~= 0` viscous cross-coupling coefficients, improved pressure-closure audits, removed a small `inv(M)` use, and switched Sutherland derivatives to analytic forms.
- Re-ran targeted tests and full `run_phase2_validation` successfully after the latest fixes.

## 2026-04-23 - Repository migration cleanup

- Migrated a clean working copy to `D:\double_wegde\double_wedge_gsa` without deleting the source project.
- Preserved root solver entries, `run/`, `src/`, `tests/`, `docs/`, `paper/`, key input data, current structural results, and user evidence.
- Kept the latest structural `270 x 128` result under `outputs/mat/sidharth2018_structural_270x128_v6/`.
- Moved uncertain side material into `_to_review/` and avoided carrying bulk historical outputs into the clean workspace.

## 2026-04-23 - Coordination docs consolidated

- Folded duplicate root migration summaries and the short root task log into `README_codex_handoff.md`, `docs/coordination/ACTIVE_CONTEXT.md`, `docs/coordination/WORK_QUEUE.md`, `docs/coordination/TASK_LOG.md`, and `docs/PROJECT_STRUCTURE.md`.
- Simplified `AGENTS.md` to point future agents at the canonical coordination files and remove ambiguity about duplicate logs.
- Removed root-level one-off reports after their content was absorbed into the canonical docs.

## 2026-04-23 - Literature-style plot contract, Chinese labels, and saved-output refresh

- Retired the short-lived dedicated `Fig20` special disturbance output and returned `beta=0` plotting to one unified literature-style bubble-component layout that stays closer to the paper-style presentation.
- Updated `write_paperA_reference_figures.m` so inactive `w'` cases show the informative `u'/v'/T'/p'` subset, while active spanwise cases still display `w'/u'/v'/T'/p'` under one common bubble-window contract.
- Added Chinese figure titles where they read naturally, including `特征值谱`, `候选模态局部放大`, `文献风格主模态分量图`, and `模态分量概览`.
- Hardened `refresh_saved_paperA_outputs` so redraws preserve saved Part4 plot-lead order by default instead of silently re-ranking saved arrays.
- Refreshed `outputs/mat/sidharth2018_structural_270x128_v6/` figures and summary metadata so the retained structural case now emits `Fig13_特征值谱.png`, `Sidharth_Fig14_主模态分离泡分量图.png`, and `Sidharth_Fig15_候选模态分量图_第01页.png`.
- Added regression coverage for the literature-style plotting contract and saved-order refresh behavior; full `run_phase2_validation` passed.

## 2026-04-23 - Manual beta=4 photo evidence extraction

- Extracted key run-summary, eigenvalue, and modal-figure information from phone photos under `outputs/mat/manual_global_stability_case_beta4_point/`.
- Saved OCR output, image inventory, and a manually checked evidence/analysis report under `outputs/mat/manual_global_stability_case_beta4_point/extracted_from_photos/`.
- Marked the evidence as secondary: the photos show a low-residual `beta=4` bubble-centred plot/publication candidate, but the same summary reports `structural_only=1` and `physics_reproduction_ready=0`, so original MAT provenance remains required before accepting a physical conclusion.

## 2026-04-23 - Manual beta=4 full-field follow-up

- Added the later `beta=4` full-field output photos (`Sidharth_fig15.jpg`, `idharth_Fig14S.jpg`) to the retained OCR bundle.
- Wrote a follow-up analysis under `outputs/mat/manual_global_stability_case_beta4_point/extracted_from_photos/beta4_root_cause_analysis_after_fullfield.md`.
- The combined photo evidence now points to a clearer failure chain: the retained `beta=4` lead candidate is a low-residual but strongly near-wall / shear-layer-extended `w`-dominant branch from a structural, downsampled, non-final physical case, not yet the target bubble-core physical structure.

## 2026-04-23 - UTF-8 summary outputs and conservative localization cleanup

- Added shared UTF-8 text-output handling so runner summaries now write readable Chinese labels without terminal mojibake.
- Localized user-facing summary labels and figure names conservatively across the main runners: sponge, bubble, mode, spectrum, derivative, and boundary-audit terminology now read naturally in Chinese, while formula symbols such as `u`, `v`, `T`, `p`, and `sigma` remain unchanged.
- Added filename sanitization helpers for localized figure names and removed legacy redraw artifacts such as `Fig02_BaseflowUxUxx.png`.
- Refreshed the retained structural case summary and figures so `run_summary.txt` is UTF-8 readable and `figs/Fig02_基本流导数_u_x_u_xx.png` now appears alongside the localized Part4 outputs.

## 2026-04-24 - Flow-condition overrides, wall thermal BCs, and non-Part4 validation

- Added shared flow helpers so the active `v6` path can accept explicit `Mach`, `Reynolds`, `T_inf`, `gamma`, `Pr`, `wall_model`, and `T_wall` inputs while keeping derived nondimensional quantities synchronized.
- Updated `Part1_v6`, `apply_structured_bc_rows`, preprocessing, runner summaries, and reuse/provenance checks so adiabatic versus isothermal wall treatment is explicit and recorded in saved audits.
- Added or extended regression coverage for flow overrides, wall-model config validation, wall thermal BC rows, Part3-only runner reuse, beta scans, sigma-shift scans, resolvent scans, and staged workflows under the new thermal-input contract.
- Re-ran a targeted non-`Part4` validation subset locally on 2026-04-24; all selected tests passed.
- Kept `Part4_v6` in static-review-only mode for this pass and confirmed via MATLAB `checkcode` that no new syntax or parse errors were introduced there.
