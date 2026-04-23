# Active Context

Last updated: 2026-04-22

## Current Objective

Preserve the double-wedge problem setup while moving the stability solver toward the method line centered on `paper/A.pdf`, with correctness and boundary validation ahead of optimization.

## Current Solver State

- The active production path is still the root-level `main_double_wedge_part1.m` through `main_double_wedge_part4.m`.
- The root entry files now dispatch into clean `v6` functions instead of the previous large inline scripts, so the production chain is once again parseable and maintainable.
- The old root-level `run.m` has been removed; use `run/run_all.m`, `run/run_phase2_validation.m`, or the explicit Part scripts.
- The production default state layout for the new main chain is now `primitive5_u_v_w_T_p`.
- Boundary-condition application is mask-driven through `src/core/apply_structured_bc_rows.m`.
- The active audit pass now runs the `v6` chain with sponge disabled by default, per the user request to remove sponge while checking operator correctness.
- The active pseudo-mode suppression route on the new chain is a shock-localized fourth-difference semi-artificial-viscosity matrix assembled by `src/core/build_shock_localized_sav_matrix.m` and added directly to `LNS_L`.
- The active primitive-five interior operator is now a direct Paper-A-style `v6` assembly in `Main_DoubleWedge_Part3_v6.m`.
- The user has now clarified the current double-wedge case boundary set explicitly: top=`inlet`, south-upstream=`symmetry`, south-downstream=`wall`, east=`outlet`. Do not treat the top edge as `farfield` for this case.
- A local PHengLEI Tecplot test file now exists at root as `double_wedge_baseflow.dat`; its header reports `I=270`, `J=128`, and the modular reader currently reduces it to `Nx=135`, `Ny=64` under the default stride settings.
- The repository has now been pruned to the Paper-A production path; runnable legacy4 and wall-relative plotting chains have been deleted.
- Active validation entry points are `run/run_phase2_validation.m`, `run/run_user_test_baseflow_fullres_v6.m`, and `run/run_paperA_validation_suite.m`.
- A new lightweight precheck entry now exists at `run/run_baseflow_import_audit_v6.m` so real-case imports can be audited for headerless column inference, EOS consistency, and pressure-ratio statistics before `Part2` hard-stops on the physical-case gate.
- The `v6` descriptor solver now supports lower-memory runs more directly: `run_user_test_baseflow_fullres_v6.m` passes optional Krylov floor/cap parameters into `Part1`, and `solve_paperA_descriptor_modes.m` now retries smaller `eigs` subspaces automatically when a shift fails due to memory pressure.
- The descriptor solver now has an explicit large-system low-memory plan: for `Ndof >= 4e5` it trims the shift family and total mode budget, and for `Ndof >= 1e6` it collapses to one primary shift with a very small per-shift candidate count before growing again. This is now the main guard against the `No finite eigenpairs were produced by the descriptor solve` failure seen on user-side `812 x 382` runs.
- The final intended production case is still `812 x 382`, and the repository still does not ship the final physical baseflow or a matching `boundary_condition.hypara` file.
- The modular reader now supports headerless PHengLEI exports for the intended `812 x 382` case by combining `cfg.reader.expected_dims` with automatic column-count inference; extra trailing columns beyond the required first 11 fields are ignored during import.
- The PHengLEI reader now treats 12-column files as a standard input shape rather than as an 11-column file with one “extra” column. Both headered and headerless 12-column exports are supported; when the twelfth `gama` column is present it is preserved in `base.gama` / `base.gamma_local`.
- The root legacy Part1 path still hardcodes `812 x 382`, so do not treat the current `270 x 128` file as a drop-in replacement for the final production run.
- The real-case `Part2_v6` EOS gate is now bulk-robust: it records full EOS percentile statistics and uses the 95th-percentile EOS error as the hard-stop metric, while leaving the pointwise max EOS error as a warning-only localized-outlier signal. This change was motivated by a user-side `812 x 382` audit showing that the worst EOS points were concentrated mainly in shock and corner regions even though the bulk pressure-ratio statistics stayed close to the expected equation of state.
- The real-case `Part2_v6` continuity gate no longer treats `ux + vy` as a hard-stop proxy for compressible continuity. `build_paperA_baseflow_context.m` now records both the old divergence proxy and a normalized compressible mass-continuity residual `|u*rhox + v*rhoy + rho*(ux+vy)| / (|u*rhox| + |v*rhoy| + |rho*ux| + |rho*vy|)`, and the real-case path only warns when either metric looks elevated.
- User-provided screenshots from a production-oriented `812 x 382` run show that the currently selected unstable mode (`sigma_r ~= +2.098e-01`, `St ~= 0.0664`) collapses into a compact upper-layer packet near `x ~= 56 to 60`, `y ~= 46 to 50` instead of locking onto the main separation bubble.
- A later user-side `812 x 382` screenshot showed a harder blocker before mode assessment: `solve_paperA_descriptor_modes.m` ran out of memory at `sigma = 0.05 + 0.02i` and then raised `No finite eigenpairs were produced by the descriptor solve`. The code now contains a dedicated low-memory fallback path for this case, but that exact real case has not yet been rerun inside this workspace.
- The current leading issue is now split into two layers: the new primitive-five chain is connected end-to-end and no longer blocked by corrupted root scripts, but real-case physical credibility still depends on validating the new operator on the intended `812 x 382` case and scanning `beta`.
- A new user-provided `beta = 8` screenshot on the intended-case path shows the plotted leading mode becoming strongly shock-dominated. Static audit now treats this as a combined risk from localized shock/corner baseflow outliers, unsafe shock-band dilation, aggressive shock regularization, and permissive Part4 plot-lead fallback rather than as trustworthy physics by default.
- The first high-priority repair batch is now in place: shock-mask dilation no longer wraps across boundaries, `Part4_v6` no longer silently promotes debug-only modes into default field figures, and saved mode diagnostics now include overlap with the EOS bad-point band and a compact corner neighborhood around the hinge.
- The second repair batch is now partially in place without rerunning the expensive real-case `Part4_v6` solve: `Part3_v6` now writes explicit `BetaAssemblyAudit` and `PressureClosureAudit` structs into `Part3_Results.mat`, and the spanwise `beta` terms are assembled through a dedicated helper rather than remaining buried inside the viscous-row helpers.
- The latest cheap-operator repair batch is now also in place without touching `Part4_v6`: `Part1_v6` and `validate_config.m` expose an explicit `use_shock_source_regularization` switch plus a dedicated `pressure_row_regularization` config block, and `Part3_v6` now writes a new `PressureRowAudit` struct into `Part3_Results.mat`.
- `Part3_v6` no longer treats "disable SAV" as if that automatically disabled every shock stabilization path. Shock-derivative clipping, second-derivative zeroing, and viscosity-gradient suppression now only activate when `use_shock_source_regularization = true`.
- The pressure-row path now has a dedicated helper `src/core/build_paperA_pressure_row_regularization_v6.m` that applies shock-localized clipping to the actual weighted coefficients entering `LPu`, `LPv`, and `LPP` (`px0/a^2`, `py0/a^2`, `div0/a^2`) while preserving the option to audit or suppress them explicitly.
- `run/run_user_test_baseflow_fullres_v6.m` is now a general runner rather than only a fixed benchmark wrapper: it accepts `RunPart4`, `Part3Variant`, and explicit SAV / shock-source / pressure-row override fields.
- A new editable script `run/run_global_stability_case_v6.m` now exposes those options through a top-of-file parameter block for manual user-side sweeps.
- A new helper `run/run_sigma_shift_scan_v6.m` now provides a reusable `SigmaShift` scan entry. The manual script can switch from one-shot solve mode to scan mode by filling `sigma_shift_list`.
- `run/run_sigma_shift_scan_v6.m` no longer collapses `SigmaTriplet=[]` into a one-shift solve when `LockSigmaTripletToShift=false`. Empty `SigmaTriplet` now correctly preserves the Part1 default shift family, while explicit locking still forces one shift per scan case. This matters for user-side downsampled `812 x 382` scans because the preserved default family keeps the per-case descriptor request much lighter than the accidental one-shift path.
- The runner layer now also exposes `ForceLowMemoryDescriptor`, which rewrites `Config.descriptor_solver.large_system_threshold` to `1` after `Part1` so user-side real-case scans can force the descriptor solve onto the existing large-system low-memory plan even when the downsampled `812 x 382` case still falls below the default `4e5` threshold.
- The active benchmark/profile contract is now explicit: `config_case()` and `Part1_v6` default to `sidharth2018_code_correction_v1`, and the `Sidharth2018` route now defaults to `no sponge + SAV on + shock-source off + pressure-row off` unless a runner explicitly re-enables the ablations.
- The no-sponge Sidharth correction route now also treats pressure-acoustic contamination as a first-class plot-selection risk: `compute_mode_filter_metrics.m` saves per-component checker/support diagnostics, and `rank_paperA_modes.m` rejects Sidharth plot candidates with high `p'` checker, free-stream, outlet-wall, or shock-core pressure support.
- `rank_paperA_modes.m` now keeps residual-only fallback strictly diagnostic: if no residual-clean mode passes the active checker gates, `ranking_candidate_mask` may still sort modes for tables, but `plot_candidate_mask` stays empty and no lead-mode disturbance cloud is emitted.
- The active production wrapper `main_double_wedge_part3.m` still dispatches to `Main_DoubleWedge_Part3_v6.m`. The archived `Main_DoubleWedge_Part3_v6_pre_pressure_fix_20260414.m` remains available only as a comparison branch through the new runner's `Part3Variant` option.
- The configurable runner now also writes `RunnerCaseMetadata.mat` and rejects `ReuseExistingCase=true` whenever the current request no longer matches the saved case identity or effective Part1/Part3 settings.
- `Part4_v6` no longer writes contradictory plotted-lead metadata: the saved sorted position and original mode index are now kept distinct, and the shared helper `src/core/resolve_part4_plot_lead_position.m` lets downstream tooling resolve both old and new result files safely.
- The reusable runner now handles `Part4_Results.mat` files with `no_physical_plot_candidate` status without crashing its summary path; it records that no plotted lead is available instead of fabricating one.
- `Part4_v6` now also saves coupled-mode audit fields (`ModeFamily_s`, `physical_candidate_score_s`, `bubble_shock_phase_deg_s`, `bubble_shock_sync_s`) together with a `ModeCouplingAudit` struct so bubble-centred and shock-bubble-coupled branches can be tracked without re-reading figures manually.
- `Part4_v6` now uses one shared `mode_filter_thresholds` bundle from `build_paperA_mode_filter_thresholds.m`; ranking and validity reports no longer carry separate hard-coded threshold copies.
- The Sidharth ranking support basis now defaults to `component_energy` rather than `u_dominant`, while still saving component-specific `u/v/w/T/p` diagnostics for detailed rejection analysis.
- Phase alignment now follows the selected `reference_component` first. For the Sidharth target this means `w`-reference modes anchor on `w'` before falling back to `u'`, and `PlotProvenanceAudit` records the requested and actual phase-anchor component.
- Plot-lead selection is now decoupled from the gallery subset: `plot_lead_candidate_mask` is the full eligible lead pool, while `selected_for_plots` only controls how many gallery modes are drawn.
- `selection_summary` now has explicit `sorted_lead`, `plot_lead`, and `publication_lead` records plus separate region-energy summaries; legacy `leading_*` fields are retained as plot-lead compatibility aliases only.
- Free-stream masks for Part4 now prefer `BaseflowMasks.free_stream_mask`; fallback construction uses configurable `mode_filter.free_stream_eta_threshold`.
- The literature-facing save contract is now broader:
  - `Part2_v6` saves `LiteratureBenchmarkAudit` and `BaseflowReferenceTable`
  - `Part3_v6` saves `PostBCAblationAudit` and `OperatorAblationTable`
  - `Part4_v6` saves `ComponentModeAudit`, `ModeReferenceTable`, `EigenReferenceTable`, `FigureCriteriaTable`, `PlotProvenanceAudit`, and `PlotContractAudit`
