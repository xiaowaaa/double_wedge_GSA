# Task Log

Use append-only entries. For solver-history details before this coordination log was created, read the dated entries in `docs/audit.md`.

## 2026-04-21 - Added staged research workflow runner for double-wedge GSA

Summary:
- Added a new reusable workflow function `run/run_research_workflow_v6.m` that packages the current recommended research sequence:
  - cheap `Part3` audits,
  - optional regularization comparison,
  - coarse `beta` scan,
  - refined `Part4` with adjoint diagnostics,
  - optional resolvent scan.
- Added the editable script `run/run_research_workflow_case_v6.m` so the user can launch that staged workflow by changing one top-of-file parameter block instead of manually copying command snippets from chat.
- Kept the older `run/run_global_stability_case_v6.m` intact for one-shot or shift-focused runs, so the new workflow entry does not break the existing single-case debug path.
- Added `tests/test_run_research_workflow_part3_only_v6.m` and inserted it into `run/run_phase2_validation.m`.
- Re-ran the lightweight smoke check on the new workflow and then re-ran the full local `run_phase2_validation` suite successfully.

Files touched:
- `run/run_research_workflow_v6.m`
- `run/run_research_workflow_case_v6.m`
- `tests/test_run_research_workflow_part3_only_v6.m`
- `run/run_phase2_validation.m`
- `docs/coordination/ACTIVE_CONTEXT.md`
- `docs/coordination/TASK_LOG.md`
- `docs/coordination/WORK_QUEUE.md`
- `docs/audit.md`

Validation:
- `matlab -batch "cd('C:/Users/寒橘柚/Downloads/double_wedgeold'); setup_double_wedge_paths('IncludeTests', true); checkcode('run/run_research_workflow_v6.m','-id'); checkcode('run/run_research_workflow_case_v6.m','-id'); checkcode('tests/test_run_research_workflow_part3_only_v6.m','-id'); test_run_research_workflow_part3_only_v6;"`
- `matlab -batch "cd('C:/Users/寒橘柚/Downloads/double_wedgeold'); setup_double_wedge_paths('IncludeTests', true); run_phase2_validation;"`

Next handoff:
- For the intended `812 x 382` case, start from `run/run_research_workflow_case_v6.m`, replace the benchmark file path and dimensions, and keep the first pass conservative:
  `Part3 audits -> regularization compare -> coarse beta scan`.
- Only after those stages look sane should the workflow proceed to refined `Part4` and the resolvent stage.

## 2026-04-21 - Coupled-mode / adjoint / resolvent research-path wiring for the v6 chain

Summary:
- Extended the active `v6` Part4 path so mode ranking no longer stops at residual-plus-bubble heuristics. `rank_paperA_modes.m` now builds a dedicated coupling audit that classifies `bubble_centred`, `shock_bubble_coupled`, `shock_dominated`, `boundary_supported`, and compact-interior candidates while exposing `physical_candidate_score`, bubble-shock phase, and sync metrics.
- `Main_DoubleWedge_Part4_v6.m` now saves those family/coupling diagnostics explicitly and can optionally compute one direct/adjoint lead audit through `Config.analysis.compute_adjoint_lead`, saving both `AdjointLeadAudit` and `WavemakerLeadMap`.
- Promoted the new diagnostics into the runner layer: `run_user_test_baseflow_fullres_v6.m` now normalizes the new config field, summarizes leading-mode family/coupling metadata, and carries adjoint/wavemaker fields into `run_summary.mat/.txt`.
- Added two reusable method-level scan entry points aligned with the current research plan:
  - `run/run_beta_scan_v6.m` for branch-aware `beta` scans,
  - `run/run_resolvent_gain_scan_v6.m` plus `src/core/compute_descriptor_resolvent_scan.m` for globally stable but strongly amplifying cases.
- Added focused tests for the new research-path pieces:
  - `test_mode_coupling_audit`
  - `test_direct_adjoint_lead_diagnostic`
  - `test_descriptor_resolvent_scan`
  - `test_run_beta_scan_part3_only_v6`
  - `test_run_resolvent_gain_scan_v6`
  - `test_run_user_test_reuse_coupled_summary_v6`
- Updated the retained validation suite and re-ran the full local `run_phase2_validation` pass successfully.

Files touched:
- `Main_DoubleWedge_Part1_v6.m`
- `Main_DoubleWedge_Part4_v6.m`
- `src/core/build_mode_coupling_audit.m`
- `src/core/build_scaled_descriptor_pencil_v6.m`
- `src/core/compute_descriptor_resolvent_scan.m`
- `src/core/compute_direct_adjoint_lead_diagnostic.m`
- `src/core/compute_mode_support_field.m`
- `src/core/compute_mode_filter_metrics.m`
- `src/core/rank_paperA_modes.m`
- `src/core/select_paperA_plot_lead_index.m`
- `src/core/solve_paperA_descriptor_modes.m`
- `src/core/validate_config.m`
- `run/run_beta_scan_v6.m`
- `run/run_phase2_validation.m`
- `run/run_resolvent_gain_scan_v6.m`
- `run/run_user_test_baseflow_fullres_v6.m`
- `tests/test_mode_coupling_audit.m`
- `tests/test_direct_adjoint_lead_diagnostic.m`
- `tests/test_descriptor_resolvent_scan.m`
- `tests/test_run_beta_scan_part3_only_v6.m`
- `tests/test_run_resolvent_gain_scan_v6.m`
- `tests/test_run_user_test_reuse_coupled_summary_v6.m`
- `docs/coordination/ACTIVE_CONTEXT.md`
- `docs/coordination/TASK_LOG.md`
- `docs/coordination/WORK_QUEUE.md`
- `docs/audit.md`

Validation:
- `matlab -batch "cd('C:/Users/寒橘柚/Downloads/double_wedgeold'); setup_double_wedge_paths('IncludeTests', true); test_mode_coupling_audit; test_direct_adjoint_lead_diagnostic; test_descriptor_resolvent_scan; test_run_user_test_reuse_coupled_summary_v6;"`
- `matlab -batch "cd('C:/Users/寒橘柚/Downloads/double_wedgeold'); setup_double_wedge_paths('IncludeTests', true); test_plot_lead_selection; test_run_user_test_baseflow_part3_only_v6; test_run_user_test_reuse_no_plot_lead_v6; test_run_sigma_shift_scan_part3_only_v6; test_run_beta_scan_part3_only_v6; test_run_resolvent_gain_scan_v6;"`
- `matlab -batch "cd('C:/Users/寒橘柚/Downloads/double_wedgeold'); setup_double_wedge_paths('IncludeTests', true); run_phase2_validation;"`

Next handoff:
- On the intended `812 x 382` case, keep the sequence `Part3 audits -> no-Part4 regularization comparison -> beta scan -> resolvent scan -> minimum necessary Part4 solve`.
- Use the new family/coupling and adjoint fields as the first filter before deciding whether a leading mode is bubble-centred physics, shock-bubble coupling, or a numerical/support-boundary artefact.

## 2026-04-16 - Literature validation benchmark summary for double-wedge global stability

Summary:
- Added a dedicated background note `docs/background/global_stability_validation_benchmarks.md` to consolidate what the current double-wedge global-stability solver can and should validate against literature.
- Structured the note around the four comparison classes the user asked for directly:
  - modal images,
  - base-flow conditions,
  - concrete eigenvalue or growth-rate or frequency data,
  - eigenspectrum or branch-topology references.
- Mapped those literature checks back onto the current repo outputs so future runs can be audited more systematically through `Part1_Results.mat` to `Part4_Results.mat` instead of only through screenshots.
- Prioritized three primary benchmark families:
  - `Sidharth et al. 2018` for the slender-double-wedge global-mode bifurcation and branch structure,
  - `Sawant et al. 2022` for shock-layer/LSB synchronized instability and low-frequency unsteadiness on the `30-55` double wedge,
  - `Hao et al. 2021` for a scaled-angle stability-boundary sanity check that also cites the double-wedge threshold data.
- Marked each literature number with an explicit reliability level:
  - exact values stated directly in the source,
  - approximate values inferred from captions or figure context.

Files touched:
- `docs/background/global_stability_validation_benchmarks.md`
- `docs/coordination/TASK_LOG.md`

Validation:
- Not run. This task is literature consolidation and documentation only.

Next handoff:
- Use the new validation note as the template for the next real-case comparison table.
- When the user provides a specific target case, instantiate one run sheet with side-by-side columns for:
  `base flow`, `mode image`, `leading eigenvalue`, `wavelength`, and `spectrum topology`.

## 2026-04-20 - Path-precedence hardening and no-plot fallback enforcement without Part4 reruns

Summary:
- Hardened repo path resolution so the active workspace now wins over mirrored or transfer-copy paths during MATLAB runs. `setup_double_wedge_paths.m` now prefers the explicit/current workspace root before helper-path fallbacks, canonicalizes path comparisons, removes duplicate canonical entries, and re-adds the active repo paths at the front of the MATLAB path.
- Updated the active `v6` production entry points and reusable runner scripts to resolve `project_root` through `setup_double_wedge_paths()` instead of relying only on `mfilename('fullpath')`. This keeps case outputs, summaries, and follow-on helper resolution inside the active workspace when a stale copy is also on the MATLAB path.
- Tightened `src/core/rank_paperA_modes.m` so debug-only fallback and true plot eligibility are now separated. When no mode passes the residual threshold, the code can still keep a debug ranking order, but `plot_candidate_mask`, `selected_for_plots`, and the saved selection status now remain explicitly empty / `no_physical_plot_candidates`.
- Added `tests/test_setup_double_wedge_paths_precedence.m` to reproduce the path-shadowing scenario against the bundled transfer copy. Expanded `tests/test_plot_lead_selection.m` with a high-residual bubble-looking regression, and rewrote `tests/test_matrix_sizes.m` so it reuses or generates a cheap local `Part3_Results.mat` artefact instead of skipping on a historical root file.
- Re-ran the retained `run_phase2_validation` suite on the cheap path only. All tests passed, including the new path-precedence regression and the no-longer-skipped matrix-size check, without launching a new expensive `Part4_v6` solve.

Files touched:
- `setup_double_wedge_paths.m`
- `src/core/rank_paperA_modes.m`
- `Main_DoubleWedge_Part1_v6.m`
- `Main_DoubleWedge_Part2_v6.m`
- `Main_DoubleWedge_Part3_v6.m`
- `Main_DoubleWedge_Part3_v6_pre_pressure_fix_20260414.m`
- `Main_DoubleWedge_Part4_v6.m`
- `run/config_case.m`
- `run/run_all.m`
- `run/run_baseflow_import_audit_v6.m`
- `run/run_beta4_part4_shift_scan_v6.m`
- `run/run_global_stability_case_v6.m`
- `run/run_paperA_validation_suite.m`
- `run/run_phase2_validation.m`
- `run/run_sigma_shift_scan_v6.m`
- `run/run_user_test_baseflow_fullres_v6.m`
- `tests/test_setup_double_wedge_paths_precedence.m`
- `tests/test_matrix_sizes.m`
- `tests/test_plot_lead_selection.m`
- `tests/test_run_sigma_shift_scan_part3_only_v6.m`
- `tests/test_run_user_test_baseflow_part3_only_v6.m`
- `tests/test_run_user_test_reuse_case_provenance_v6.m`
- `tests/test_run_user_test_reuse_no_plot_lead_v6.m`
- `docs/coordination/ACTIVE_CONTEXT.md`
- `docs/coordination/TASK_LOG.md`
- `docs/audit.md`

Validation:
- `matlab -batch "<checkcode loop over modified path/ranking/runner/test files>"`
- `matlab -batch "cd('C:/Users/寒橘柚/Downloads/double_wedgeold'); addpath(pwd); addpath(fullfile(pwd,'run')); run_phase2_validation;"`

Next handoff:
- Keep using the cheap path for real-case debugging: inspect `PressureRowAudit`, `BetaAssemblyAudit`, and `PressureClosureAudit` on the user-side `812 x 382` case before any new `Part4_v6` solve.
- If another path-shadowing report appears, check `test_setup_double_wedge_paths_precedence` first before touching solver physics.

## 2026-04-15 - Consolidated change ledger for the current v6 repair campaign

Summary:
- Added a cumulative log entry so the current repair campaign can be reconstructed from one place instead of only from scattered dated notes.
- Baseflow import and preprocessing side:
  - updated the PHengLEI reader to accept both headered and headerless 12-column exports,
  - preserved the twelfth `gama` column explicitly,
  - added `run/run_baseflow_import_audit_v6.m` for cheap EOS or pressure-ratio inspection before entering `Part2_v6`,
  - reworked the real-case EOS hard gate in `Main_DoubleWedge_Part2_v6.m` to use a bulk-robust percentile metric while keeping localized shock or corner outliers as warnings and diagnostics.
- Runtime and entry-point robustness side:
  - added a low-memory descriptor fallback in `solve_paperA_descriptor_modes.m`,
  - exposed low-memory Krylov controls through `Main_DoubleWedge_Part1_v6.m` and `run/run_user_test_baseflow_fullres_v6.m`,
  - relaxed project-root detection in `setup_double_wedge_paths.m` so the helper recognizes the `Main_DoubleWedge_Part3_v6.m` style root marker as well.
- Plot and reporting side:
  - localized the final reference-figure display titles in `src/core/write_paperA_reference_figures.m` to Chinese while leaving file names unchanged,
  - kept the figure path safer by skipping misleading default field plots when no physical plot candidate exists,
  - split sorted-leading and plotted-leading semantics explicitly inside `Part4_v6`.
- Shock and ranking repair side:
  - replaced the `circshift`-based shock dilation with the non-wrapping helper `src/core/dilate_mask_no_wrap.m`,
  - carried `eos_bad_point_mask` and a compact hinge `corner_mask` into the formal mode-diagnostic chain,
  - added overlap metrics for corner and bad-point bands,
  - removed the silent plotted-mode fallback in `rank_paperA_modes.m` and `select_paperA_plot_lead_index.m`.
- Second-round `Part3` audit side:
  - extracted the spanwise `beta` terms into `src/core/build_paperA_beta_terms_v6.m`,
  - added `src/core/build_paperA_pressure_closure_audit_v6.m`,
  - now save `BetaAssemblyAudit` and `PressureClosureAudit` directly into `Part3_Results.mat` without needing a full `Part4_v6` rerun.
- Documentation and investigation side:
  - added `investigation_report.md`,
  - added `literature_shock_pollution_survey.md`,
  - added `root_cause_fix_plan.md`,
  - added `full_code_check_and_fix_plan.md`,
  - synchronized `ACTIVE_CONTEXT.md`, `WORK_QUEUE.md`, and `docs/audit.md` after each major repair batch.

