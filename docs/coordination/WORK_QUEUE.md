# Work Queue

Last updated: 2026-04-23

## Next

- On the intended `812 x 382` path, inspect `PressureRowAudit`, `BetaAssemblyAudit`, `PressureClosureAudit`, `PostBCAblationAudit`, row scaling, and saved boundary masks before any new expensive `Part4` solve.
- For every refined `Part4` result, check `selection_status`, `publication_allowed`, `mode_validity_primary_reason`, `reference_component`, phase-anchor component, pressure-component gates, and sorted/plot/publication lead provenance before accepting a plotted mode.
- For `beta=0` or inactive-`w'` plotted modes, review the unified literature-style bubble-component figure and confirm `sidharth_component_contract=literature_style_bubble_components`; do not judge correctness from a near-zero `w'` panel or expect a dedicated `Fig20` special figure.
- If refined `Part4` returns `no_physical_plot_candidates`, keep the hard gate and run `run_resolvent_gain_scan_v6(...)` or a cheaper Part3 audit instead of relaxing the selector.
- Use `run/run_research_workflow_case_v6.m` as the default manual intended-case entry; set the real `812 x 382` baseflow path explicitly before running.
- Use `run_beta_scan_v6(...)` for the first structured `beta` sweep once cheap Part3 audits look sane.
- Use `run_sigma_shift_scan_v6(...)` or `sigma_shift_list` in `run_global_stability_case_v6.m` for shift sweeps instead of cloning cases manually.
- Keep transfer bundles on demand and outside the main repo tree; do not recreate a persistent full repo mirror under `outputs/transfer/`.
- Keep future user-facing localization conservative: translate labels, section titles, and figure filenames where natural, but preserve formula symbols and stable benchmark/config identifiers.

## Blocked

- Final physical validation is blocked until a trusted `812 x 382` physical baseflow and, ideally, matching boundary labels are available.
- Top-edge physical interpretation should remain tied to real mesh/baseflow/boundary-label evidence, not inferred screenshots.

## Later

- Add a cheap post-BC blockwise audit in `Part3_v6` to compare interior beta-term norms against final BC-overwritten operator rows.
- Revisit sponge studies separately from the current no-sponge SAV and mode-selection workflow.
- Keep checking local benchmark EOS, pressure-ratio, divergence proxy, and normalized mass-continuity diagnostics before treating any positive-growth structural result as physics.