- `write_paperA_reference_figures.m` now enforces the no-physical-candidate figure contract and supports a separate Sidharth figure set when the benchmark profile requests it.
- `Part4_v6` now supports optional direct/adjoint lead diagnostics through `Config.analysis.compute_adjoint_lead`; successful runs save `AdjointLeadAudit` and `WavemakerLeadMap` for wavemaker localization of the plotted physical lead.
- `build_paperA_mode_masks.m` now constrains `shock_core` to the actual protected shock band used by `Part3_v6`, so near-wall rows intentionally removed from `ShockInfo.shock_mask` are no longer reintroduced as hard plot-ranking vetoes.
- `assert_realcase_boundary_contract.m` now excludes the side-owned top corners from the north-edge inlet contract, matching the deterministic corner ownership already used by `build_boundary_masks.m`.
- `setup_double_wedge_paths.m` now prefers the explicit/current workspace root before helper-path fallbacks and reprioritizes the active repo paths ahead of mirrored or stale-copy paths. The main `v6` entry points plus the reusable runner/scan scripts now resolve `project_root` through that helper instead of depending on `mfilename('fullpath')` alone.
- `rank_paperA_modes.m` now separates the debug-only ranking pool from the true plot-eligible candidate pool. When no mode passes the residual threshold, the code may still sort modes for diagnostics, but `selected_for_plots` stays empty and the saved selection status remains `no_physical_plot_candidates`.
- The runner layer now exposes `EnableAdjointLeadDiagnostics` and carries the new family/coupling/wavemaker fields into `run_summary.mat/.txt`, so scan scripts can compare leading-mode physics without opening `Part4_Results.mat` by hand.
- Two new reusable scan helpers now exist:
  - `run/run_beta_scan_v6.m` for branch-aware `beta` sweeps with saved per-case summaries and lead-correlation tracking,
  - `run/run_resolvent_gain_scan_v6.m` for Part3-based descriptor resolvent scans when the EVP is globally stable but strongly amplifying.