Files touched in this campaign:
- `src/core/read_phenglei_baseflow.m`
- `run/config_case.m`
- `run/run_baseflow_import_audit_v6.m`
- `Main_DoubleWedge_Part1_v6.m`
- `Main_DoubleWedge_Part2_v6.m`
- `Main_DoubleWedge_Part3_v6.m`
- `Main_DoubleWedge_Part4_v6.m`
- `src/core/solve_paperA_descriptor_modes.m`
- `src/core/validate_config.m`
- `setup_double_wedge_paths.m`
- `src/core/dilate_mask_no_wrap.m`
- `src/core/build_shock_localized_sav_matrix.m`
- `src/core/build_paperA_baseflow_context.m`
- `src/core/build_paperA_mode_masks.m`
- `src/core/compute_mode_filter_metrics.m`
- `src/core/rank_paperA_modes.m`
- `src/core/select_paperA_plot_lead_index.m`
- `src/core/write_paperA_reference_figures.m`
- `src/core/build_paperA_beta_terms_v6.m`
- `src/core/build_paperA_pressure_closure_audit_v6.m`
- `run/run_phase2_validation.m`
- `tests/test_read_phenglei_headerless_infer_num_vars.m`
- `tests/test_read_phenglei_multiline_zone_header.m`
- `tests/test_descriptor_solver_low_memory.m`
- `tests/test_dilate_mask_no_wrap.m`
- `tests/test_plot_lead_selection.m`
- `tests/test_paperA_mode_masks.m`
- `tests/test_paperA_beta_terms_v6.m`
- `tests/test_paperA_pressure_closure_audit_v6.m`
- `tests/test_part3_beta_audit_smoke.m`
- `investigation_report.md`
- `literature_shock_pollution_survey.md`
- `root_cause_fix_plan.md`
- `full_code_check_and_fix_plan.md`
- `docs/coordination/ACTIVE_CONTEXT.md`
- `docs/coordination/WORK_QUEUE.md`
- `docs/coordination/TASK_LOG.md`
- `docs/audit.md`

Validation:
- Reader regression checks for headered or headerless 12-column PHengLEI files.
- Low-memory descriptor-solver regression checks.
- Shock-mask no-wrap regression checks.
- Plot-lead selection regression checks.
- Mode-mask and overlap regression checks.
- `Part3_v6` beta-term and pressure-closure regression checks.
- `Part3_v6` smoke validation that stops before a full `Part4_v6` eigensolve.
- Retained validation subset through `run/run_phase2_validation.m`, with the same long-standing `test_matrix_sizes` skip for a missing external root `Part3_Results.mat`.

Next handoff:
- Keep using `Part3_Results.mat` plus the new audit fields as the first inspection point on the expensive real `812 x 382`, `beta = 8` path.
- Delay any new full `Part4_v6` rerun until the cheaper `Part3` audits and post-BC blockwise checks say the operator path looks sane.

## 2026-04-15 - Part3 beta-term audit and pressure-closure diagnostics without full Part4 rerun

Summary:
- Continued the second-round repair pass without rerunning the full real-case `Part4_v6` solve, per the new user constraint that `Part4` is too expensive to repeat casually.
- Extracted all explicit spanwise-`beta` contributions from `Main_DoubleWedge_Part3_v6.m` into a new shared helper `src/core/build_paperA_beta_terms_v6.m` so the linear `-i*beta` couplings and quadratic `-mu*beta^2` damping terms can be checked independently of the rest of the primitive-five assembly.
- Added a second helper `src/core/build_paperA_pressure_closure_audit_v6.m` so each `Part3_v6` run now records structural closure checks for `pressure_scale`, `rho_from_p`, `rho_from_T`, and the imported EOS consistency range instead of leaving those relations implicit inside the operator assembly.
- Updated `Main_DoubleWedge_Part3_v6.m` to save the new `BetaAssemblyAudit` and `PressureClosureAudit` structs directly into `Part3_Results.mat`, giving a cheaper inspection path before any long descriptor solve or plotting step.
- Added three regression tests: `test_paperA_beta_terms_v6.m`, `test_paperA_pressure_closure_audit_v6.m`, and `test_part3_beta_audit_smoke.m`; the last one stops after `Part3_v6` and verifies that the saved MAT file carries the new audit fields on a tiny synthetic case.
- Re-ran the retained validation subset with the new tests included; the suite passed with the same pre-existing `test_matrix_sizes` skip caused by a missing external root `Part3_Results.mat`.

Files touched:
- `Main_DoubleWedge_Part3_v6.m`
- `src/core/build_paperA_beta_terms_v6.m`
- `src/core/build_paperA_pressure_closure_audit_v6.m`
- `tests/test_paperA_beta_terms_v6.m`
- `tests/test_paperA_pressure_closure_audit_v6.m`
- `tests/test_part3_beta_audit_smoke.m`
- `run/run_phase2_validation.m`

Validation:
- `matlab -batch "cd('C:/Users/UserX/Downloads/double_wedgeold'); setup_double_wedge_paths('StartDir',pwd,'IncludeTests',true); test_paperA_beta_terms_v6; test_paperA_pressure_closure_audit_v6; test_part3_beta_audit_smoke;"`
- `matlab -batch "cd('C:/Users/UserX/Downloads/double_wedgeold'); addpath(pwd); addpath(fullfile(pwd,'run')); run_phase2_validation;"`

Next handoff:
- Use the new `Part3_Results.mat` audit fields on the user-side `beta = 8` path before spending time on another full `Part4_v6` solve.
- Then extend the blockwise audit one step further so post-BC row overwrite norms can be compared against the pre-BC interior beta-term diagnostics.

## 2026-04-14 - Shock-mask wrap fix, strict plotted-lead gating, and overlap diagnostics

Summary:
- Replaced the `circshift`-based shock-mask dilation with a shared non-wrapping helper `src/core/dilate_mask_no_wrap.m` and wired both `Main_DoubleWedge_Part3_v6.m` and `src/core/build_shock_localized_sav_matrix.m` to use it.
- Extended the formal baseflow-mask contract so `Part2_v6` now carries `eos_bad_point_mask` forward and `build_paperA_baseflow_context.m` now builds a compact geometric `corner_mask` around the hinge.
- Updated `build_paperA_mode_masks.m`, `compute_mode_filter_metrics.m`, and `Main_DoubleWedge_Part4_v6.m` so `corner` and `bad-point` overlaps now appear in the saved mode diagnostics and ranking outputs.
- Removed the silent plotted-mode fallback: `rank_paperA_modes.m` no longer auto-selects the first 4 sorted modes when no physical plot candidate exists, and `select_paperA_plot_lead_index.m` now returns an explicit `no_physical_plot_candidate` status.
- `Part4_v6` now distinguishes sorted-leading and plotted-leading semantics more explicitly via `selection_summary`, `lambda_sorted_lead`, and `lambda_plotted_lead`, while `write_paperA_reference_figures.m` now skips misleading field figures when no physical plot candidate exists and only emits the eigenspectrum in that case.

Files touched:
- `src/core/dilate_mask_no_wrap.m`
- `Main_DoubleWedge_Part2_v6.m`
- `Main_DoubleWedge_Part3_v6.m`
- `Main_DoubleWedge_Part4_v6.m`
- `src/core/build_paperA_baseflow_context.m`
- `src/core/build_paperA_mode_masks.m`
- `src/core/build_shock_localized_sav_matrix.m`
- `src/core/compute_mode_filter_metrics.m`
- `src/core/rank_paperA_modes.m`
- `src/core/select_paperA_plot_lead_index.m`
- `src/core/write_paperA_reference_figures.m`
- `tests/test_dilate_mask_no_wrap.m`
- `tests/test_plot_lead_selection.m`
- `tests/test_paperA_mode_masks.m`
- `run/run_phase2_validation.m`

Validation:
- `matlab -batch "setup_double_wedge_paths('StartDir',pwd,'IncludeTests',true); test_dilate_mask_no_wrap; test_paperA_mode_masks; test_plot_lead_selection;"`
- `matlab -batch "cd('C:/Users/UserX/Downloads/double_wedgeold'); addpath(pwd); addpath(fullfile(pwd,'run')); run_phase2_validation;"`

Next handoff:
- Use the new overlap diagnostics on the real `812 x 382` path and check whether the leading branch still concentrates in shock or corner bad-point bands.
- Then move to the planned `beta` term audit in `Part3_v6`.

## 2026-04-14 - Beta=8 shock-dominated mode audit and full fix plan

Summary:
- Investigated a new user-provided `beta = 8` figure where the default plotted leading mode is strongly aligned with the shock band instead of the main separation bubble.
- Rechecked the full static chain from `Part2_v6` through `Part4_v6` against the earlier audit findings and the newly confirmed real-case EOS outlier localization in the shock and corner regions.
- The strongest current explanation is a stacked failure chain rather than one isolated bug: localized shock/corner baseflow outliers enter `Part3_v6`, the shock-band dilation still uses unsafe `circshift` wrap-around, the shock regularization remains aggressive once that mask is built, and `Part4_v6` can still promote a relaxed fallback mode into the default figure set.
- Confirmed that the `v6` operator does include explicit `beta`-dependent terms, so the issue is not simply “beta is ignored”; however, the large-`beta` branch is not yet protected by a dedicated regression suite and still requires term-by-term audit and rerun after the ranking and shock-mask fixes.
- Added a dedicated planning document `root_cause_fix_plan.md` that prioritizes: non-wrapping shock dilation, explicit plotted-lead failure on missing physical candidates, overlap diagnostics against shock/corner bad-point bands, and a focused beta-term audit in `Part3_v6`.

Files touched:
- `root_cause_fix_plan.md`
- `docs/coordination/ACTIVE_CONTEXT.md`
- `docs/coordination/WORK_QUEUE.md`
- `docs/coordination/TASK_LOG.md`
- `docs/audit.md`

Validation:
- Not run. This batch is static audit plus planning documentation only.

Next handoff:
- Fix the wrap-around shock dilation first.
- Then remove the silent plotted-lead fallback in `Part4_v6`.
- Only after those two fixes rerun the real-case `beta = 8` path and interpret the result.

## 2026-04-14 - Robust real-case EOS gate for localized shock or corner outliers

Summary:
- Investigated the user-side `812 x 382` `Part2_v6` hard-stop where `eos_relative_error ~= 3.55e-01` blocked the run even though the import audit showed bulk pressure-ratio statistics close to the expected equation of state.
- The user then localized the worst EOS points and confirmed that they were concentrated mainly in the shock region and near a geometric corner rather than spread through the bulk field.
- Updated `Main_DoubleWedge_Part2_v6.m` so `BaseflowPhysicsAudit` now stores full EOS percentile stats, bad-point count or fraction, and pressure-ratio stats directly in the saved Part2 audit struct.
- Changed the real-case EOS hard-stop to use the 95th-percentile EOS error as the bulk-pass criterion while keeping the pointwise max EOS error as a warning-only localized-outlier signal.
- Left the continuity gate unchanged and did not alter the Part3 or Part4 numerical operator path in this batch.

Files touched:
- `Main_DoubleWedge_Part2_v6.m`
- `docs/coordination/ACTIVE_CONTEXT.md`
- `docs/coordination/WORK_QUEUE.md`
- `docs/coordination/TASK_LOG.md`
- `docs/audit.md`

Validation:
- `matlab -batch "addpath(fullfile(pwd,'run')); run_phase2_validation;"`

Next handoff:
- Rerun the user-side `812 x 382` case through `Part2_v6` and verify that the EOS warning now reports only localized shock or corner outliers instead of hard-stopping.
- If `Part2_v6` passes, continue to the low-memory `Part4_v6` solve and immediately re-audit the plotted leading mode.

## 2026-04-14 - Reader contract update for headered or headerless 12-column PHengLEI files

Summary:
- Updated the PHengLEI baseflow reader so 12-column exports are treated as a standard format whether or not a Tecplot header is present.
- Preserved the twelfth `gama` column in `base.gama` / `base.gamma_local` instead of reporting it as a generic extra column.
- Kept backward compatibility with older 11-column files by leaving the required column count at 11 while setting the reader default expected column count to 12.
- Expanded the reader regression tests so both the headerless and multiline-header paths now exercise a 12-column contract explicitly.

Files touched:
- `src/core/read_phenglei_baseflow.m`
- `run/config_case.m`
- `run/run_baseflow_import_audit_v6.m`
- `tests/test_read_phenglei_headerless_infer_num_vars.m`
- `tests/test_read_phenglei_multiline_zone_header.m`
- `docs/coordination/ACTIVE_CONTEXT.md`
- `docs/coordination/TASK_LOG.md`
- `docs/audit.md`

Validation:
- `matlab -batch "addpath(pwd); addpath(fullfile(pwd,'run')); addpath(fullfile(pwd,'src','core')); addpath(fullfile(pwd,'tests')); test_read_phenglei_headerless_infer_num_vars; test_read_phenglei_multiline_zone_header;"`
- `matlab -batch "addpath(pwd); addpath(fullfile(pwd,'run')); addpath(fullfile(pwd,'src','core')); addpath(fullfile(pwd,'tests')); run(fullfile('run','run_phase2_validation.m'));"`

Next handoff:
- If a user provides another PHengLEI export variant, check whether the first 12 columns still follow `x y z rho u v w p T mach cp gama` before changing the mapping.

## 2026-04-14 - Descriptor low-memory fallback for 812x382 Part4 failures

Summary:
- Investigated a new user-side `812 x 382` screenshot showing `solve_paperA_descriptor_modes.m` failing at `sigma = 0.05 + 0.02i` with an out-of-memory error and then raising `No finite eigenpairs were produced by the descriptor solve`.
- Reworked the descriptor solve planning so large systems now enter an explicit low-memory policy before calling `eigs`: the shift family is reordered around `Config.sigma`, the total requested mode budget is reduced, the number of shifts is capped, and each shift is retried with progressively smaller `k/p` pairs.
- Added persistent config defaults for the new `descriptor_solver` policy in both `validate_config.m` and `Main_DoubleWedge_Part1_v6.m`.
- Added a regression test that forces the huge-system low-memory path and verifies that the solver trims the shift family and mode budget as intended.
- Revalidated the retained Paper-A test suite after the solver change.

Files touched:
- `src/core/solve_paperA_descriptor_modes.m`
- `src/core/validate_config.m`
- `Main_DoubleWedge_Part1_v6.m`
- `tests/test_config_fields.m`
- `tests/test_descriptor_solver_low_memory.m`
- `run/run_phase2_validation.m`
- `docs/coordination/ACTIVE_CONTEXT.md`
- `docs/coordination/WORK_QUEUE.md`
- `docs/coordination/TASK_LOG.md`
- `docs/audit.md`

