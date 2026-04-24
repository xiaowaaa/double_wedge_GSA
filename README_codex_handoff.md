# Codex Handoff README

Last updated: 2026-04-23

This is the compact entry point for a fresh Codex or agent session.

## Read First

1. `AGENTS.md`
2. `docs/coordination/ACTIVE_CONTEXT.md`
3. `docs/coordination/WORK_QUEUE.md`
4. `docs/coordination/TASK_LOG.md`
5. `docs/audit.md`
6. `docs/PROJECT_STRUCTURE.md`

## Current Project State

- Project: MATLAB structured-grid double-wedge PHengLEI bi-global/global stability solver.
- Production chain: `main_double_wedge_part1.m -> main_double_wedge_part2.m -> main_double_wedge_part3.m -> main_double_wedge_part4.m`.
- Active implementation: `Main_DoubleWedge_Part*_v6.m` with primitive-five perturbations `q = [u', v', w', T', p']^T`.
- Default benchmark/profile: `sidharth2018_code_correction_v1`.
- Local bundled baseflow: `double_wedge_baseflow.dat`, `270 x 128`, structural benchmark only.
- Intended physical case: `812 x 382`; the final trusted baseflow and matching boundary labels are not bundled here.
- Current boundary contract: top=`inlet`, south-upstream=`symmetry`, south-downstream=`wall`, east=`outlet`.

## Useful Entry Points

```matlab
setup_double_wedge_paths('IncludeTests', true);
run_phase2_validation;
```

```matlab
summary = run_user_test_baseflow_fullres_v6();
```

Recommended manual scripts:

- `run/run_research_workflow_case_v6.m`
- `run/run_global_stability_case_v6.m`
- `run/run_beta_scan_v6.m`
- `run/run_resolvent_gain_scan_v6.m`
- `run/run_sidharth2018_workflow_v6.m`

## Current Evidence Level

The retained local structural result under `outputs/mat/sidharth2018_structural_270x128_v6/` reaches `Part4` and currently reports a bubble-centred physical plot candidate. Its figures have been refreshed to one unified literature-style component layout (`Sidharth_Fig14_主模态分离泡分量图.png`, `Sidharth_Fig15_候选模态分量图_第01页.png`), and both figure titles and saved image names now use Chinese where that improves readability (for example `Fig13_特征值谱.png`, `特征值谱`, `候选模态局部放大`, and `文献风格主模态分量图`). The case still remains `structural_only=1` and `physics_reproduction_ready=0`; do not use it as final evidence for the intended `812 x 382` physical case.

For user-side `812 x 382` results, verify `run_summary.txt/.mat`, `Part3_Results.mat`, and `Part4_Results.mat` before accepting any screenshot-based stability conclusion.

## Update Rules

- After completed work, append a concise entry to `docs/coordination/TASK_LOG.md`.
- Update `docs/coordination/ACTIVE_CONTEXT.md` if the project state changes.
- Update `docs/coordination/WORK_QUEUE.md` if priorities or blockers change.
- Append `docs/audit.md` only for major solver, validation, or method changes.