- A new staged workflow runner now exists:
  - `run/run_research_workflow_v6.m` packages the recommended sequence `Part3 audits -> regularization compare -> coarse beta scan -> refined Part4 -> resolvent`,
  - `run/run_research_workflow_case_v6.m` is the editable top-of-file script for user-side manual runs.
- A new preset wrapper `run/run_sidharth2018_workflow_v6.m` now packages the code-correction sequence for the Sidharth benchmark profile without requiring the caller to rebuild that parameter set by hand.
- The editable `run/run_research_workflow_case_v6.m` template now defaults to an explicit intended-case first pass rather than a mixed benchmark placeholder: `expected_dims = [812, 382]`, the caller must supply a real physical baseflow path before the script runs, `stride_x = stride_y = 3`, coarse `beta` scan stays on `Part3` only, refined `Part4` and resolvent stages start disabled, the default `beta` list and `n_eigs` values are lower, `SigmaTriplet` is pinned to the primary shift, and the Krylov floor/cap are explicitly reduced.
- `run/run_research_workflow_v6.m` now exposes `EnableRefinedAdjointLeadDiagnostics`, so the refined `Part4` stage no longer forces direct/adjoint diagnostics on memory-constrained runs unless the caller explicitly re-enables them.
- The old in-repo transfer bundle under `outputs/transfer/double_wedge_812x382_portable_20260416/` has now been removed to keep the workspace leaner and avoid carrying a full mirrored repo copy inside the main tree. Path-precedence regression now uses a synthetic temporary stale-copy fixture instead of a bundled transfer directory, and any future cross-machine transfer bundle should be generated on demand outside the main repo tree.
- The documentation layout has now been cleaned up: long-lived investigation and literature notes live under `docs/background/`, while stale one-off `PLAN.md`, `DEBUG_REPORT.md`, `FIX_LOG.md`, and superseded root-level fix-plan files have been removed.