Validation:
- `matlab -batch "addpath(pwd); addpath(fullfile(pwd,'src','core')); addpath(fullfile(pwd,'tests')); test_descriptor_solver_low_memory;"`
- `matlab -batch "addpath(pwd); addpath(fullfile(pwd,'src','core')); addpath(fullfile(pwd,'tests')); run(fullfile('run','run_phase2_validation.m'));"`

Next handoff:
- Rerun the failing `812 x 382` case through `Main_DoubleWedge_Part4_v6` or `run_user_test_baseflow_fullres_v6` with the updated solver.
- Once finite eigenpairs exist again, immediately audit `shock_core_energy_frac` and `u_peak_in_shock_core` before trusting any plotted mode.

## 2026-04-08 - Collaboration logging bootstrap and folder classification

Summary:
- Added a dedicated coordination area under `docs/coordination/` so two Codex accounts can recover context quickly.
- Standardized three stable handoff files: `ACTIVE_CONTEXT.md`, `WORK_QUEUE.md`, and this `TASK_LOG.md`.
- Added `docs/PROJECT_STRUCTURE.md` so the file layout and root-level exceptions are explicit.
- Added `outputs/logs/README.md` so the repository now has the declared log directory for diary and text outputs.
- Reworked `README_codex_handoff.md` into a compact cross-account entry page that points new sessions to the coordination docs.

Files touched:
- `README.md`
- `README_codex_handoff.md`
- `docs/audit.md`
- `docs/PROJECT_STRUCTURE.md`
- `docs/coordination/README.md`
- `docs/coordination/ACTIVE_CONTEXT.md`
- `docs/coordination/WORK_QUEUE.md`
- `docs/coordination/TASK_LOG.md`
- `outputs/logs/README.md`

Validation:
- Not run. This batch is documentation and file-organization only.

Next handoff:
- Continue from `docs/coordination/WORK_QUEUE.md`, starting with the direct primitive-five interior assembly task.

## 2026-04-09 - Legacy4 semi-artificial-viscosity filter pass

Summary:
- Switched the production default back to the legacy four-variable layout `legacy4_rho_u_v_T`.
- Disabled sponge damping by default for this phase.
- Replaced the old pressure-gradient-sensor diagonal damping on the main Part3 path with a fourth-difference Hildebrand-style semi-artificial-viscosity matrix added directly to `LNS_L`.
- Added a unit test for the exact filter stencil and a synthetic `epsilon_av` scan driver with saved figure, MAT summary, and text log.
- Ran targeted tests and the broader validation script successfully.

Files touched:
- `main_double_wedge_part1.m`
- `main_double_wedge_part3.m`
- `validate_config.m`
- `src/core/validate_config.m`
- `src/core/build_semi_artificial_viscosity_matrix.m`
- `tests/test_config_fields.m`
- `tests/test_semi_artificial_viscosity_matrix.m`
- `run/run_legacy4_semi_artificial_viscosity_scan.m`
- `run/run_phase2_validation.m`
- `README_codex_handoff.md`
- `docs/audit.md`
- `docs/coordination/ACTIVE_CONTEXT.md`
- `docs/coordination/WORK_QUEUE.md`
- `docs/coordination/TASK_LOG.md`

Validation:
- `test_config_fields`
- `test_semi_artificial_viscosity_matrix`
- `run_legacy4_semi_artificial_viscosity_scan`
- `run_phase2_validation`

Artifacts:
- `outputs/figs/legacy4_semi_artificial_viscosity_scan.png`
- `outputs/mat/legacy4_semi_artificial_viscosity_scan.mat`
- `outputs/logs/legacy4_semi_artificial_viscosity_scan.log`

Next handoff:
- Wait for a real double-wedge baseflow and run the legacy4 `epsilon_av` sweep on the real case before changing larger solver architecture.

## 2026-04-09 - Folder cleanup and file classification

Summary:
- Removed the unreferenced duplicate `AGENTS_updated.md` from the repository root.
- Removed the root-level `run.m` so MATLAB's built-in `run(...)` can be used again without name shadowing.
- Created `docs/prompts/` and moved the saved task prompt there.
- Created `paper/notes/` and moved the longer literature-comparison markdown files there.
- Deleted the unreferenced `paper/S_pages/` extracted-page image directory.
- Updated the structure and handoff docs so the new layout is explicit for the next Codex account.

Files touched:
- `README_codex_handoff.md`
- `docs/PROJECT_STRUCTURE.md`
- `docs/audit.md`
- `docs/coordination/ACTIVE_CONTEXT.md`
- `docs/coordination/TASK_LOG.md`
- `docs/prompts/第一轮提示词.txt`
- `paper/notes/README_任务收获与后续改造依据.md`
- `paper/notes/二维可压缩圆柱绕流_你的方法_vs_文献A_B_详细对比.md`

Files removed:
- `AGENTS_updated.md`
- `run.m`
- `paper/S_pages/`

Validation:
- `run(fullfile('run','run_phase2_validation.m'))`
- Result: the validation entry point now works without root-level `run.m` shadowing; all checks passed except the existing `test_matrix_sizes` skip for missing `Part3_Results.mat`.

Next handoff:
- Keep the cleaned root layout stable; do not reintroduce a root-level `run.m`.

Summary:
- Unified the active plot titles, axis labels, and colorbar labels to Chinese across the main Part1/Part2/Part4 workflow plus the current helper plotting scripts.
- Cleared the remaining mixed-language visible terms from plots, including `Legacy4`, `Sutherland`, `Jacobian`, `Christoffel`, `Laplacian`, `Re/Im`, `rad/s`, and `St`.
- Revalidated the plotting paths after the text-only changes.

Files touched:
- `main_double_wedge_part1.m`
- `main_double_wedge_part2.m`
- `main_double_wedge_part4.m`
- `build_boundary_masks.m`
- `src/core/build_boundary_masks.m`
- `src/core/plot_boundary_map.m`
- `src/core/plot_mode_u_bubble_gallery.m`
- `src/core/read_phenglei_baseflow.m`
- `src/core/run_part4_primitive5.m`
- `run/run_legacy4_semi_artificial_viscosity_scan.m`
- `docs/audit.md`
- `docs/coordination/TASK_LOG.md`

Validation:
- `matlab -batch "run(fullfile('run','run_phase2_validation.m'));"`  
  Result: passed, with the existing `test_matrix_sizes` skip for missing root `Part3_Results.mat`.
- `matlab -batch "addpath(fullfile(pwd,'run')); addpath(fullfile(pwd,'src','core')); run_legacy4_semi_artificial_viscosity_scan;"`  
  Result: passed and regenerated `outputs/figs/legacy4_semi_artificial_viscosity_scan.png`.

Next handoff:
- If you add new plotting scripts later, keep titles, axes, colorbars, and legend display names Chinese by default so the repository stays stylistically consistent.

Summary:
- Investigated the reported mismatch between Tecplot `ddx` derivatives and the Part2 `u_x / u_xx` fields.
- Added a curved-grid manufactured-solution validation so the derivative route is now checked on a non-orthogonal, spatially varying mapping instead of only the simpler metric/Jacobian smoke case.
- Confirmed that the shared metric-plus-chain-rule operator path is highly accurate on the manufactured curved-grid case, so the current 20% discrepancy is more likely tied to Tecplot/operator-definition differences, boundary points, shock-adjacent points, or the still-unified-private `Part2` derivative implementation.

Files touched:
- `tests/test_curvilinear_scalar_operators.m`
- `run/run_phase2_validation.m`
- `docs/audit.md`
- `docs/coordination/TASK_LOG.md`

Validation:
- `matlab -batch "run(fullfile('run','run_phase2_validation.m'));"`  
  Result: passed, with the existing `test_matrix_sizes` skip for missing root `Part3_Results.mat`.

Next handoff:
- If this Tecplot comparison remains important, the next best step is to add an audit script that runs a manufactured scalar field on the real PHengLEI mesh from `Part1_Results.mat`, so the actual mesh can be checked independently of the real baseflow and independently of Tecplot.

Summary:
- Fixed the `main_double_wedge_part4` crash caused by an older shadowing `compute_mode_diagnostics.m` that does not accept the newer `'StateLayout'` parameter.
- Added a safe wrapper that detects this stale-helper situation, warns with the resolved file path, and retries only in legacy4-compatible mode.
- Added a regression test that reproduces the exact shadowing scenario with a temporary old helper in the current folder.

Files touched:
- `src/core/safe_compute_mode_diagnostics.m`
- `src/core/rank_mode_candidates.m`
- `run/run_legacy4_semi_artificial_viscosity_scan.m`
- `tests/test_rank_mode_candidates_legacy_compatibility.m`
- `run/run_phase2_validation.m`
- `docs/audit.md`
- `docs/coordination/TASK_LOG.md`

Validation:
- `matlab -batch "run(fullfile('run','run_phase2_validation.m'));"`  
  Result: passed, with the existing `test_matrix_sizes` skip for missing root `Part3_Results.mat`.

Next handoff:
- If the user still sees the warning in a copied/exported workspace, replace or delete the stale `compute_mode_diagnostics.m` reported in the warning so MATLAB stops shadowing the updated helper.

## 2026-04-09 - Local 270x128 test baseflow detection

Summary:
- Confirmed that the repository root now contains `double_wedge_baseflow.dat` as a local PHengLEI Tecplot smoke dataset.
- Verified directly from the Tecplot header that this local file reports `I=270`, `J=128`, `K=1`.
- Verified through `read_phenglei_baseflow.m` that the default modular reader path ingests it without fallback and produces a working grid of `Nx=135`, `Ny=64` under the current stride settings.
- Recorded that this file is only for testing; the final intended physical run still targets `812 x 382`.
- Fixed `src/core/read_phenglei_baseflow.m` so the modular reader now accepts Tecplot files whose `ZONE` metadata and `I/J` dimensions are split across multiple header lines.
- Added a focused regression test for the multi-line `ZONE` header case and wired it into the Phase 2 validation script.

Files touched:
- `README.md`
- `README_codex_handoff.md`
- `docs/coordination/ACTIVE_CONTEXT.md`
- `docs/coordination/TASK_LOG.md`
- `run/run_phase2_validation.m`
- `src/core/read_phenglei_baseflow.m`
- `tests/test_read_phenglei_multiline_zone_header.m`

Validation:
- Header inspection of root `double_wedge_baseflow.dat`: `I=270`, `J=128`, `K=1`
- `test_read_phenglei_multiline_zone_header`
- `run(fullfile('run','run_phase2_validation.m'))`

Next handoff:
- Keep treating `double_wedge_baseflow.dat` as a reader/smoke input only.
- When the final `812 x 382` case arrives, record its path, header dimensions, and whether a matching `boundary_condition.hypara` file is available.

## 2026-04-09 - Real 812x382 screenshot review and wrong-mode assessment

Summary:
- Recorded a user-provided screenshot review from a production-oriented run tied to the intended `812 x 382` double-wedge case.
- Noted the user clarification that this run involved downsampling, but kept downsampling as background context rather than the primary explanation for the wrong result.
- Recorded the selected mode marker as `sigma_r ~= +2.098e-01` with `St ~= 0.0664`.
- Recorded that the clearest reconstructed support is a compact, smooth, isolated packet near `x ~= 56 to 60`, `y ~= 46 to 50`, above the downstream wedge segment, rather than a dominant separation-bubble footprint.
- Assessed the currently selected leading mode as a likely nonphysical interior pseudo-mode branch, not the target separation-bubble global instability.
- Traced the most likely immediate cause to the current ranking logic: `rank_mode_candidates.m` only filters with boundary dominance, checker content, high-frequency content, and `y` centroid information from `compute_mode_diagnostics.m`, so a smooth compact interior mode can still rank well if it is not boundary-dominated.
- Added a reusable follow-up prompt file that tells the next coding pass to strengthen bubble relevance and compact-support rejection instead of chasing reader or downsampling explanations.

Files touched:
- `README_codex_handoff.md`
- `docs/coordination/ACTIVE_CONTEXT.md`
- `docs/coordination/TASK_LOG.md`
- `docs/coordination/WORK_QUEUE.md`
- `docs/prompts/2026-04-09_812x382_mode_selection_followup.md`

Validation:
- Not run. This task records image-based evidence and next-step guidance only; no solver code was changed.

Next handoff:
- Treat the current blocker as a mode-selection credibility problem on the real case.
- First tighten bubble relevance and compact-support diagnostics, then rerun the real case before interpreting any leading unstable branch physically.

## 2026-04-09 - Full-resolution 270x128 test-file legacy4 run

Summary:
- Added `run/run_user_test_baseflow_fullres_legacy4.m` to run the local `double_wedge_baseflow.dat` test file through the legacy Part2 to Part4 chain without any extra downsampling.
- Bridged the modular reader and preprocess output into the legacy `Part1_Results.mat` contract inside an isolated case directory under `outputs/mat/user_test_baseflow_270x128_fullres_legacy4/`.
- Removed the Statistics Toolbox dependency that blocked this path by replacing `prctile(...)` calls in `main_double_wedge_part1.m` and `main_double_wedge_part2.m` with a local toolbox-free percentile helper.
- Completed the full `270 x 128` run successfully with `n_eigs = 20`, `beta = 0`, and the current legacy4 stabilization settings.
- Recorded the leading mode as `sigma_r ~= +2.094271e-01`, `sigma_i ~= +4.707634e-01`, `f_nd ~= 0.074924`, residual `~= 3.00e-15`, and `y_centroid ~= 0.136941`.
- Checked the saved mode figures and found that the leading `u'` support is concentrated near the lower-wall compression region around `x ~= 20 to 26`, `y ~= 13 to 16`, which is spatially different from the upper-layer packet seen in the user-provided `812 x 382` screenshot review.
- Also recorded that this test-file run is still not a trustworthy physics benchmark because preprocessing and Part2 diagnostics are poor on this file under the current interpretation: EOS relative error `~= 4.90e-01`, wall-temperature relative mismatch `~= 2.75`, and continuity-residual max `~= 9.50e+02`.

Files touched:
- `main_double_wedge_part1.m`
- `main_double_wedge_part2.m`
- `run/run_user_test_baseflow_fullres_legacy4.m`
- `docs/coordination/ACTIVE_CONTEXT.md`
- `docs/coordination/TASK_LOG.md`
- `docs/audit.md`

Validation:
- `matlab -batch "addpath(fullfile(pwd,'run')); summary = run_user_test_baseflow_fullres_legacy4();"`
- Result: passed and produced `Part1_Results.mat` through `Part4_Results.mat` under `outputs/mat/user_test_baseflow_270x128_fullres_legacy4/`.

Artifacts:
- `outputs/mat/user_test_baseflow_270x128_fullres_legacy4/Part4_Results.mat`
- `outputs/mat/user_test_baseflow_270x128_fullres_legacy4/run_summary.mat`
- `outputs/mat/user_test_baseflow_270x128_fullres_legacy4/run_summary.txt`
- `outputs/figs/Fig13_EigenvalueSpectrum.png`
- `outputs/figs/Fig18_u_hat.png`
- `outputs/figs/Fig22_Top4Modes.png`

