# Work Queue

Last updated: 2026-04-23

## Next

- Rerun or refresh a `270 x 128` structural `Part4` case with the new pressure-component plot gates and verify whether the selected result is now `no_physical_plot_candidate` or a genuinely bubble-centred lead.
- On the intended `812 x 382` path, inspect `p_checker_ratio`, `p_free_stream_overlap`, `p_outlet_wall_overlap`, and `p_shock_core_overlap` alongside the existing bubble/shock support metrics before accepting any plotted Sidharth-style disturbance cloud.
- Use the new `Part3_Results.mat` audit fields `PressureRowAudit`, `BetaAssemblyAudit`, and `PressureClosureAudit` on the user-side `812 x 382`, `beta = 8` path before launching another full `Part4_v6` solve.
- Use `run_beta_scan_v6(...)` for the first structured `beta` sweep once the cheap `Part3` audits look sane, so branch continuity and leading-mode family changes are saved automatically under one scan root.
- Use `run_resolvent_gain_scan_v6(...)` whenever the EVP remains globally stable or shock-dominated, so amplifier behavior is not forced into an eigenvalue-only interpretation.
- Use `run_research_workflow_case_v6.m` as the default manual entry for the full literature-aligned workflow instead of stitching the audit / scan / refined / resolvent stages together by hand.
- Use the new `run_sigma_shift_scan_v6(...)` or `sigma_shift_list` in `run_global_stability_case_v6.m` for shift sweeps instead of manually cloning one-shot cases.
- Run one cheap `Part3_v6` comparison with `use_shock_source_regularization = true/false` so "关闭半人工粘性" and "关闭 shock 源项正则化" are no longer conflated in later screenshot analysis.
- Use `run/run_global_stability_case_v6.m` or the now-configurable `run_user_test_baseflow_fullres_v6(...)` for user-side sweeps so every compare run keeps the same provenance layout under one case directory.
- Keep the new `ReuseExistingCase` provenance gate in place; if an older run needs to be reused, regenerate it once with fresh `RunnerCaseMetadata.mat` instead of allowing silent parameter drift.
- When handing the solver to another machine, generate a fresh transfer bundle outside the main repo tree rather than keeping a persistent full repo mirror under `outputs/transfer/`.
- Add a cheap post-BC blockwise audit in `Part3_v6` so the saved diagnostics can compare interior beta-term norms against the final BC-overwritten operator rows.
- Keep the `beta = [0, 1, 2, 4, 8]` scan on the no-sponge `v6` chain behind these audits so we do not waste time ranking shock-core modes that only survived because of known operator or selection issues.
- After the new `Part3` diagnostics look sane on the intended case, rerun only the minimum necessary user-side solve step rather than repeating the full pipeline by default.
- Keep checking the weak local benchmark baseflow diagnostics (`eos_relative_error`, `divergence_proxy_max`, and normalized `mass_continuity_relative_stats`) before treating any positive-growth local mode as final physics.

## Blocked By Missing External Data

- Confirm the physical meaning of the top structured-grid edge from a real extracted mesh, baseflow file, or boundary-label source.
- Run a full physical double-wedge case beyond smoke level once real PHengLEI baseflow data and, ideally, the hypara file are available.

## After The Structural v6 Pass

- Run the intended `812 x 382` case through the new `v6` path once a physically trustworthy baseflow is available.
- Keep sponge studies separate from the current no-sponge pseudo-mode-suppression and mode-selection question; the new runner still needs a dedicated follow-up pass before `UseSponge=true` becomes a trustworthy user-facing option.
