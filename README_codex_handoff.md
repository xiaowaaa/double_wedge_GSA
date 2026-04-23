# Codex Handoff README

Last updated: 2026-04-10

This file is now the top-level entry page for cross-account handoff.

## Read In This Order

1. `docs/coordination/ACTIVE_CONTEXT.md`
2. `docs/coordination/WORK_QUEUE.md`
3. `docs/coordination/TASK_LOG.md`
4. `docs/audit.md`
5. `docs/PROJECT_STRUCTURE.md`
6. `docs/background/` when older investigation context or literature notes are needed

## Quick Project Facts

- Project: MATLAB structured-grid double-wedge compressible bi-global stability solver
- Main method reference: `paper/A.pdf`
- Active production path: root-level `main_double_wedge_part1.m` through `main_double_wedge_part4.m`
- Modular workflow entry: `run/run_all.m`
- Production default: direct `v6` primitive-five path `q = [u'', v'', w'', T'', p'']^T`
- Local test baseflow detected: root-level `double_wedge_baseflow.dat` with Tecplot header `I=270`, `J=128`; full-resolution benchmark runner: `run/run_user_test_baseflow_fullres_v6.m`
- Final intended physical case remains `812 x 382`
- Latest retained structural benchmark: `outputs/mat/paperA_validation_270x128_v6/` with `beta = 0`, `n_eigs = 50`, `sigma = 0.05 + 0.02i`, no sponge, and shock-localized fourth-difference artificial viscosity
- The active `Part4_v6` path now uses the full scaled descriptor pencil, bubble-first phase anchoring, and the reference figure contract (`Fig13`, `Fig18`, `Fig19`, `Fig22`)
- Latest default benchmark leading mode: `sigma_r ~= -7.343e-05`, `sigma_i ~= +2.036e-02`, total residual `~2.47e-08`, bubble overlap `~3.94e-02`, near-wall energy `~8.65e-01`, free-stream energy `~1.09e-01`, shock energy `~6.93e-01`, checker ratio `~4.89e-02`, and `publication_allowed = 0`
- This remains a solver-structure benchmark rather than a final physics result because the local `270 x 128` baseflow file itself remains diagnostically weak
- Current stabilization route for the active audit pass: shock-localized fourth-difference semi-artificial viscosity only; sponge damping is now disabled by default
- Current user-confirmed boundary set for this double-wedge case: top=inlet, south-upstream=symmetry, south-downstream=wall, east=outlet; do not assume a farfield boundary on the top edge
- The repository has been pruned to the Paper-A production path; old runnable legacy4 and wall-relative plotting chains were deleted
- The old root-level `run.m` has been removed so MATLAB's built-in `run(...)` is no longer shadowed

## Validation Entry Point

```matlab
run_phase2_validation
```

```matlab
summary = run_user_test_baseflow_fullres_v6();
```

Key smoke artifacts currently present:
- `outputs/mat/test_eigs_smoke.mat`
- `outputs/mat/paperA_validation_270x128_v6/Part4_Results.mat`
- `outputs/mat/paperA_validation_270x128_v6/run_summary.txt`
- `outputs/mat/paperA_validation_270x128_v6/figs/Fig13_EigenvalueSpectrum.png`
- `outputs/mat/paperA_validation_270x128_v6/figs/Fig18_LeadingModeNormalizationAudit.png`
- `outputs/mat/paperA_validation_270x128_v6/figs/Fig19_LeadingModeUVBubbleStreamlines.png`
- `outputs/mat/paperA_validation_270x128_v6/figs/Fig22_Top4Modes.png`

## Collaboration Rule

After every completed task:
1. append `docs/coordination/TASK_LOG.md`
2. update `docs/coordination/ACTIVE_CONTEXT.md` if the project snapshot changed
3. update `docs/coordination/WORK_QUEUE.md` if priorities changed
4. append `docs/audit.md` for major solver or validation changes