Next handoff:
- Keep using the `270 x 128` run only as an end-to-end smoke or regression case.
- Do not infer real-case physics from this test-file output until the baseflow consistency diagnostics improve substantially.

## 2026-04-10 - Direct primitive-five v5 chain rebuild

Summary:
- Replaced the root `main_double_wedge_part1.m` through `main_double_wedge_part4.m` entry files with clean wrappers that dispatch into new `v5` implementations instead of the previous large inline scripts.
- Added `Main_DoubleWedge_Part1_v5.m` and `Main_DoubleWedge_Part2_v5.m` to rebuild the front half of the chain on top of the shared modular reader, preprocessing, metric, and derivative helpers.
- Added `Main_DoubleWedge_Part3_v5.m` to assemble a direct primitive-five `q = [u'', v'', w'', T'', p'']^T` generalized EVP with density eliminated by the equation of state, shock-localized semi-artificial viscosity, and a restricted top/outlet sponge.
- Added `Main_DoubleWedge_Part4_v5.m` to solve the scaled EVP, apply wall-energy and checker filters, save region-energy diagnostics, and emit primitive-five mode figures and matrix-health metadata.
- Added `Diagnose_MatrixHealth.m`, `src/core/build_restricted_sponge_profile.m`, `src/core/build_shock_localized_sav_matrix.m`, and `src/core/compute_mode_filter_metrics.m` as reusable diagnostics/helpers for the new chain.
- Corrected the primitive-five symmetry BC implementation in `src/core/apply_structured_bc_rows.m` so `w''` now uses a south-edge Neumann row instead of an incorrect Dirichlet row.
- Added `tests/test_mode_filter_metrics.m` and extended `tests/test_bc_rows.m` to cover the new primitive-five symmetry `w''` boundary treatment.
- Completed a reduced-grid smoke run in `outputs/mat/codex_v5_smoke/` through the new `Part4` path.
- On that smoke run, the active-row matrix row-norm ratio dropped from about `4.7e4` before scaling to about `3.7e1` after the new preconditioner.

Files touched:
- `main_double_wedge_part1.m`
- `main_double_wedge_part2.m`
- `main_double_wedge_part3.m`
- `main_double_wedge_part4.m`
- `Main_DoubleWedge_Part1_v5.m`
- `Main_DoubleWedge_Part2_v5.m`
- `Main_DoubleWedge_Part3_v5.m`
- `Main_DoubleWedge_Part4_v5.m`
- `Diagnose_MatrixHealth.m`
- `src/core/apply_structured_bc_rows.m`
- `src/core/build_restricted_sponge_profile.m`
- `src/core/build_shock_localized_sav_matrix.m`
- `src/core/compute_mode_filter_metrics.m`
- `tests/test_bc_rows.m`
- `tests/test_mode_filter_metrics.m`
- `run/run_phase2_validation.m`
- `docs/coordination/ACTIVE_CONTEXT.md`
- `docs/coordination/WORK_QUEUE.md`
- `docs/coordination/TASK_LOG.md`
- `docs/audit.md`

Validation:
- `checkcode('Main_DoubleWedge_Part3_v5.m')`
- `checkcode('Main_DoubleWedge_Part4_v5.m')`
- `test_bc_rows`
- `test_mode_filter_metrics`
- Reduced-grid smoke chain:
  `Main_DoubleWedge_Part1_v5('StrideX',6,'StrideY',6,'NEigs',6)`
  `Main_DoubleWedge_Part2_v5`
  `Main_DoubleWedge_Part3_v5`
  `Diagnose_MatrixHealth('Part3_Results.mat')`
  `Main_DoubleWedge_Part4_v5`

Next handoff:
- Run the new `v5` chain on the intended real case and perform the required `beta` scan.
- Treat the reduced-grid smoke run only as a connectivity and conditioning check, not as a physical validation case.

## 2026-04-10 - Full-resolution 270x128 v5 benchmark run and documentation sync

Summary:
- Added `run/run_user_test_baseflow_fullres_v5.m` to run the local `double_wedge_baseflow.dat` benchmark through the direct primitive-five `v5` chain at full `270 x 128` resolution.
- The new runner saves `Part1_Results.mat` through `Part4_Results.mat`, `Diagnose_MatrixHealth_Report.mat`, `run_summary.mat`, and `run_summary.txt` in an isolated case directory under `outputs/mat/user_test_baseflow_270x128_fullres_v5/`.
- Completed the full benchmark run with `beta = 0`, `n_eigs = 8`, `sigma = 0 + 0.05i`, and `top_type = inlet`.
- Recorded a large conditioning improvement from the Part4 scaling step: active-row row-norm ratio `~1.36e5 -> ~4.34e1`.
- Recorded that the benchmark is still not physically credible: `0 / 8` modes passed the residual filter, the best residual is only `~6.69e-1`, and the reported leading mode remains close to the shift at `sigma ~= 2.276e-4 + 4.991e-2 i`.
- The leading benchmark mode still has high near-wall energy (`wall_energy_frac ~= 0.862`, `free_stream_energy_frac ~= 0.021`, `sponge_energy_frac ~= 6.0e-4`, `checker_ratio ~= 0.755`), so the current blocker is no longer gross free-stream pollution alone; it is now residual credibility of the assembled EVP and Part4 fallback semantics.
- Updated the existing README and coordination files so the new `v5` benchmark runner and its non-credible outcome are explicit for the next handoff.

Files touched:
- `run/run_user_test_baseflow_fullres_v5.m`
- `README.md`
- `README_codex_handoff.md`
- `docs/coordination/ACTIVE_CONTEXT.md`
- `docs/coordination/WORK_QUEUE.md`
- `docs/coordination/TASK_LOG.md`
- `docs/audit.md`

Validation:
- `matlab -batch "addpath(fullfile(pwd,'run')); summary = run_user_test_baseflow_fullres_v5();"`
- `matlab -batch "addpath(fullfile(pwd,'run')); summary = run_user_test_baseflow_fullres_v5('ReuseExistingCase', true);"`

Artifacts:
- `outputs/mat/user_test_baseflow_270x128_fullres_v5/Part4_Results.mat`
- `outputs/mat/user_test_baseflow_270x128_fullres_v5/Diagnose_MatrixHealth_Report.mat`
- `outputs/mat/user_test_baseflow_270x128_fullres_v5/run_summary.mat`
- `outputs/mat/user_test_baseflow_270x128_fullres_v5/run_summary.txt`

Next handoff:
- Fix the `v5` full-resolution residual issue before treating any `270 x 128` or real-case mode as physically meaningful.
- After that, rerun the benchmark and only then move on to the intended real-case `beta` scan.

## 2026-04-10 - Descriptor-residual fix and publication-aware v5 ranking

Summary:
- Fixed the core `Part4_v5` residual bug by switching the eigensolve from the reduced active-row-only pencil to the full scaled descriptor pencil, so `Gamma = 0` algebraic boundary columns are no longer silently deleted.
- Added explicit residual splits (`total`, `active`, `algebraic`, `scaled`) and a strict filter summary so the benchmark now reports whether a mode is actually residual-clean instead of hiding the issue behind fallback selection.
- Added `src/core/build_filter_selection_summary.m` and `src/core/evaluate_mode_validity_tags.m`, then reused the validity tags to rank publication-gate-passing modes ahead of compact-support pseudo-modes in `Part4_v5`.
- Re-ran the full `270 x 128` v5 benchmark `Part4` solve after these fixes.
- The updated benchmark leading mode is now `sigma ~= +2.824e-06 + 4.996e-02 i` with total residual `~= 1.77e-08`, algebraic contribution `~= 1.77e-15`, wall-energy fraction `~= 0.962`, checker ratio `~= 0.082`, and `publication_allowed = true` under the current strict gates.
- This removes the previous “all modes are non-credible because residuals are O(1)” blocker, but it still does not turn the local `270 x 128` file into a physics-grade benchmark because the baseflow diagnostics remain weak.

Files touched:
- `Main_DoubleWedge_Part4_v5.m`
- `run/run_user_test_baseflow_fullres_v5.m`
- `src/core/build_filter_selection_summary.m`
- `src/core/evaluate_mode_validity_tags.m`
- `src/core/build_mode_validity_report.m`
- `tests/test_filter_selection_summary.m`
- `tests/test_mode_validity_report.m`
- `run/run_phase2_validation.m`
- `README_codex_handoff.md`
- `docs/coordination/ACTIVE_CONTEXT.md`
- `docs/coordination/WORK_QUEUE.md`
- `docs/coordination/TASK_LOG.md`
- `docs/audit.md`

Validation:
- `matlab -batch "addpath(fullfile(pwd,'src','core')); addpath(fullfile(pwd,'tests')); test_filter_selection_summary; test_mode_validity_report;"`
- `matlab -batch "addpath(pwd); addpath(fullfile(pwd,'run')); addpath(fullfile(pwd,'src','core')); cd(fullfile('outputs','mat','user_test_baseflow_270x128_fullres_v5')); Main_DoubleWedge_Part4_v5('FigureDirectory', fullfile(pwd,'figs'));"`  (run twice during debugging, final result kept)
- `matlab -batch "addpath(fullfile(pwd,'run')); summary = run_user_test_baseflow_fullres_v5('ReuseExistingCase', true);"`

Artifacts:
- `outputs/mat/user_test_baseflow_270x128_fullres_v5/Part4_Results.mat`
- `outputs/mat/user_test_baseflow_270x128_fullres_v5/run_summary.txt`

Next handoff:
- Inspect the updated leading-mode field plots and decide whether this benchmark is now good enough for a small `beta` trend scan.
- Keep the weak local baseflow diagnostics in mind before drawing any physical conclusion from the new clean residuals.

## 2026-04-10 - No-sponge inlet-boundary audit pass

Summary:
- The user clarified that the active double-wedge case has no top farfield boundary: the correct boundary set is top=`inlet`, south-upstream=`symmetry`, south-downstream=`wall`, east=`outlet`.
- Reverted the mistaken temporary `top_type = farfield` assumption and set the active modular defaults back to `top_type = inlet`.
- Disabled sponge damping by default on the `v5` path for this audit pass (`Main_DoubleWedge_Part1_v5`, `Main_DoubleWedge_Part3_v5`, and `run/run_user_test_baseflow_fullres_v5.m`).
- Fixed a real diagnostic bug in `compute_mode_diagnostics.m` and `build_mode_reference_masks.m`: wall distance and upper/lower-layer masks are now computed relative to the local south-edge wall position in each column instead of from the global `Y` range.
- Added a regression extension in `tests/test_mode_diagnostics.m` to protect that downstream wall-distance interpretation on a tilted wall.
- Ran a fresh full `270 x 128` benchmark under the user-confirmed `top=inlet`, `UseSponge=false` configuration in `outputs/mat/user_test_baseflow_270x128_fullres_v5_nosponge_inlet/`.
- The updated leading mode is `sigma ~= +3.109e-05 + 4.996e-02 i` with total residual `~= 5.74e-08`, algebraic residual `~= 2.12e-15`, wall-energy fraction `~= 0.888`, free-stream fraction `~= 0.0797`, checker ratio `~= 0.197`, and zero sponge energy.
- Quantitatively the leading `u'` peak is now wall-attached (`j=8`, wall distance `~= 0.0262`), and the near-wall-band `u'` maximum is about `4.22e-2` versus about `9.45e-3` in the upper-layer band. The remaining mismatch is that the original-style smoothed top-4 gallery still visually emphasizes upper weak stripes.

Files touched:
- `Main_DoubleWedge_Part1_v5.m`
- `Main_DoubleWedge_Part3_v5.m`
- `run/config_case.m`
- `run/run_user_test_baseflow_fullres_v5.m`
- `src/core/build_mode_reference_masks.m`
- `src/core/compute_mode_diagnostics.m`
- `tests/test_mode_diagnostics.m`
- `README_codex_handoff.md`
- `docs/coordination/ACTIVE_CONTEXT.md`
- `docs/coordination/WORK_QUEUE.md`
- `docs/coordination/TASK_LOG.md`
- `docs/audit.md`

Validation:
- `matlab -batch "addpath(fullfile(pwd,'src','core')); addpath(fullfile(pwd,'tests')); test_mode_diagnostics; test_filter_selection_summary; test_mode_validity_report;"`
- `matlab -batch "addpath(fullfile(pwd,'run')); summary = run_user_test_baseflow_fullres_v5('CaseName','user_test_baseflow_270x128_fullres_v5_nosponge_inlet','TopType','inlet','UseSponge',false,'ReuseExistingCase',false);"`

Artifacts:
- `outputs/mat/user_test_baseflow_270x128_fullres_v5_nosponge_inlet/Part4_Results.mat`
- `outputs/mat/user_test_baseflow_270x128_fullres_v5_nosponge_inlet/run_summary.txt`
- `outputs/mat/user_test_baseflow_270x128_fullres_v5_nosponge_inlet/figs/Fig22_Top4Modes.png`

Next handoff:
- Audit the original-style smoothed plotting normalization against the raw wall-attached `u'` field before using the gallery as the main physical judgment tool.
- Keep sponge off while the operator/plotting audit continues.

## 2026-04-10 - Claude-style shock-mode suppression pass on the v5 chain

Summary:
- Implemented the user-requested shock-focused repair on the active `v5` path instead of only adjusting plots.
- `Main_DoubleWedge_Part3_v5.m` now detects a dilated shock band from `|grad rho|`, excludes the near-wall 10 percent strip from that mask, clips second-derivative baseflow spikes against non-shock 99.5th-percentile levels, recomputes `mu_x` and `mu_y` from the clipped `dMU_dT`, removes all remaining `d2MU_dT2` couplings from the primitive-five momentum and energy rows, and keeps sponge defaults at zero.
- The semi-artificial-viscosity defaults were raised to `epsilon = 0.05`, `shock_percentile = 85`, `dilation_steps = 5`, and remain localized to the shock band through the existing fourth-difference SAV matrix path.
- `Main_DoubleWedge_Part4_v5.m` now uses the lower-frequency shift `sigma = 0.05 + 0.02i`, larger Krylov subspace settings, whole-vector near-wall energy fractions, `|u'|`-based checker ratios, relaxed wall/checker fallback logic, shock-energy bookkeeping, and an extra `Fig_ModeDiagnosis.png` overlay with the saved shock mask.
- The leading-field plots and the new wall-relative near-wall diagnostics are now energy-normalized. `write_wall_relative_mode_figures.m` was updated accordingly and no longer depends on `turbo`.
- `run/run_user_test_baseflow_fullres_v5.m` and `Main_DoubleWedge_Part1_v5.m` defaults were updated to the new no-sponge, `n_eigs = 50`, `sigma = 0.05 + 0.02i` benchmark settings.
- Re-ran the full `270 x 128` case in `outputs/mat/user_test_baseflow_270x128_fullres_v5_claude_fix/`.
- On that run the leading mode is `sigma ~= +8.063e-02 + 1.285e-02 i` with residual `~= 3.77e-09`, wall-energy fraction `~= 0.972`, free-stream fraction `~= 1.35e-4`, shock-energy fraction `~= 0.193`, checker ratio `~= 0.276`, and a shock/nonshock row-max ratio in `Part3` of only `~= 0.105`.
- The first six frequencies are now all different (`0.002046, 0.000693, 0.003458, 0.004578, 0.006240, 0.001631`), so the old fully degenerate `St = 0.0080` shock-mode pack is no longer the selected branch on this local benchmark.
- Remaining limitation: the current compact-support validity gate still rejects the new leading mode (`publication_allowed = false`), and the local benchmark baseflow remains diagnostically weak (`eos_relative_error ~= 2.60e+01`, `continuity_residual_max ~= 1.10e+02`).