## Latest Validation Snapshot

- Validation entry point: `run/run_phase2_validation.m`
- New v6 structural benchmark chain: `outputs/mat/paperA_validation_270x128_v6/`
- Recent smoke artifacts exist under:
- `outputs/mat/test_eigs_smoke.mat`
- `outputs/mat/paperA_validation_270x128_v6/Part4_Results.mat`
- `outputs/mat/paperA_validation_270x128_v6/run_summary.txt`
- `outputs/mat/paperA_validation_270x128_v6/figs/Fig13_EigenvalueSpectrum.png`
- `outputs/mat/paperA_validation_270x128_v6/figs/Fig18_LeadingModeNormalizationAudit.png`
- `outputs/mat/paperA_validation_270x128_v6/figs/Fig19_LeadingModeUVBubbleStreamlines.png`
- `outputs/mat/paperA_validation_270x128_v6/figs/Fig22_Top4Modes.png`
- The retained unit-test subset now passes under `run_phase2_validation`.
- The retained unit-test subset now also includes `test_setup_double_wedge_paths_precedence`; it verifies that the active workspace wins over a synthetic stale-copy fixture after `setup_double_wedge_paths(...)` reprioritizes the path.
- `test_matrix_sizes` no longer depends on a historical root-level `Part3_Results.mat` file. It now accepts an injectable result path and otherwise reuses or generates a cheap local `Part3` smoke artefact under `outputs/mat/test_run_user_test_part3_only_v6/`, so the retained suite passes without the old skip.
- The retained unit-test subset now also includes `test_paperA_beta_terms_v6`, `test_paperA_pressure_closure_audit_v6`, `test_paperA_pressure_row_regularization_v6`, `test_part3_beta_audit_smoke`, `test_run_user_test_baseflow_part3_only_v6`, `test_run_user_test_reuse_case_provenance_v6`, and `test_run_sigma_shift_scan_part3_only_v6`; all pass locally.
- The retained unit-test subset now also includes `test_mode_coupling_audit`, `test_direct_adjoint_lead_diagnostic`, `test_descriptor_resolvent_scan`, `test_run_beta_scan_part3_only_v6`, `test_run_resolvent_gain_scan_v6`, and `test_run_user_test_reuse_coupled_summary_v6`; all pass locally.
- The retained unit-test subset now also includes `test_run_research_workflow_part3_only_v6`, which keeps the new staged workflow runner wired to the existing `v6` path without paying for a full expensive scan.
- The retained unit-test subset now also includes `test_run_research_workflow_refined_part4_no_adjoint_v6`, which keeps the refined workflow path compatible with a tiny `Part4` case while locking in the new disabled-adjoint option.
- The retained unit-test subset now also includes `test_write_paperA_reference_figures_no_plot_candidate` and `test_run_sidharth2018_workflow_part3_only_v6`; the full local `run_phase2_validation` pass on 2026-04-22 is green with these additions included.
- A full local `run_phase2_validation` pass on 2026-04-23 is green after adding pressure-component checker gates and changing the default shock-source / pressure-row route to explicit ablations.
- A later full local `run_phase2_validation` pass on 2026-04-23 is green after tightening residual-only checker fallback and fixing the `u_peak_in_bubble` plot-lead selector score sign.
- Targeted no-`Part4` validation on 2026-04-23 is green after aligning support basis, reference-component phase anchors, lead provenance, threshold bundles, plot-lead candidate pools, and free-stream mask sourcing. The validation included mode-filter, phase-anchor, mask, plot-lead, reuse/provenance, and Part3-only smoke tests, but intentionally did not launch a new `Part4_v6` eigensolve.
- The retained unit-test subset now also includes `test_part2_mass_continuity_audit`, which locks in the new distinction between a nonzero divergence proxy and a near-zero compressible mass-continuity residual on a manufactured field.
- The retained unit-test subset now also includes `test_resolve_part4_plot_lead_position`, `test_realcase_boundary_contract`, and `test_run_user_test_reuse_no_plot_lead_v6`, which together lock in the new plotted-lead metadata contract, the north-edge side-corner exemption, and the no-plot Part4 reuse path without running a new expensive `Part4_v6` solve.
- A full local `run_phase2_validation` pass on 2026-04-22 now includes the new coupled-mode, adjoint, resolvent, beta-scan, reused-Part4-summary, and workflow-no-adjoint tests and passes end-to-end.
- A later 2026-04-21 cleanup pass also removed the old in-repo `outputs/transfer` mirror; `test_setup_double_wedge_paths_precedence` now uses a synthetic temp fixture instead, and a full local `run_phase2_validation` pass still succeeds after that cleanup.
- A full `270 x 128` default structural benchmark now completes through `Part4_v6` with `beta = 0`, `n_eigs = 50`, `sigma = 0.05 + 0.02i`, `sigma_triplet = [0.00+0.02i, 0.05+0.02i, 0.05+0.05i]`, `top_type = inlet`, and no sponge.
- `Part4_v6` now solves the full scaled descriptor pencil, ranks modes by residual/checker gates plus bubble/near-wall support, and plots only the reference figure contract.
- On the current smoke benchmark the active-row matrix row-norm ratio improves from `~1.36e5` before scaling to `~4.34e1`.
- The current default benchmark leading mode is `sigma ~= -7.343e-05 + 2.036e-02 i` with total residual `~2.47e-08`, bubble overlap `~3.94e-02`, near-wall fraction `~8.65e-01`, free-stream fraction `~1.09e-01`, shock fraction `~6.93e-01`, and checker ratio `~4.89e-02`.
- The new reference figures are no longer blank, but this latest benchmark leader is still shock-dominated rather than separation-bubble-dominated, so it remains a structural result instead of a physical acceptance case.
- This still does not promote the local `270 x 128` file into a trustworthy physical benchmark, because preprocessing and Part2 diagnostics remain weak on that file.
- A newer full fresh case under `outputs/mat/sidharth2018_structural_270x128_v6/` has now reached `Part3` and written fresh `Part1_Results.mat`, `Part2_Results.mat`, `Part3_Results.mat`, and `Diagnose_MatrixHealth_Report.mat`, but the `Part4` solve did not finish within the current CLI timeout window, so that run has not yet produced a new `Part4_Results.mat` or `run_summary.txt`.

