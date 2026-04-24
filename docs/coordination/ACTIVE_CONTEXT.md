# Active Context

Last updated: 2026-04-24

## Current Objective

Keep the double-wedge setup runnable while moving the solver toward the Paper-A/Sidharth-style primitive-five stability workflow. Correct operator assembly, boundary treatment, mode ranking, and provenance remain higher priority than producing attractive figures.

## Current Production Path

- Use the root chain `main_double_wedge_part1.m -> main_double_wedge_part2.m -> main_double_wedge_part3.m -> main_double_wedge_part4.m`.
- Those root scripts dispatch to `Main_DoubleWedge_Part*_v6.m`.
- The active state layout is `primitive5_u_v_w_T_p`.
- Boundary rows are mask-driven through `src/core/apply_structured_bc_rows.m`.
- The active default profile is `sidharth2018_code_correction_v1`.
- The current correction route is no sponge + shock-localized SAV on + shock-source regularization off + pressure-row regularization off, unless a runner explicitly enables ablations.
- Legacy4 with nonzero `beta` must not silently proceed.

## Data And Boundary Contract

- Bundled local baseflow: `double_wedge_baseflow.dat`, header `I=270`, `J=128`.
- The local `270 x 128` file is a structural benchmark only, not final physical evidence.
- Intended physical case: `812 x 382`; final trusted physical baseflow and matching `boundary_condition.hypara` are not bundled.
- Current user-confirmed boundary set: top=`inlet`, south-upstream=`symmetry`, south-downstream=`wall`, east=`outlet`.
- Do not treat the top edge as `farfield` for the current double-wedge case.

## Current Implementation Highlights

- PHengLEI reader supports headered/headerless 11- and 12-column exports and preserves a twelfth `gama` column when present.
- `Part2_v6` records EOS, pressure-ratio, and compressible mass-continuity diagnostics instead of using screenshot-level evidence.
- `Part3_v6` saves `PressureRowAudit`, `BetaAssemblyAudit`, `PressureClosureAudit`, `PostBCAblationAudit`, and operator-ablation tables.
- `Part1_v6` and the main `run/` workflows now accept explicit flow-condition overrides for `Mach`, `Reynolds`, `T_inf`, `gamma`, and `Pr`, and keep derived nondimensional quantities synchronized through shared helpers.
- Wall thermal handling is now explicit across the active path: `wall_model` supports `adiabatic` and `isothermal`, `T_wall` is validated centrally, and `Part3` boundary rows switch between adiabatic and isothermal thermal constraints through `src/core/get_wall_thermal_bc_rows.m`.
- Spanwise `beta` terms are isolated in `src/core/build_paperA_beta_terms_v6.m`.
- Shock-localized SAV is assembled into the effective operator through `src/core/build_shock_localized_sav_matrix.m`.
- `Part4_v6` separates sorted lead, plot lead, and publication lead, and records plot/candidate provenance.
- Ranking now uses component-energy support by default and includes pressure-component checker/free-stream/outlet/shock-core gates.
- Residual-only fallback is diagnostic only; it must not emit physical plot candidates.
- For `beta=0` / inactive-`w'` plotted modes, the figure contract now keeps one unified literature-style bubble-component layout, automatically dropping near-zero `w'` panels and falling back to informative `u'/v'/T'/p'` views instead of a dedicated special figure.
- `refresh_saved_paperA_outputs` preserves saved Part4 sorted order and plot-lead indices by default when redrawing figures without re-solving eigs.
- Runner scripts expose low-memory descriptor controls, sigma-shift scans, beta scans, resolvent scans, and staged workflows.
- Baseflow validation and literature-context summaries now retain wall-model and target wall-temperature provenance so reused cases can reject mismatched thermal setups.

## Latest Validation Snapshot

- `run/run_phase2_validation.m` has passed locally on 2026-04-23 after the latest literature-style plot-contract refresh, Chinese figure-label updates, refresh-provenance, pressure-gate, beta-term, pressure-closure, and Sutherland-derivative fixes.
- A targeted non-`Part4` validation subset passed locally on 2026-04-24 after the new flow-override and wall-thermal additions, including `test_config_fields`, `test_part1_flow_wall_overrides`, `test_bc_rows`, `test_preprocess_baseflow_sutherland_derivatives`, `test_part3_beta_audit_smoke`, `test_run_user_test_baseflow_part3_only_v6`, `test_run_user_test_reuse_case_provenance_v6`, `test_run_sigma_shift_scan_part3_only_v6`, `test_run_beta_scan_part3_only_v6`, `test_run_resolvent_gain_scan_v6`, `test_run_research_workflow_part3_only_v6`, and `test_run_sidharth2018_workflow_part3_only_v6`.
- `Main_DoubleWedge_Part4_v6.m` was reviewed statically on 2026-04-24 with MATLAB `checkcode` only and was not executed in this validation pass.
- Latest retained local structural case: `outputs/mat/sidharth2018_structural_270x128_v6/`.
- Current retained structural summary reports a `Part4` bubble-centred plot candidate, `selection_status=physical_plot_candidates_available`, `publication_allowed=1`, `structural_only=1`, and `physics_reproduction_ready=0`.
- The retained structural case has been redrawn with the saved Part4 plot lead preserved and now includes `figs/Fig13_特征值谱.png`, `figs/Sidharth_Fig14_主模态分离泡分量图.png`, and `figs/Sidharth_Fig15_候选模态分量图_第01页.png`.
- Its refreshed summary now records `sidharth_component_contract=literature_style_bubble_components` and `sidharth_gallery_component=u`.
- User-facing summary text is now written as UTF-8 and localized conservatively: sponge/bubble/mode/spectrum/boundary-audit labels are translated where natural, while formula symbols such as `u`, `v`, `T`, `p`, and `sigma` remain unchanged.
- The retained structural case also refreshes the derivative-figure output name to `figs/Fig02_基本流导数_u_x_u_xx.png`, and redraws remove the legacy English `Fig02_BaseflowUxUxx.png`.
- Because the local case is structural-only, it does not validate the intended `812 x 382` physical spectrum.
- User-side `812 x 382` screenshots and OCR are archived under `archive/user_evidence/` and `results/user_812x382_ocr/`, but screenshots remain secondary evidence.

## Open Risks

- Treating the `270 x 128` structural result as physical validation.
- Accepting an `812 x 382` screenshot without checking `Part3_Results.mat`, `Part4_Results.mat`, and runner provenance.
- Mistaking a `no_physical_plot_candidates` result for code failure instead of a valid rejection by the current gates.
- Re-enabling shock-source or pressure-row regularization without labeling the run as an ablation.
- Running expensive `Part4` cases repeatedly without first checking cheap `Part3` audits.
- Boundary-label mismatch at corners or top edge.

## Recommended Next Task

For the intended `812 x 382` path, inspect `Part3_Results.mat` first: `PressureRowAudit`, `BetaAssemblyAudit`, `PressureClosureAudit`, `PostBCAblationAudit`, and row-scaling diagnostics. Only then decide whether a minimal refined `Part4` run, beta scan, or resolvent scan is justified.

## Handoff Rules

- Append `docs/coordination/TASK_LOG.md` after each completed task.
- Update this file when the active snapshot changes.
- Update `docs/coordination/WORK_QUEUE.md` when priorities change.
- Append `docs/audit.md` only for major solver, validation, or method changes.