Files touched:
- `Main_DoubleWedge_Part1_v5.m`
- `Main_DoubleWedge_Part3_v5.m`
- `Main_DoubleWedge_Part4_v5.m`
- `run/run_user_test_baseflow_fullres_v5.m`
- `src/core/build_shock_localized_sav_matrix.m`
- `src/core/compute_mode_filter_metrics.m`
- `src/core/write_wall_relative_mode_figures.m`
- `tests/test_mode_filter_metrics.m`
- `README_codex_handoff.md`
- `docs/coordination/ACTIVE_CONTEXT.md`
- `docs/coordination/WORK_QUEUE.md`
- `docs/coordination/TASK_LOG.md`
- `docs/audit.md`

Validation:
- `matlab -batch "addpath(fullfile(pwd,'tests')); test_mode_filter_metrics; test_filter_selection_summary; test_mode_validity_report;"`
- `matlab -batch "addpath(fullfile(pwd,'run')); summary = run_user_test_baseflow_fullres_v5('CaseName','user_test_baseflow_270x128_fullres_v5_claude_fix','TopType','inlet','UseSponge',false,'ReuseExistingCase',false);"`

Artifacts:
- `outputs/mat/user_test_baseflow_270x128_fullres_v5_claude_fix/Part3_Results.mat`
- `outputs/mat/user_test_baseflow_270x128_fullres_v5_claude_fix/Part4_Results.mat`
- `outputs/mat/user_test_baseflow_270x128_fullres_v5_claude_fix/run_summary.txt`
- `outputs/mat/user_test_baseflow_270x128_fullres_v5_claude_fix/figs/Fig22_Top4Modes.png`
- `outputs/mat/user_test_baseflow_270x128_fullres_v5_claude_fix/figs/Fig23_LeadModeNearWallWallRelative.png`
- `outputs/mat/user_test_baseflow_270x128_fullres_v5_claude_fix/figs/Fig24_Top4ModesNearWallWallRelative.png`

Next handoff:
- Decide whether `publication_allowed = false` is now a filter-design problem instead of an operator problem.
- If yes, relax the compact-support gate and run the small `beta` sweep on the same local file.

## 2026-04-10 - Paper-A v6 production-chain refactor and legacy pruning

Summary:
- Promoted the repository to a single Paper-A production path by moving the root wrappers onto `Main_DoubleWedge_Part*_v6.m`.
- Added shared `BaseflowPhysicsAudit`, `GeometryAudit`, and `BaseflowMasks` outputs in the front half of the chain, then carried those through `Part3_v6` and `Part4_v6`.
- Rebuilt `Part4_v6` around the full scaled descriptor pencil, low-frequency `sigma_triplet`, bubble-first phase anchoring, bubble/near-wall/shock-aware ranking, and the reference result figure contract (`Fig13`, `Fig18`, `Fig19`, `Fig22`).
- Added `solve_paperA_descriptor_modes.m`, `build_paperA_mode_masks.m`, `rank_paperA_modes.m`, `write_paperA_reference_figures.m`, `run/run_paperA_validation_suite.m`, `tests/test_paperA_mode_masks.m`, and `tests/test_paperA_phase_anchor.m`.
- Deleted the runnable legacy4 production chain, the old primitive5 transition chain, wall-relative plotting modules, and the legacy-only tests and runners.
- Updated `validate_config.m` and the remaining tests/defaults to the new primitive-five, top=`inlet`, no-sponge Paper-A defaults.
- Ran the retained unit-test subset successfully and completed a `270 x 128` structural smoke case under `outputs/mat/codex_v6_smoke_270x128/`.

Files touched:
- `Main_DoubleWedge_Part1_v6.m`
- `Main_DoubleWedge_Part2_v6.m`
- `Main_DoubleWedge_Part3_v6.m`
- `Main_DoubleWedge_Part4_v6.m`
- `run/run_user_test_baseflow_fullres_v6.m`
- `run/run_phase2_validation.m`
- `run/run_paperA_validation_suite.m`
- `src/core/build_paperA_baseflow_context.m`
- `src/core/build_paperA_mode_masks.m`
- `src/core/solve_paperA_descriptor_modes.m`
- `src/core/rank_paperA_modes.m`
- `src/core/write_paperA_reference_figures.m`
- `src/core/compute_mode_filter_metrics.m`
- `src/core/choose_mode_phase_factor.m`
- `src/core/validate_config.m`
- `src/core/apply_structured_bc_rows.m`
- `src/core/build_semi_artificial_viscosity_matrix.m`
- `src/core/compute_mode_diagnostics.m`
- `src/core/get_state_layout_info.m`
- `Diagnose_MatrixHealth.m`
- `README.md`
- `README_codex_handoff.md`
- `docs/coordination/ACTIVE_CONTEXT.md`
- `docs/coordination/WORK_QUEUE.md`
- `docs/coordination/TASK_LOG.md`

Validation:
- `matlab -batch "addpath(fullfile(pwd,'run')); run_phase2_validation;"`
- `matlab -batch "addpath(pwd); addpath(fullfile(pwd,'run')); addpath(fullfile(pwd,'src','core')); cd(fullfile('outputs','mat','codex_v6_smoke_270x128')); Main_DoubleWedge_Part4_v6('FigureDirectory', fullfile(pwd,'figs'));"`
- `matlab -batch "addpath(fullfile(pwd,'run')); summary = run_user_test_baseflow_fullres_v6('CaseName','codex_v6_smoke_270x128','ReuseExistingCase',true);"`

Artifacts:
- `outputs/mat/codex_v6_smoke_270x128/Part4_Results.mat`
- `outputs/mat/codex_v6_smoke_270x128/run_summary.txt`
- `outputs/mat/codex_v6_smoke_270x128/figs/Fig13_EigenvalueSpectrum.png`
- `outputs/mat/codex_v6_smoke_270x128/figs/Fig18_LeadingModeNormalizationAudit.png`
- `outputs/mat/codex_v6_smoke_270x128/figs/Fig19_LeadingModeUVBubbleStreamlines.png`
- `outputs/mat/codex_v6_smoke_270x128/figs/Fig22_Top4Modes.png`

Next handoff:
- Run the default `n_eigs = 50` `v6` benchmark on the local `270 x 128` file.
- Start the `beta = [0, 1, 2, 4, 8]` no-sponge `v6` sweep once that benchmark is stable.

Addendum:
- Ran the default `n_eigs = 50` benchmark in `outputs/mat/paperA_validation_270x128_v6/`.
- Latest leading mode: `sigma ~= -7.343e-05 + 2.036e-02 i`, residual `~= 2.47e-08`, bubble overlap `~= 0.039`, near-wall energy `~= 0.865`, free-stream energy `~= 0.109`, shock energy `~= 0.693`, checker ratio `~= 0.049`, `publication_allowed = 0`.
- The new reference figures are no longer blank, but this default benchmark leader is still shock-dominated and should not be treated as the correct physical separation-bubble mode.

## 2026-04-14 - Headerless real-case baseflow reader support

Summary:
- Investigated the user's `run_user_test_baseflow_fullres_v6` failure on a headerless `812 x 382` PHengLEI export where `read_phenglei_baseflow` fell back to the default `11` columns and raised `The Tecplot data length is not divisible by 11 columns.`
- Updated `src/core/read_phenglei_baseflow.m` so headerless imports can infer the true column count from `I * J` when `cfg.reader.expected_dims` is provided, instead of blindly assuming `cfg.reader.n_expected_vars`.
- Kept the import contract conservative: the reader still requires at least the first 11 fields (`x, y, z, rho, u, v, w, p, T, mach, cp`), but now tolerates extra trailing columns such as a twelfth `gamma/gama`-style field.
- Updated `Main_DoubleWedge_Part1_v6.m` so `Config.Nvar` records the actual imported column count rather than the default fallback guess.
- Added `tests/test_read_phenglei_headerless_infer_num_vars.m` and wired it into `run/run_phase2_validation.m`.

Files touched:
- `src/core/read_phenglei_baseflow.m`
- `Main_DoubleWedge_Part1_v6.m`
- `tests/test_read_phenglei_headerless_infer_num_vars.m`
- `run/run_phase2_validation.m`
- `docs/coordination/ACTIVE_CONTEXT.md`
- `docs/coordination/TASK_LOG.md`
- `docs/audit.md`

Validation:
- `matlab -batch "addpath(fullfile(pwd,'run')); addpath(fullfile(pwd,'tests')); test_read_phenglei_multiline_zone_header; test_read_phenglei_headerless_infer_num_vars;"`
- `matlab -batch "addpath(fullfile(pwd,'run')); run_phase2_validation;"`

Notes:
- `run_phase2_validation` still shows the pre-existing `test_matrix_sizes` skip for the missing root `Part3_Results.mat`; this is unrelated to the reader fix.

Addendum:
- Added `run/run_baseflow_import_audit_v6.m` as a lightweight pre-`Part2` import audit for real-case PHengLEI files.
- The new helper reports raw and working dimensions, inferred column count, extra trailing columns, `eos_relative_error`, `eos_relative_error` percentile stats, and the ratio `p / (rho*T/(gamma*Ma^2))`.
- Updated `Main_DoubleWedge_Part2_v6.m` so the real-case EOS gate now points users toward `run_baseflow_import_audit_v6(...)` instead of failing with no next-step hint.
- Smoke-checked the new helper on the bundled `270 x 128` test file. That run confirmed an important nuance: the max-based EOS metric can be dominated by a few outlier points even when the bulk pressure-ratio statistics remain close to the expected relation.

## 2026-04-14 - Low-memory descriptor-solve fallback for real-case runs

Summary:
- Investigated a real-case `Part4_v6` failure where `solve_paperA_descriptor_modes` reported shift-level `内存不足` and then stopped with `No finite eigenpairs were produced by the descriptor solve.`
- Exposed optional Krylov controls in `Main_DoubleWedge_Part1_v6.m` and `run/run_user_test_baseflow_fullres_v6.m` so users can now set `KrylovDimensionFloor` and `KrylovDimensionCap` directly from the runner.
- Reworked `src/core/solve_paperA_descriptor_modes.m` so each shift now tries a sequence of progressively smaller `eigs` subspaces instead of failing permanently on the first out-of-memory attempt.
- Added solver audit fields for the Krylov candidate list and per-shift attempts, and improved the final no-eigenpair error so it reports the tried `p` values.
- Verified that the retained validation suite still passes and that a reduced-grid low-memory runner smoke case can complete with a capped Krylov dimension.

Files touched:
- `Main_DoubleWedge_Part1_v6.m`
- `run/run_user_test_baseflow_fullres_v6.m`
- `src/core/solve_paperA_descriptor_modes.m`
- `docs/coordination/ACTIVE_CONTEXT.md`
- `docs/coordination/TASK_LOG.md`
- `docs/audit.md`

Validation:
- `matlab -batch "addpath(fullfile(pwd,'run')); run_phase2_validation;"`
- `matlab -batch "addpath(fullfile(pwd,'run')); summary = run_user_test_baseflow_fullres_v6('BaseflowFile',fullfile(pwd,'double_wedge_baseflow.dat'),'ExpectedDims',[270,128],'StrideX',6,'StrideY',6,'NEigs',6,'SigmaShift',0.05+0.02i,'SigmaTriplet',0.05+0.02i,'KrylovDimensionFloor',24,'KrylovDimensionCap',36,'CaseName','lowmem_runner_smoke');"`

Notes:
- The low-memory smoke case completed with working grid `45 x 22` and Krylov dimension `36`.
- This change does not make the full `812 x 382` solve cheap; it only prevents the current solver from insisting on an unnecessarily large `eigs` subspace before giving the user any fallback.

## 2026-04-16 - Part3 pressure-row regularization and independent shock-source switch

Summary:
- Separated the two shock-stabilization mechanisms that had previously been conflated in user-side comparisons: `Kav` is still controlled by `use_semi_artificial_viscosity`, while the derivative/source clipping path in `Part3_v6` is now controlled independently by a new top-level `use_shock_source_regularization` switch.
- Added a dedicated `pressure_row_regularization` config block to `Part1_v6` and `validate_config.m` so the weighted pressure-row coefficients entering `LPu`, `LPv`, and `LPP` can be clipped or explicitly suppressed in shock zones without having to rewrite the rest of the primitive-five closure.
- Added `src/core/build_paperA_pressure_row_regularization_v6.m` and now save `PressureRowAudit` into `Part3_Results.mat` alongside the existing `BetaAssemblyAudit` and `PressureClosureAudit`.
- Extended the retained validation subset with `test_paperA_pressure_row_regularization_v6` and updated the existing `Part3` smoke case so the new audit field is exercised without invoking a full `Part4_v6` eigensolve.

Files touched:
- `Main_DoubleWedge_Part1_v6.m`
- `Main_DoubleWedge_Part3_v6.m`
- `src/core/validate_config.m`
- `src/core/build_paperA_pressure_row_regularization_v6.m`
- `tests/test_config_fields.m`
- `tests/test_paperA_pressure_row_regularization_v6.m`
- `tests/test_part3_beta_audit_smoke.m`
- `run/run_phase2_validation.m`
- `docs/coordination/ACTIVE_CONTEXT.md`
- `docs/coordination/WORK_QUEUE.md`
- `docs/coordination/TASK_LOG.md`
- `docs/audit.md`

Validation:
- `matlab -batch "addpath(fullfile(pwd,'run')); addpath(fullfile(pwd,'src','core')); addpath(fullfile(pwd,'tests')); test_config_fields; test_paperA_pressure_closure_audit_v6; test_paperA_pressure_row_regularization_v6; test_part3_beta_audit_smoke; disp('targeted_tests_ok');"`
- `matlab -batch "addpath(fullfile(pwd,'run')); run_phase2_validation; disp('phase2_validation_ok');"`