## Latest Real-Case Observation

- Based on user-provided screenshots, a downsampled run derived from the intended `812 x 382` case selected a mode with `sigma_r ~= +2.098e-01` and `St ~= 0.0664`.
- The clearest reconstructed support is a smooth, compact, isolated packet above the downstream wedge segment around `x ~= 56 to 60`, `y ~= 46 to 50`.
- That spatial footprint is inconsistent with the expected dominant separation-bubble mode shape and is currently treated as a likely nonphysical interior pseudo-mode branch that slipped through the present ranking filters.
- The absolute contour magnitudes visible in the screenshots are normalization-dependent and should not be used alone as the rejection criterion; the main rejection signal is the spatial localization pattern.

## Biggest Open Risks

- Mistaking the new v5 smoke-chain completion for a full physical validation of the real double-wedge spectrum.
- Keeping the production-path boundary finite-difference closures at their current root-level one-sided form without re-checking their consistency against the paper-A intended centered-interior plus boundary-biased behavior.
- Using the unconfirmed top-edge physical interpretation as if it were geometry-verified.
- Treating the current filter strength choice as final before a real double-wedge baseflow case is available.
- Assuming smoke-level validation is enough for a real double-wedge physical case.
- Accepting any new primitive-five result as physical before a real `beta` scan and region-energy audit on the intended case.

## Recommended Next Task

Wait for or relaunch the fresh `outputs/mat/sidharth2018_structural_270x128_v6/` `Part4` solve with a longer wall-clock budget, then inspect whether the new publication-gating path now returns `no_physical_plot_candidate` or a genuinely bubble-centred plotted lead before using that case as evidence for the next physical-alignment step.

## Handoff Rules

- After every completed task, append `docs/coordination/TASK_LOG.md`.
- If the active snapshot changes, update this file in the same task.
- If priorities change, update `docs/coordination/WORK_QUEUE.md`.
- If the task is a major solver or validation change, append a short note to `docs/audit.md`.