Notes:
- The current pressure-row regularization is intentionally mild by default: it clips the shock-zone weighted coefficients against non-shock statistics and records per-field counts; it does not zero the whole shock band unless the new config flags explicitly request that.
- `run_phase2_validation` still shows the pre-existing `test_matrix_sizes` skip for the missing external root `Part3_Results.mat`; this remains unrelated to the new `Part3_v6` change.

## 2026-04-16 - Configurable v6 runner and editable manual sweep script

Summary:
- Upgraded `run/run_user_test_baseflow_fullres_v6.m` from a mostly fixed benchmark wrapper into a configurable user-side runner. It now supports `RunPart4`, `Part3Variant`, and explicit overrides for `use_semi_artificial_viscosity`, `use_shock_source_regularization`, and `pressure_row_regularization`.
- Added `run/run_global_stability_case_v6.m` as an editable script with a top-of-file parameter block so user-side scans can be launched by directly changing case settings instead of reconstructing a long name-value call each time.
- Kept the production default unchanged: `main_double_wedge_part3.m` still points to `Main_DoubleWedge_Part3_v6.m`, while the archived `Main_DoubleWedge_Part3_v6_pre_pressure_fix_20260414.m` is now exposed only as an explicit comparison option through `Part3Variant`.
- Added a lightweight runner smoke test `test_run_user_test_baseflow_part3_only_v6` that stops after `Part3` on a very coarse import of the bundled benchmark file and confirms that the new config overrides and summary export work without invoking `Part4`.

Files touched:
- `run/run_user_test_baseflow_fullres_v6.m`
- `run/run_global_stability_case_v6.m`
- `tests/test_run_user_test_baseflow_part3_only_v6.m`
- `run/run_phase2_validation.m`
- `docs/coordination/ACTIVE_CONTEXT.md`
- `docs/coordination/WORK_QUEUE.md`
- `docs/coordination/TASK_LOG.md`
- `docs/audit.md`

Validation:
- `matlab -batch "checkcode('run/run_user_test_baseflow_fullres_v6.m'); checkcode('run/run_global_stability_case_v6.m'); checkcode('tests/test_run_user_test_baseflow_part3_only_v6.m'); disp('runner_syntax_ok');"`
- `matlab -batch "addpath(fullfile(pwd,'run')); addpath(fullfile(pwd,'tests')); addpath(fullfile(pwd,'src','core')); test_run_user_test_baseflow_part3_only_v6; disp('runner_smoke_ok');"`
- `matlab -batch "addpath(fullfile(pwd,'run')); run_phase2_validation; disp('phase2_with_runner_ok');"`

Notes:
- MATLAB resolves this repository through a mirrored path under `C:\Users\寒橘柚\Downloads\double_wedgeold` in the current desktop setup, but file hashes match the `C:\Users\UserX\Downloads\double_wedgeold` workspace copy. The new runner validation therefore exercised the same content that was edited in this task.

Addendum:
- Added `run/run_sigma_shift_scan_v6.m` as a reusable sigma-shift scan helper.
- Updated `run/run_global_stability_case_v6.m` so a non-empty `sigma_shift_list` switches the manual script from one-shot mode into scan mode.
- Added `test_run_sigma_shift_scan_part3_only_v6.m` and confirmed that a two-shift coarse `Part3`-only scan builds per-shift case folders plus one aggregated `sigma_shift_scan_summary.mat/.txt`.

## 2026-04-16 - ReuseExistingCase provenance hardening for the configurable v6 runner

Summary:
- Continued the full-code review on the new configurable runner and found a high-severity provenance bug: `ReuseExistingCase=true` reused old MAT files but still wrote `expected_dims`, `stride`, `top_type`, and `Part3Variant` in the summary from the current call arguments rather than from the saved case.
- Fixed that path by introducing explicit case-identity metadata in `RunnerCaseMetadata.mat`. Fresh runs now save the immutable identity of the case, and reuse runs now load that metadata instead of trusting the current call arguments.
- Added a hard reuse gate: if the current request does not match the saved baseflow path, grid/stride, top boundary, effective Part1 overrides, or archived-vs-current `Part3Variant`, the runner now throws `run_user_test_baseflow_fullres_v6:ReuseMismatch` instead of silently mislabeling the case.
- Added `tests/test_run_user_test_reuse_case_provenance_v6.m` to cover both the clean reuse path and the mismatch-rejection path, then wired that test into `run_phase2_validation`.

Files touched:
- `run/run_user_test_baseflow_fullres_v6.m`
- `tests/test_run_user_test_reuse_case_provenance_v6.m`
- `run/run_phase2_validation.m`
- `docs/coordination/ACTIVE_CONTEXT.md`
- `docs/coordination/WORK_QUEUE.md`
- `docs/coordination/TASK_LOG.md`
- `docs/audit.md`

Validation:
- `matlab -batch "checkcode('run/run_user_test_baseflow_fullres_v6.m'); checkcode('tests/test_run_user_test_reuse_case_provenance_v6.m'); checkcode('run/run_phase2_validation.m');"`
- `matlab -batch "addpath(fullfile(pwd,'run')); addpath(fullfile(pwd,'tests')); addpath(fullfile(pwd,'src','core')); test_run_user_test_baseflow_part3_only_v6; test_run_user_test_reuse_case_provenance_v6;"`
- `matlab -batch "addpath(fullfile(pwd,'run')); run_phase2_validation;"`

Notes:
- This batch intentionally did not touch sponge support. The runner still exposes `UseSponge`, but sponge parameter plumbing remains a separate follow-up item.

## 2026-04-16 - Copy-ready transfer bundle for another computer

Summary:
- Created a dedicated transfer folder at `outputs/transfer/double_wedge_812x382_portable_20260416/` so the user can copy one self-contained directory to another computer for `812 x 382` double-wedge global-stability runs.
- Kept the folder repo-relative so `setup_double_wedge_paths.m` still works unchanged after the copy. The bundle includes the root solver entry files, `run/`, `src/`, `tests/`, `docs/`, `paper/`, the benchmark `double_wedge_baseflow.dat`, and a new migration note `TRANSFER_README_812x382.md`.
- Intentionally left out historical `outputs/` artefacts and the unrelated `cone_code/` branch so the transfer package stays smaller and focused on the active production path.
- Updated the repo `AGENTS.md` so future cross-machine handoffs explicitly require generating one dedicated transfer folder instead of leaving the file selection implicit.

Files touched:
- `AGENTS.md`
- `outputs/transfer/double_wedge_812x382_portable_20260416/`
- `docs/coordination/ACTIVE_CONTEXT.md`
- `docs/coordination/WORK_QUEUE.md`
- `docs/coordination/TASK_LOG.md`
- `docs/audit.md`

Validation:
- Verified the transfer folder contains the expected top-level solver files plus `run/`, `src/`, `tests/`, `docs/`, and `paper/`.
- Added a dedicated `TRANSFER_README_812x382.md` with new-machine setup and run instructions.
- Ran `run_phase2_validation` from inside the transfer bundle root to confirm it behaves as a standalone project copy, then removed the temporary package-local `outputs/` created during that self-check.

Notes:
- The real user-side `812 x 382` baseflow file is still external and must be copied into or referenced from the transfer bundle on the target computer.

## 2026-04-16 - Documentation cleanup and obsolete plan/log removal

Summary:
- Reorganized the non-code documents by type so the repo root no longer mixes active code with background analysis and expired iterative notes.
- Moved the long-lived background materials `investigation_report.md` and `literature_shock_pollution_survey.md` into the new `docs/background/` folder and added `docs/background/README.md` to define what belongs there.
- Deleted obsolete iterative documents that had already been absorbed by `docs/audit.md` and `docs/coordination/`: `docs/DEBUG_REPORT.md`, `docs/FIX_LOG.md`, `docs/PLAN.md`, `full_code_check_and_fix_plan.md`, and `root_cause_fix_plan.md`.
- Updated `AGENTS.md`, `docs/coordination/README.md`, `docs/PROJECT_STRUCTURE.md`, and `README_codex_handoff.md` so the cleaned document layout is now the documented default instead of a one-off cleanup.
- Cleaned the transfer bundle at `outputs/transfer/double_wedge_812x382_portable_20260416/` as well, including removal of the accidental nested `docs/docs/` duplicate folder.

Files touched:
- `AGENTS.md`
- `README_codex_handoff.md`
- `docs/background/README.md`
- `docs/background/investigation_report.md`
- `docs/background/literature_shock_pollution_survey.md`
- `docs/coordination/ACTIVE_CONTEXT.md`
- `docs/coordination/README.md`
- `docs/coordination/TASK_LOG.md`
- `docs/PROJECT_STRUCTURE.md`
- `docs/audit.md`
- `outputs/transfer/double_wedge_812x382_portable_20260416/`

Validation:
- Verified the root directory now contains only solver entry files, repo metadata, and major top-level READMEs.
- Verified `docs/` now groups files by purpose as `background/`, `coordination/`, and `prompts/`.
- Verified the transfer bundle no longer contains the accidental `docs/docs/` duplication.

Notes:
- Historical references to the deleted temporary plan files remain in older append-only task-log lines as part of the historical record, but the active document entry points no longer depend on those files.

## 2026-04-16 - Fix TeX label crash in Part2 derivative figure export

Summary:
- A user-side `812 x 382` run got past the temporarily bypassed real-case continuity gate and then failed inside `write_baseflow_derivative_figures.m` during `saveas/print`.
- The immediate cause was invalid TeX-style axis labels written as `x^*` and `y^*`, which MATLAB's text interpreter rejects when exporting figures.
- Fixed the labels in `src/core/write_baseflow_derivative_figures.m` to the valid form `x^{*}` and `y^{*}` while keeping the intended notation.
- Ran one focused smoke check that calls the derivative-figure writer directly and confirmed that the figure now saves successfully.

Files touched:
- `src/core/write_baseflow_derivative_figures.m`
- `docs/coordination/TASK_LOG.md`
- `docs/audit.md`
- `outputs/transfer/double_wedge_812x382_portable_20260416/src/core/write_baseflow_derivative_figures.m`

Validation:
- `matlab -batch "checkcode('src/core/write_baseflow_derivative_figures.m');"`
- `matlab -batch "addpath(fullfile(pwd,'src','core')); [X,Y]=meshgrid(linspace(0,1,8),linspace(0,1,6)); dX=struct('ux',sin(X).*cos(Y),'uxx',cos(X).*sin(Y)); outdir=fullfile(pwd,'outputs','figs','tmp_derivative_label_smoke'); if exist(outdir,'dir')==7, rmdir(outdir,'s'); end; audit=write_baseflow_derivative_figures(outdir,X,Y,zeros(size(X)),dX); assert(exist(audit.output_files{1},'file')==2);"`

Notes:
- This fix only removes the figure-export crash. It does not change the separate `812 x 382` real-case continuity hard-stop logic in `Part2_v6`.

## 2026-04-16 - Replace the real-case Part2 continuity hard-stop with a compressible mass-continuity audit

Summary:
- A user-side `812 x 382` run showed that the old `Part2_v6` real-case hard-stop still failed even after changing from `stride=3` to `stride=1`, which confirmed that the gate was not merely a downsampling artifact.
- Rechecked the code path and confirmed that the old hard-stop was using `dX.div = ux + vy` as `continuity_residual_max`, even though this is only a divergence proxy and not the correct compressible steady mass-continuity residual.
- Updated `src/core/build_paperA_baseflow_context.m` so the shared audit now records both `divergence_proxy_max` and a normalized compressible mass-continuity metric based on `u*rhox + v*rhoy + rho*(ux+vy)`.
- Updated `Main_DoubleWedge_Part2_v6.m` so the 812x382 real-case path no longer aborts on `ux+vy`; the divergence proxy is now warning-only, and the new normalized mass-continuity audit is saved into `Part2Diagnostics` and warned on when elevated.
- Added `tests/test_part2_mass_continuity_audit.m` to lock in the new intended behavior on a manufactured field with nonzero `ux+vy` but exact compressible mass continuity.

Files touched:
- `Main_DoubleWedge_Part2_v6.m`
- `src/core/build_paperA_baseflow_context.m`
- `tests/test_part2_mass_continuity_audit.m`
- `run/run_phase2_validation.m`
- `docs/coordination/ACTIVE_CONTEXT.md`
- `docs/coordination/WORK_QUEUE.md`
- `docs/coordination/TASK_LOG.md`
- `docs/audit.md`

Validation:
- `matlab -batch "cd('C:/Users/UserX/Downloads/double_wedgeold'); addpath(pwd); addpath(fullfile(pwd,'run')); addpath(fullfile(pwd,'src','core')); addpath(fullfile(pwd,'tests')); test_part2_mass_continuity_audit; test_run_user_test_baseflow_part3_only_v6;"`
- `matlab -batch "cd('C:/Users/UserX/Downloads/double_wedgeold'); addpath(pwd); addpath(fullfile(pwd,'run')); run_phase2_validation;"`

Notes:
- This change removes a physically misleading blocker from the real-case import path, but it does not by itself validate the resulting spectrum. User-side `812 x 382` runs should still inspect the saved `Part2Diagnostics` and downstream `Part3` audits before trusting any mode physically.

## 2026-04-16 - Harden Part4 reference-figure text objects against MATLAB interpreter errors

Summary:
- A user-side `old3` run reached `Part4_v6` but then failed inside `write_paperA_reference_figures.m` during `saveas/print`.
- The immediate symptoms were interpreter-syntax errors on the eigenspectrum titles and axis labels, followed by the same class of issue on `sigma_r / sigma_i` labels and figure titles.
- Rewrote `src/core/write_paperA_reference_figures.m` into a clean ASCII-safe version of the same helper so the reference-figure contract stays the same but text objects no longer depend on fragile encoded strings or ambiguous default interpreters.
- The eigenspectrum titles now use plain ASCII with `Interpreter='none'`, mode labels use `Lead`/`#k` with `Interpreter='none'`, and the shared field plot helper now uses `x^{*}` / `y^{*}` plus `Interpreter='none'` for subplot titles.
- Per the user's request, no expensive `Part4` solve was rerun after this patch; validation was limited to static MATLAB analysis.

Files touched:
- `src/core/write_paperA_reference_figures.m`
- `docs/coordination/TASK_LOG.md`
- `docs/audit.md`

Validation:
- `matlab -batch "cd('C:/Users/UserX/Downloads/double_wedgeold'); checkcode('src/core/write_paperA_reference_figures.m');"`

Notes:
- This patch only addresses the MATLAB figure-export failure mode in `Part4_v6`. It does not change the eigenvalue solve, ranking, or physical acceptance logic.

## 2026-04-16 - Restore Chinese comments and figure text in write_paperA_reference_figures

Summary:
- After the earlier interpreter-hardening pass, the user asked to restore the Chinese comments and user-visible figure text in `src/core/write_paperA_reference_figures.m`.
- Updated the helper so comments, eigenspectrum titles, modal field titles, and the `Lead` annotation are back in Chinese.
- Kept the safer text settings from the previous pass: the main titles and annotations still use explicit `Interpreter='none'`, while `x^{*}` / `y^{*}` remain on TeX-safe axis labels.
- No new `Part4` solve was launched; validation stayed on the cheap path.

Files touched:
- `src/core/write_paperA_reference_figures.m`
- `docs/coordination/TASK_LOG.md`

Validation:
- `matlab -batch "cd('C:/Users/UserX/Downloads/double_wedgeold'); checkcode('src/core/write_paperA_reference_figures.m');"`

Notes:
- The remaining `checkcode` output is only the old "past suppression" advisory and not a syntax or runtime error.

## 2026-04-17 - Repair plotted-lead metadata reuse, align shock-core masks, and fix the north-edge contract

Summary:
- A static review of the active `v6` path found three coupled correctness/provenance issues that could all be fixed on the cheap path without rerunning `Part4_v6`.
- Fixed `Main_DoubleWedge_Part4_v6.m` so saved plotted-lead metadata no longer changes meaning between the in-memory selection summary and the persisted top-level fields. The sorted plotted-lead position and the original unsorted mode index are now preserved separately.
- Added `src/core/resolve_part4_plot_lead_position.m` and updated `run/run_user_test_baseflow_fullres_v6.m` to use it, so reused `Part4_Results.mat` files with `no_physical_plot_candidate` status now summarize cleanly instead of crashing on `NaN` indexing.
- Tightened `src/core/build_paperA_mode_masks.m` so `shock_core` cannot extend outside the actual protected shock band carried in `ShockInfo.shock_mask`; this keeps the Part4 hard ranking gates consistent with the Part3 near-wall protection logic.
- Fixed `src/core/assert_realcase_boundary_contract.m` so the top-edge inlet contract excludes the top corners already owned by the west/east edges, matching the corner-ownership rule in `build_boundary_masks.m`.
- Added focused regressions for all three repairs, including one reuse-only runner test that exercises the Part4 summary path without launching a new expensive solve.

Files touched:
- `Main_DoubleWedge_Part4_v6.m`
- `run/run_user_test_baseflow_fullres_v6.m`
- `src/core/resolve_part4_plot_lead_position.m`
- `src/core/build_paperA_mode_masks.m`
- `src/core/assert_realcase_boundary_contract.m`
- `tests/test_paperA_mode_masks.m`
- `tests/test_resolve_part4_plot_lead_position.m`
- `tests/test_realcase_boundary_contract.m`
- `tests/test_run_user_test_reuse_no_plot_lead_v6.m`
- `run/run_phase2_validation.m`
- `docs/coordination/ACTIVE_CONTEXT.md`
- `docs/coordination/TASK_LOG.md`
- `docs/audit.md`

Validation:
- `matlab -batch "cd('C:/Users/UserX/Downloads/double_wedgeold'); addpath(pwd); addpath(fullfile(pwd,'run')); addpath(fullfile(pwd,'src','core')); addpath(fullfile(pwd,'tests')); test_plot_lead_selection; test_resolve_part4_plot_lead_position; test_paperA_mode_masks; test_realcase_boundary_contract; test_run_user_test_reuse_no_plot_lead_v6;"`
- `matlab -batch "cd('C:/Users/UserX/Downloads/double_wedgeold'); addpath(pwd); addpath(fullfile(pwd,'run')); run_phase2_validation;"`

Notes:
- Per the user request, this task did not rerun `Main_DoubleWedge_Part4_v6` on a real or benchmark case. The new reuse test builds a tiny saved `Part4_Results.mat` fixture instead.

## 2026-04-20 - Fix sigma-scan empty-triplet semantics for user-side real-case sweeps

Summary:
- Analyzed a new user-provided `run_global_stability_case_v6` screenshot and matched its `812 x 382`, `stride = 3`, `beta = 0`, `n_eigs = 30` scan settings to the current `v6` code path.
- Confirmed that the reported descriptor failure was consistent with a `271 x 128` working grid (`Ndof = 173440`) staying below the current large-system low-memory threshold, so `Part4_v6` still used the standard shift-invert branch.
- Found a runner-level semantics bug in `run/run_sigma_shift_scan_v6.m`: when the caller set `LockSigmaTripletToShift = false` but left `SigmaTriplet = []`, the scan still forced a one-shift solve instead of preserving the documented default Part1 shift family.
- Fixed the scan helper so only explicit locking forces a single-shift solve, and added a regression assertion that loads `Part1_Results.mat` to verify that `Config.sigma_triplet` stays on the default family while `Config.sigma` still tracks the per-case primary scan shift.

Files touched:
- `run/run_sigma_shift_scan_v6.m`
- `tests/test_run_sigma_shift_scan_part3_only_v6.m`
- `docs/coordination/ACTIVE_CONTEXT.md`
- `docs/coordination/TASK_LOG.md`

Validation:
- `matlab -batch "cd('C:/Users/UserX/Downloads/double_wedgeold'); addpath(pwd); addpath(fullfile(pwd,'run')); addpath(fullfile(pwd,'src','core')); addpath(fullfile(pwd,'tests')); test_run_sigma_shift_scan_part3_only_v6;"`

Notes:
- This fix changes the scan semantics only for the explicit combination `LockSigmaTripletToShift=false` and `SigmaTriplet=[]`; the default locked single-shift scan path is unchanged.

## 2026-04-21 - Add runner-level forced low-memory descriptor mode for user-side real-case scans

Summary:
- Investigated the follow-up user report that the descriptor solve still failed even after only editing `run_global_stability_case_v6.m`.
- Confirmed that this was still plausible on the intended `812 x 382`, `stride = 3` path because the working system (`271 x 128`, `Ndof = 173440`) remains below the default automatic large-system threshold, so the solver can stay on the heavier standard plan unless explicitly forced down.
- Added a new runner flag `ForceLowMemoryDescriptor` and threaded it through `run_global_stability_case_v6.m`, `run_sigma_shift_scan_v6.m`, and `run_user_test_baseflow_fullres_v6.m`.
- The new flag works by rewriting `Config.descriptor_solver.large_system_threshold` to `1` after `Part1`, which reuses the existing large-system low-memory logic without changing the default behavior of normal benchmark runs.
- Added a smoke regression that runs a tiny full `Part4` case with the new flag and checks that the saved `SolveAudit.memory_policy` is `large_system_low_memory`.

Files touched:
- `run/run_global_stability_case_v6.m`
- `run/run_sigma_shift_scan_v6.m`
- `run/run_user_test_baseflow_fullres_v6.m`
- `tests/test_run_user_test_force_low_memory_descriptor_v6.m`
- `run/run_phase2_validation.m`
- `docs/coordination/ACTIVE_CONTEXT.md`
- `docs/coordination/TASK_LOG.md`

Validation:
- `matlab -batch "cd('C:/Users/寒橘柚/Downloads/double_wedgeold'); addpath(pwd); addpath(fullfile(pwd,'run')); addpath(fullfile(pwd,'src','core')); addpath(fullfile(pwd,'tests')); test_run_sigma_shift_scan_part3_only_v6;"`
- `matlab -batch "cd('C:/Users/寒橘柚/Downloads/double_wedgeold'); addpath(pwd); addpath(fullfile(pwd,'run')); addpath(fullfile(pwd,'src','core')); addpath(fullfile(pwd,'tests')); test_run_user_test_force_low_memory_descriptor_v6;"`

Notes:
- This change does not alter the default solver thresholds. It only affects runs that explicitly set `ForceLowMemoryDescriptor = true`.

## 2026-04-21 - Remove in-repo stale transfer mirror and dead local-run helpers

Summary:
- Reworked `tests/test_setup_double_wedge_paths_precedence.m` so it now builds a tiny synthetic stale-copy fixture in the system temp directory instead of depending on the old bundled transfer mirror under `outputs/transfer/`.
- Deleted the unreferenced helpers `src/core/local_run_case_script.m` and `src/core/local_run_main.m`; they were not called by the active runner chain, tests, or reusable helpers.
- Removed the old in-repo transfer bundle `outputs/transfer/double_wedge_812x382_portable_20260416/` so the main workspace no longer carries a full mirrored repo tree just to support one path-precedence regression.
- Updated the active snapshot and work-queue docs so transfer bundles are now treated as on-demand external packaging artefacts rather than as permanent generated content inside the repo.

Files touched:
- `tests/test_setup_double_wedge_paths_precedence.m`
- `src/core/local_run_case_script.m`
- `src/core/local_run_main.m`
- `docs/coordination/ACTIVE_CONTEXT.md`
- `docs/coordination/WORK_QUEUE.md`
- `docs/PROJECT_STRUCTURE.md`
- `docs/coordination/TASK_LOG.md`
- `docs/audit.md`

Validation:
- `matlab -batch "cd('C:/Users/寒橘柚/Downloads/double_wedgeold'); setup_double_wedge_paths('IncludeTests', true); test_setup_double_wedge_paths_precedence;"`
- `matlab -batch "cd('C:/Users/寒橘柚/Downloads/double_wedgeold'); setup_double_wedge_paths('IncludeTests', true); run_phase2_validation;"`

Notes:
- This cleanup intentionally does not change the production solver path or any `Part1` to `Part4` operator logic.

## 2026-04-22 - Make research workflow defaults conservative for low-memory real-case runs

Summary:
- Investigated a new user report that `run/run_research_workflow_case_v6.m` still ran out of memory on repeated intended-case launches.
- Confirmed that the main issue was no longer only the descriptor solver internals; the editable workflow script itself still stacked several expensive stages by default: `stride = 1`, coarse `beta` scan with `RunBetaScanPart4 = true`, refined `Part4` enabled, resolvent enabled, and relatively aggressive `n_eigs` values.
- Reworked the editable case script so its top-of-file defaults now match the previously documented conservative first pass for the intended `812 x 382` workflow: `stride_x = stride_y = 3`, coarse `beta` scan stays on `Part3` only, refined `Part4` and resolvent start disabled, the default `beta` list and `n_eigs` values are smaller, `SigmaTriplet` is pinned to the primary shift, and the Krylov floor/cap are explicitly reduced.
- Updated `run/run_research_workflow_v6.m` so refined `Part4` adjoint diagnostics are truly optional through a new `EnableRefinedAdjointLeadDiagnostics` flag instead of always being enabled.
- Added a new refined-workflow smoke regression that completes a tiny `Part4` case with adjoint diagnostics disabled and verifies that the saved audit remains explicitly disabled.

Files touched:
- `run/run_research_workflow_v6.m`
- `run/run_research_workflow_case_v6.m`
- `tests/test_run_research_workflow_refined_part4_no_adjoint_v6.m`
- `run/run_phase2_validation.m`
- `docs/coordination/ACTIVE_CONTEXT.md`
- `docs/coordination/TASK_LOG.md`
- `docs/audit.md`

Validation:
- `matlab -batch "cd('C:/Users/寒橘柚/Downloads/double_wedgeold'); setup_double_wedge_paths('IncludeTests', true); checkcode('run/run_research_workflow_v6.m','-id'); checkcode('run/run_research_workflow_case_v6.m','-id'); checkcode('tests/test_run_research_workflow_refined_part4_no_adjoint_v6.m','-id'); test_run_research_workflow_part3_only_v6; test_run_research_workflow_refined_part4_no_adjoint_v6;"`
- `matlab -batch "cd('C:/Users/寒橘柚/Downloads/double_wedgeold'); setup_double_wedge_paths('IncludeTests', true); run_phase2_validation;"`

Notes:
- This change is intentionally aimed at the manual workflow entry used for intended-case runs; the reusable workflow function still allows callers to re-enable refined `Part4`, adjoint diagnostics, resolvent scans, denser `beta` lists, or larger `n_eigs` values once the cheap stages have been cleared.

## 2026-04-22 - Implement Sidharth benchmark contracts and publication-plot safeguards

Summary:
- Added an explicit `Sidharth2018` benchmark/profile contract and threaded it from `Part1` through the reusable runner/scan/workflow layer.
- `Part1_v6` now defaults the Sidharth code-correction route to `no sponge + light SAV` with shock-source and pressure-row regularization disabled unless a runner explicitly re-enables them for ablation.
- `Part2_v6` now saves `LiteratureBenchmarkAudit` and `BaseflowReferenceTable`; `Part3_v6` now saves `PostBCAblationAudit` and `OperatorAblationTable`; `Part4_v6` now saves component-mode audits, literature-facing reference tables, and plot provenance / plot contract metadata.
- `write_paperA_reference_figures.m` now refuses to emit misleading lead-mode cloud figures when no physical plot candidate exists and adds a separate Sidharth figure contract when requested by the benchmark profile.
- Added the preset entry `run/run_sidharth2018_workflow_v6.m`, expanded runner compatibility for older `Part2` / `Part4` MAT files, and updated the text summary path so the literature tables and provenance are written into `run_summary.txt`.

Files touched:
- `Main_DoubleWedge_Part1_v6.m`
- `Main_DoubleWedge_Part2_v6.m`
- `Main_DoubleWedge_Part3_v6.m`
- `Main_DoubleWedge_Part4_v6.m`
- `run/config_case.m`
- `run/run_user_test_baseflow_fullres_v6.m`
- `run/run_beta_scan_v6.m`
- `run/run_sigma_shift_scan_v6.m`
- `run/run_resolvent_gain_scan_v6.m`
- `run/run_research_workflow_v6.m`
- `run/run_paperA_validation_suite.m`
- `run/run_global_stability_case_v6.m`
- `run/run_sidharth2018_workflow_v6.m`
- `src/core/get_double_wedge_benchmark_profile.m`
- `src/core/build_paperA_baseflow_context.m`
- `src/core/apply_structured_bc_rows.m`
- `src/core/compute_mode_filter_metrics.m`
- `src/core/rank_paperA_modes.m`
- `src/core/select_paperA_plot_lead_index.m`
- `src/core/write_paperA_reference_figures.m`
- `tests/test_bc_rows.m`
- `tests/test_mode_filter_metrics.m`
- `tests/test_part3_beta_audit_smoke.m`
- `tests/test_run_user_test_reuse_case_provenance_v6.m`
- `tests/test_run_user_test_reuse_no_plot_lead_v6.m`
- `tests/test_run_user_test_reuse_coupled_summary_v6.m`
- `tests/test_write_paperA_reference_figures_no_plot_candidate.m`
- `tests/test_run_sidharth2018_workflow_part3_only_v6.m`
- `run/run_phase2_validation.m`
- `docs/coordination/ACTIVE_CONTEXT.md`
- `docs/coordination/TASK_LOG.md`
- `docs/audit.md`

Validation:
- `matlab -batch "setup_double_wedge_paths('IncludeTests',true); run_phase2_validation;"`
- `matlab -batch "setup_double_wedge_paths('IncludeTests',true); test_write_paperA_reference_figures_no_plot_candidate; test_run_sidharth2018_workflow_part3_only_v6;"`

Notes:
- A full `270 x 128` structural case was launched under `outputs/mat/sidharth2018_structural_270x128_v6/`. It completed through `Part3`, but the `Part4` solve exceeded the current CLI timeout window, so this task does not yet claim a full fresh `270 x 128` publication-gating result.

## 2026-04-23 - Add pressure-component quality gates for Sidharth plot selection

Summary:
- Audited the user-reported pressure-row issue against `Main_DoubleWedge_Part3_v6.m` and confirmed that the current pressure mass matrix and `LPP = -D(u0/a^2)Dx - D(v0/a^2)Dy - D(div/a^2)` path are the corrected acoustic-pressure scaling, so this change intentionally does not revert to the pre-pressure-fix operator.
- Confirmed the real ranking bug: `compute_mode_filter_metrics.m` only used `u'` to build the saved checker ratio, so a mode with a clean `u'` field but oscillatory `p'` could pass the plot-candidate filters.
- Added component-level checker diagnostics for `u/v/w/T/p`, direct pressure aliases (`p_checker_ratio`, `p_free_stream_overlap`, `p_outlet_overlap`, `p_outlet_wall_overlap`, `p_shock_core_overlap`, and pressure peak flags), and changed the total checker ratio to include the worst component.
- Extended `rank_paperA_modes.m` and `select_paperA_plot_lead_index.m` so Sidharth plot eligibility rejects modes with pressure checker/free-stream/outlet-wall/shock-core contamination instead of promoting pressure-acoustic tails into publication-style cloud plots.
- Aligned the default correction route across core validation, `Part3`, the pressure-row helper, and editable runner scripts: shock-source and pressure-row regularization now default off unless explicitly enabled for ablation.
- Updated reuse tests and config tests so synthetic legacy cases match the new default contract while still preserving explicit override/reuse checks.

Files touched:
- `Main_DoubleWedge_Part1_v6.m`
- `Main_DoubleWedge_Part3_v6.m`
- `Main_DoubleWedge_Part4_v6.m`
- `src/core/compute_mode_filter_metrics.m`
- `src/core/rank_paperA_modes.m`
- `src/core/select_paperA_plot_lead_index.m`
- `src/core/build_paperA_pressure_row_regularization_v6.m`
- `src/core/validate_config.m`
- `src/core/refresh_saved_paperA_outputs.m`
- `run/run_user_test_baseflow_fullres_v6.m`
- `run/run_research_workflow_v6.m`
- `run/run_global_stability_case_v6.m`
- `run/run_research_workflow_case_v6.m`
- `tests/test_mode_filter_metrics.m`
- `tests/test_plot_lead_selection.m`
- `tests/test_config_fields.m`
- `tests/test_run_user_test_reuse_no_plot_lead_v6.m`
- `tests/test_run_user_test_reuse_coupled_summary_v6.m`
- `docs/coordination/TASK_LOG.md`
- `docs/coordination/ACTIVE_CONTEXT.md`
- `docs/coordination/WORK_QUEUE.md`
- `docs/audit.md`

Validation:
- `matlab -batch "setup_double_wedge_paths('IncludeTests', true); test_mode_filter_metrics; test_plot_lead_selection; test_config_fields; test_paperA_pressure_row_regularization_v6;"`
- `matlab -batch "setup_double_wedge_paths('IncludeTests', true); test_run_user_test_reuse_no_plot_lead_v6; test_run_user_test_reuse_coupled_summary_v6;"`
- `matlab -batch "setup_double_wedge_paths('IncludeTests', true); run_phase2_validation;"`

Notes:
- The pressure-equation scaling remains on the corrected `v6` path. The current fix targets selection/audit correctness and prevents oscillatory pressure tails from being treated as valid Sidharth disturbance structures.

## 2026-04-23 - Review Gemini static-audit findings and tighten checker fallback plotting

Summary:
- Reviewed the Gemini static-audit report against the active production code without running an expensive `Part4` physical solve.
- Confirmed that the descriptor-vector recovery warning is already handled correctly: `solve_paperA_descriptor_modes.m` maps scaled eigenvectors back through `EigVecs_all = Dc * EigVecs_scaled_all` before residuals, ranking, extraction, or plotting.
- Confirmed the active SAV path is `build_shock_localized_sav_matrix.m -> build_semi_artificial_viscosity_matrix.m`; the fourth-difference stencil sign remains consistent with a dissipative high-frequency filter when added to `LNS_L`.
- Found one valuable issue in the Gemini ranking discussion: `residual_only_fallback` still reused `plot_candidate_mask = mask_res`, so a residual-clean but checker-failed bubble-looking mode could still become a plotted lead.
- Fixed `rank_paperA_modes.m` so residual-only fallback modes remain available for diagnostic ordering but are removed from the true plot candidate pool.
- Fixed a related selector-sign regression in `select_paperA_plot_lead_index.m`: `u_peak_in_bubble` is now rewarded rather than penalized when choosing among plot-lead candidates.
- Added a regression case to `tests/test_plot_lead_selection.m` that locks out residual-clean checker-failed modes from `selected_for_plots`.

Files touched:
- `src/core/rank_paperA_modes.m`
- `src/core/select_paperA_plot_lead_index.m`
- `tests/test_plot_lead_selection.m`
- `docs/coordination/TASK_LOG.md`
- `docs/coordination/ACTIVE_CONTEXT.md`
- `docs/audit.md`

Validation:
- `matlab -batch "setup_double_wedge_paths('IncludeTests', true); test_plot_lead_selection; test_mode_filter_metrics; test_config_fields; test_paperA_pressure_row_regularization_v6;"`
- `matlab -batch "setup_double_wedge_paths('IncludeTests', true); test_plot_lead_selection;"`
- `matlab -batch "setup_double_wedge_paths('IncludeTests', true); run_phase2_validation;"`

Notes:
- One intermediate `run_phase2_validation` attempt failed because MATLAB could not delete an old generated test directory under `outputs/mat/test_beta_scan_part3_only_v6`; after safely removing that generated directory, the full suite passed.

## 2026-04-23 - Align Sidharth ranking support, phase anchors, and lead provenance

Summary:
- Reviewed the production `main_double_wedge_part1 -> ... -> main_double_wedge_part4` path against the six reported ranking/provenance findings.
- Confirmed the main issues: production support fractions still used a fixed `u_dominant` basis, phase anchoring still preferred `u'`, plot-lead selection was tied to the gallery subset, validity-report thresholds were duplicated locally, and free-stream masks were not consistently consumed from `BaseflowMasks`.
- Changed production mode-filter metrics to use configurable `component_energy` support by default, with the actual support basis saved in ranking metrics and `selection_summary.mode_filter_thresholds`.
- Added `src/core/build_paperA_mode_filter_thresholds.m` so the ranker and validity report share one resolved threshold bundle instead of duplicating numeric gates.
- Updated phase alignment and refresh paths so `choose_mode_phase_factor(...)` accepts `ReferenceComponent`; Sidharth `w`-reference modes now anchor phase on `w'` first, with `u'` only as fallback.
- Split lead provenance into explicit `sorted_lead`, `plot_lead`, and `publication_lead` summaries plus separate region-energy summaries. Legacy `leading_*` fields are retained only as plot-lead compatibility aliases.
- Decoupled plot-lead candidates from gallery truncation through `ranking.plot_lead_candidate_mask`; `selected_for_plots` now controls the gallery only. Also fixed the plotted-lead `u_peak_in_bubble` sign so it is rewarded rather than penalized.
- Made `build_paperA_mode_masks.m` prefer `BaseflowMasks.free_stream_mask`; fallback free-stream construction now uses configurable `mode_filter.free_stream_eta_threshold`.

Files touched:
- `Main_DoubleWedge_Part1_v6.m`
- `Main_DoubleWedge_Part4_v6.m`
- `src/core/build_paperA_baseflow_context.m`
- `src/core/build_paperA_mode_filter_thresholds.m`
- `src/core/build_paperA_mode_masks.m`
- `src/core/choose_mode_phase_factor.m`
- `src/core/compute_mode_filter_metrics.m`
- `src/core/rank_paperA_modes.m`
- `src/core/refresh_saved_paperA_outputs.m`
- `src/core/select_paperA_plot_lead_index.m`
- `src/core/validate_config.m`
- `tests/test_config_fields.m`
- `tests/test_mode_filter_metrics.m`
- `tests/test_paperA_mode_masks.m`
- `tests/test_paperA_phase_anchor.m`
- `tests/test_plot_lead_selection.m`
- `docs/coordination/TASK_LOG.md`
- `docs/coordination/ACTIVE_CONTEXT.md`
- `docs/coordination/WORK_QUEUE.md`
- `docs/audit.md`

Validation:
- `matlab -batch "setup_double_wedge_paths('IncludeTests', true); test_config_fields; test_mode_filter_metrics; test_paperA_phase_anchor; test_paperA_mode_masks; test_plot_lead_selection;"`
- `matlab -batch "setup_double_wedge_paths('IncludeTests', true); test_mode_coupling_audit; test_write_paperA_reference_figures_no_plot_candidate; test_resolve_part4_plot_lead_position; test_run_user_test_reuse_coupled_summary_v6; test_run_user_test_reuse_no_plot_lead_v6;"`
- `matlab -batch "setup_double_wedge_paths('IncludeTests', true); test_part3_beta_audit_smoke; test_run_user_test_baseflow_part3_only_v6; test_run_beta_scan_part3_only_v6; test_run_sidharth2018_workflow_part3_only_v6;"`
- `matlab -batch "files = {'Main_DoubleWedge_Part4_v6.m','src/core/rank_paperA_modes.m','src/core/select_paperA_plot_lead_index.m','src/core/choose_mode_phase_factor.m','src/core/build_paperA_mode_filter_thresholds.m','src/core/build_paperA_mode_masks.m','src/core/build_paperA_baseflow_context.m','src/core/refresh_saved_paperA_outputs.m'}; for k = 1:numel(files), msgs = checkcode(files{k}, '-id'); if ~isempty(msgs), fprintf('[checkcode] %s\n', files{k}); for j = 1:numel(msgs), fprintf('%s:%d %s %s\n', files{k}, msgs(j).line, msgs(j).id, msgs(j).message); end; end; end"`

Notes:
- Per user instruction, no new `Part4_v6` eigensolve was launched in this task. Validation stayed on targeted unit tests, reuse/plot metadata tests, and Part3-only smoke paths.
- `checkcode` reported only existing analyzer-suppression/string-literal style warnings in the checked files; no syntax errors were reported.

## 2026-04-23 - Retarget manual research workflow entry to explicit 812x382 first pass

Summary:
- Updated `run/run_research_workflow_case_v6.m` so the editable intended-case entry now defaults to `expected_dims = [812, 382]` instead of the local `270 x 128` structural benchmark dimensions.
- Renamed the default workflow output root to `manual_research_workflow_812x382_firstpass_v6` so intended-case runs are easier to distinguish from older generic manual workflows.
- Added an explicit hard stop that requires the user to set `baseflow_file` before the script can launch, preventing accidental reuse of the local `270 x 128` benchmark file under an intended-case parameter block.
- Updated `docs/coordination/ACTIVE_CONTEXT.md` so the active snapshot matches the new manual-entry contract.

Files touched:
- `run/run_research_workflow_case_v6.m`
- `docs/coordination/ACTIVE_CONTEXT.md`
- `docs/coordination/TASK_LOG.md`

Validation:
- `matlab -batch "setup_double_wedge_paths; checkcode('run/run_research_workflow_case_v6.m','-id');"`

Notes:
- This change does not claim that the intended `Mach 7, Re = 1e5` target mode is guaranteed to appear. It only ensures the manual intended-case entry is no longer mixing an `812 x 382` workflow contract with the local `270 x 128` structural benchmark file.

## 2026-04-23 - Validate Claude static review and patch only confirmed issues

Summary:
- Audited the six headline Claude review findings against the active `v6` production path and kept a strict “do not modify unless confirmed” rule.
- Fixed the real `beta ~= 0` operator bug in `src/core/build_paperA_beta_terms_v6.m`: the `Luw` and `Lvw` viscous pointwise beta couplings now use the Stokes-consistent `-(2/3)` coefficient on `mu_x` and `mu_y`.
- Reworked `src/core/build_paperA_pressure_closure_audit_v6.m` so Part3 no longer saves tautological pressure-closure fields; the audit now records independent density/EOS residuals and ratios, and the runner summary prints the new fields.
- Replaced `inv(M)` with `M \ eye(3)` in `src/core/build_structured_scalar_operators.m`, switched `src/core/preprocess_baseflow.m` to analytic Sutherland derivatives, and added `tests/test_preprocess_baseflow_sutherland_derivatives.m`.
- Deliberately did not change `src/core/build_uniform_fd_matrix.m` or `src/core/apply_structured_bc_rows.m`: the next-to-boundary second-derivative stencil is an existing tested contract, and the outlet row template remains an unresolved BC-design choice rather than a confirmed coding error.

Files touched:
- `src/core/build_paperA_beta_terms_v6.m`
- `src/core/build_paperA_pressure_closure_audit_v6.m`
- `src/core/build_structured_scalar_operators.m`
- `src/core/preprocess_baseflow.m`
- `tests/test_paperA_beta_terms_v6.m`
- `tests/test_paperA_pressure_closure_audit_v6.m`
- `tests/test_preprocess_baseflow_sutherland_derivatives.m`
- `tests/test_part3_beta_audit_smoke.m`
- `run/run_phase2_validation.m`
- `run/run_user_test_baseflow_fullres_v6.m`
- `docs/coordination/TASK_LOG.md`
- `docs/audit.md`

Validation:
- `matlab -batch "cd('C:/Users/寒橘柚/Downloads/double_wedgeold'); setup_double_wedge_paths('IncludeTests', true); test_paperA_beta_terms_v6; test_paperA_pressure_closure_audit_v6; test_preprocess_baseflow_sutherland_derivatives; test_structured_scalar_operators; test_part3_beta_audit_smoke;"`
- `matlab -batch "cd('C:/Users/寒橘柚/Downloads/double_wedgeold'); setup_double_wedge_paths('IncludeTests', true); run_phase2_validation;"`

Notes:
- The first full-suite attempt failed only because `run_phase2_validation` was invoked before calling `setup_double_wedge_paths('IncludeTests', true)`; re-running with the repo path bootstrap passed cleanly.
