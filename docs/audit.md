# Audit Notes

Date: 2026-04-14
Phase: Beta=8 shock-dominated mode audit and correction plan

- Investigated a new user-provided `beta = 8` result where the default plotted leading mode is strongly aligned with the shock band rather than the expected separation-bubble footprint.
- Combined this screenshot with the already confirmed real-case import nuance: the worst EOS points on the intended `812 x 382` case are localized mainly in the shock region and near a geometric corner, not through the bulk flow.
- Rechecked the main static failure chain for this specific symptom:
  - `Part3_v6` still builds the operator directly from the raw primitive fields and derivatives, so localized shock/corner outliers can still enter the linear operator after the now-robust `Part2_v6` EOS gate passes.
  - Both `Main_DoubleWedge_Part3_v6.m` and `src/core/build_shock_localized_sav_matrix.m` still use `circshift` to dilate the shock band, which is a confirmed wrap-around bug and can over-regularize non-shock regions.
  - The shock-band regularization remains aggressive once that mask is built: clipped or zeroed second derivatives, suppressed viscosity-gradient terms, and shock-localized SAV all depend on that mask.
  - `Part4_v6` still permits a relaxed fallback plotted mode when no physically acceptable plot candidate exists, so a shock-heavy debug mode can still become the default figure output.
- Confirmed from code inspection that `beta` is not being ignored in the `v6` operator. The direct assembly includes explicit inviscid `-i*beta` couplings and viscous `-mu*beta^2` terms, but the large-`beta` path is still not protected by a dedicated regression suite or a term-by-term validation against an independently checked reduced case.
- Captured the then-current recommended order for this repair pass (now retired into `docs/coordination/WORK_QUEUE.md` and later audit entries):
  1. remove wrap-around shock dilation,
  2. remove silent plotted-lead fallback,
  3. add overlap diagnostics against shock/corner bad-point zones,
  4. audit beta terms in the primitive-five operator,
  5. then rerun the real-case `beta` scan.

Date: 2026-04-14
Phase: PHengLEI reader contract update for 12-column headered/headerless files

- Clarified the repository import contract for PHengLEI baseflow exports: 12 columns are now treated as a standard layout, not as an 11-column layout with one extra payload column.
- `src/core/read_phenglei_baseflow.m` still requires only the first 11 columns (`x y z rho u v w p T mach cp`) so older 11-column files remain readable, but when a twelfth `gama` column exists it is now preserved in `base.gama` and `base.gamma_local`.
- The reader metadata now distinguishes between optional standard columns and genuinely extra trailing columns: `standard_num_vars`, `num_optional_standard_vars`, `gamma_column_present`, and `num_extra_vars`.
- Updated the default reader hint in `run/config_case.m` from 11 to 12 so headerless PHengLEI files that follow the common 12-column export are interpreted correctly without looking like they contain one spurious extra column.
- Extended both retained reader tests so the headerless path and the multiline-header path now explicitly validate the 12-column PHengLEI contract.
- Validation after this batch: both reader tests passed, and the retained `run_phase2_validation` suite passed again with only the existing `test_matrix_sizes` skip.

Date: 2026-04-14
Phase: Descriptor-solver low-memory fallback for real-case Part4

- Investigated a user-side `812 x 382` failure where `solve_paperA_descriptor_modes.m` exhausted memory at `sigma = 0.05 + 0.02i` and then aborted with `No finite eigenpairs were produced by the descriptor solve`.
- The main issue was no longer only the Krylov dimension; the solver was still trying to honor the full shift family and a large total mode request before confirming that even one low-frequency shift could be factored and iterated on the available memory budget.
- `src/core/solve_paperA_descriptor_modes.m` now builds an explicit low-memory solve plan before entering the shift loop. For `Ndof >= 4e5` it trims both the effective shift list and the total mode budget, and for `Ndof >= 1e6` it collapses to one primary shift near `Config.sigma` with a very small per-shift `k` budget before growing again.
- The solver now retries each shift with progressively smaller `k/p` pairs instead of only shrinking `p`, and it records the requested shift set, effective shift set, low-memory policy, `k` candidates, and `p` candidates in `SolveAudit`.
- Fixed an implicit validity risk in the old Krylov-candidate builder: `p` is now always forced to remain larger than `k`, even when the configured `krylov_dimension_cap` is smaller than the current `k`.
- Added a focused regression test `tests/test_descriptor_solver_low_memory.m` that forces the huge-system low-memory policy and verifies that the solver trims to one shift and a capped mode budget without breaking the rest of the retained validation suite.
- Validation after this batch: `test_descriptor_solver_low_memory` passed, and the retained `run_phase2_validation` suite passed again with the existing `test_matrix_sizes` skip for the missing root `Part3_Results.mat`.

Date: 2026-04-03
Phase: Phase 1 audit plus Phase 2 validation scaffolding

## Boundary and Index Assumptions

- The solver uses the structured-grid convention `M(j,i)`, with `j` acting wall-normal-like and `i` streamwise-like.
- `main_double_wedge_part1.m`, `main_double_wedge_part2.m`, and `main_double_wedge_part3.m` all assume:
  - south edge (`j = 1`) is a mixed symmetry/wall boundary split by `Config.x_hinge`,
  - north edge (`j = Ny`) is farfield,
  - west edge (`i = 1`) is inlet,
  - east edge (`i = Nx`) is outlet.
- Before this patch, Part3 enforced the above only through raw index loops plus overwrite order. Corner ownership was implicit in that overwrite order.
- `build_boundary_masks.m` now makes corner ownership explicit with the solver's current precedence: south > west/east > north.
- The true physical meaning of the extracted top edge is still not geometry-verified in this repository because no mesh-label source or baseflow data file is present. That confirmation remains required.

## Defined vs Used Config Fields

- Explicitly defined in Part1 before this patch:
  - `Ma_inf`, `Re_inf`, `T_inf`, `gamma`, `Pr`, `Cv_nd`, `S_nd`, `T_wall_nd`
  - `Nx_raw`, `Ny_raw`, `Nvar`, `n_header`
  - `col_x`, `col_y`, `col_z`, `col_rho`, `col_u`, `col_v`, `col_w`, `col_p`, `col_T`, `col_mach`, `col_cp`, `col_gama`
  - `ds_x`, `ds_y`, `Nx`, `Ny`
  - `x_hinge`, `n_eigs`, `sigma`, `datafile`
- Used elsewhere but previously not made explicit in Part1:
  - `boundary_map`
  - `bc_topology`
  - `use_physical_filter`
- Used in Part4 and still intentionally not guessed:
  - `U_ref`
  - `L_ref`

## Physical Filtering Assumptions

- Part4 converts eigenvalues to Strouhal number with `St = imag(lambda) / (2*pi) * L_ref / U_ref`.
- Because `U_ref` and `L_ref` are not defined in Part1, this patch does not invent values.
- Validation policy after this patch:
  - if `Config.use_physical_filter == true`, then `Config.U_ref` and `Config.L_ref` are required and validated;
  - if `Config.use_physical_filter == false`, Part4 skips the physical eigenvalue filter and keeps residual filtering active.

## Hard-Coded BC Logic

- Part3 still assembles BC rows with the existing solver formulas:
  - farfield and inlet: full Dirichlet,
  - outlet: fourth-order extrapolation,
  - south symmetry: `v' = 0` plus one-sided Neumann for `rho'`, `u'`, `T'`,
  - south wall: `u' = v' = T' = 0` plus one-sided Neumann for `rho'`.
- This patch adds explicit mask construction and boundary validation utilities, but does not change the governing equations or the BC formulas themselves.

## Blocking Risks Found

- Part2 had a MATLAB-incompatible chained index expression: `(dX.ux + dX.vy)(:)`.
- Part3 had a non-scalar logical risk: `if any(isnan(Lv_chk)||isinf(Lv_chk))`.
- Part4 dereferenced `Config.U_ref` and `Config.L_ref` without prior validation.

## Change Note

- Added explicit config validation, boundary-mask utilities, Phase 2 tests, and MATLAB R2020a compatibility fixes without changing the solver physics.
- Updated Part4 result selection so the reported leading mode is sorted by residual first, then by boundary-band concentration and checkerboard correlation, before growth rate.
- Added a mode-diagnostic helper and test to separate boundary-dominated / checkerboard-like numerical modes from smoother interior modes in post-processing.
- Updated Part3 matrix-statistics reporting to convert sparse row-max vectors to full before `min/max` diagnostics, avoiding MATLAB R2020a sparse-input function errors.
- Expanded Part4 mode diagnostics to use a grid-relative boundary band, explicit farfield-band energy, high-frequency content, and wall-normal centroid before residual-first ranking among valid modes.
- Added a post-run all-mode separation-bubble `u'` gallery option via `Config.plot_all_mode_u_bubble` and `run/plot_all_mode_u_bubble.m`, with saved pages under `outputs/figs/`.
- Replaced `prctile`-based visualization scaling in the new gallery path with a toolbox-free local percentile helper so the post-processing works without Statistics and Machine Learning Toolbox.
- Added `apply_structured_bc_rows.m` plus `test_bc_rows.m` so Part3 can re-apply boundary rows from explicit masks instead of relying only on raw `j=Ny`, `i=1`, `i=Nx`, `j=1` overwrite loops.
- Rewrote the top-level `run.m` entry script to call the current `main_double_wedge_part1` ... `main_double_wedge_part4` scripts directly, avoiding nested `run(...)` calls that conflicted with the local `run.m` filename.

Date: 2026-04-07
Phase: Modular rework, batch 1

- Added a new modular entry/config path under `run/` and new PHengLEI reader/preprocess stages under `src/core/`.
- Locked the new pipeline to the conservative perturbation ordering `q = [rho', (rho*u)', (rho*v)', (rho*w)', (rho*E)']^T` and the convention `exp(sigma*t + i*beta*z)`.
- Made `cfg.io.baseflow_file` and `cfg.io.boundary_file` explicit because this repository still does not ship a real PHengLEI baseflow or hypara file.
- Added geometry-based bottom-edge segmentation (`x<0` symmetry, `x>=0` wall) and a saved boundary-audit figure under `outputs/figs/`.
- Added preprocessing checks for positivity, EOS consistency, Sutherland viscosity derivatives, wall-model ambiguity (`isothermal` versus `adiabatic`), and baseflow `w` contamination.
- Deferred all equation/operator changes to later batches so that the reader, topology interpretation and physical assumptions can be validated first.

Date: 2026-04-08
Phase: Paper-A alignment scaffolding, batch 2

- Added reusable `src/core/fd4_uniform.m` and `src/core/compute_structured_metrics.m` so the metric/Jacobian formulas used by `main_double_wedge_part2.m` can be validated independently on analytic structured-grid mappings.
- Added `tests/test_metric_jacobian.m` to cover the missing validation gate from `AGENTS.md`.
- Fixed the generalized-eigenvalue BC-row treatment in `src/core/apply_structured_bc_rows.m`: algebraic Dirichlet/Neumann/extrapolation rows now zero the corresponding mass-matrix rows instead of writing identity rows into both matrices, avoiding spurious `sigma = 1` boundary modes.
- Generalized `apply_structured_bc_rows.m` to support both the legacy 4-variable layout `q = [rho', u', v', T']` and a paper-A-style primitive 5-variable layout `q = [u', v', w', T', p']` at the boundary-condition layer.
- Added `src/core/build_sponge_profile.m` to construct explicit outlet/top/inlet/bottom sponge profiles with tunable strength and thickness for Mani-2012-style sensitivity studies.
- Added `src/core/build_semi_artificial_viscosity.m` to compute a weak pressure-gradient-based stabilization coefficient field intended for shock-region pseudo-mode control.
- Added `tests/test_eigs_smoke.m` to solve a small primitive-5 generalized eigenvalue problem with explicit BC rows, sponge damping, and weak stabilization, producing a smoke artifact under `outputs/mat/`.
- Updated `tests/test_bc_rows.m`, `tests/test_matrix_sizes.m`, and `run/run_phase2_validation.m` to reflect the corrected BC-row mass-matrix treatment and the required validation order.
- Corrected the sign of the first-derivative fourth-order stencil in `main_double_wedge_part2.m` and in the reusable `src/core/fd4_uniform.m`; the previous coefficients failed an analytic metric/Jacobian check on a quadratic mapping.
- Hooked the current legacy Part3 operator to the new sponge profile and weak pressure-gradient-based stabilization as interim operator-level damping terms, while keeping the later BC-row overwrite step authoritative on the actual boundary rows.
- Added explicit guards in `main_double_wedge_part3.m` and `main_double_wedge_part4.m` so the old four-variable interior/post-processing path cannot silently pretend to support the new primitive-5 layout before the full operator rewrite is done.

Date: 2026-04-08
Phase: Paper-A alignment scaffolding, batch 3

- Added `src/core/get_state_layout_info.m`, `src/core/extract_state_component.m`, and `src/core/build_state_damping_weights.m` so state-layout semantics, modal reshaping, and damping weights are no longer hard-coded to the legacy four-variable ordering.
- Updated both copies of `compute_mode_diagnostics.m`, plus `rank_mode_candidates.m` and `plot_mode_u_bubble_gallery.m`, to accept the paper-A-style primitive layout `q = [u', v', w', T', p']` without breaking the legacy path.
- Extended `tests/test_mode_diagnostics.m`, `tests/test_mode_ranking.m`, and `tests/test_mode_u_bubble_gallery.m` so the diagnostic / ranking / gallery pipeline is now validated on both the legacy four-variable layout and the primitive five-variable layout.
- Updated `main_double_wedge_part3.m` so the current validated legacy four-variable interior operator can be lifted into a primitive-five generalized eigenvalue pencil through `lift_legacy4_pencil_to_primitive5.m` before the explicit boundary-mask overwrite step; this is still an intermediate transition layer, not yet a direct handwritten paper-A primitive-five interior assembly.
- Updated `main_double_wedge_part3.m` so sponge damping and weak shock-region stabilization are applied on primitive-five DOFs after the lift step, with layout-aware damping weights.
- Added `src/core/run_part4_primitive5.m` and made `main_double_wedge_part4.m` dispatch to it whenever `Config.state_layout = 'primitive5_u_v_w_T_p'`; the new path performs primitive-five scaling, generalized-eigenvalue solution, residual filtering, quality ranking, field extraction, figure generation, and `Part4_Results.mat` export including `w_hat`.
- Added `tests/test_part4_primitive5_smoke.m` plus the corresponding hook in `run/run_phase2_validation.m` so the primitive-five Part4 branch now has an end-to-end smoke test that reaches eigensolve, ranking, plotting, and result saving.

Date: 2026-04-08
Phase: Literature-guided audit continuation, batch 4

- Continued the code audit against paper A and the local supporting references before further Part3 edits.
- Synchronized `src/core/validate_config.m` with the richer root-level validator so `beta`, `state_layout`, sponge settings, and semi-artificial-viscosity settings are validated consistently regardless of MATLAB path shadowing.
- Updated `src/core/fd4_uniform.m` and `src/core/build_uniform_fd_matrix.m` so the discretization now matches paper A more closely: fourth-order centered stencils in the interior and third-order biased stencils near structured-grid boundaries, instead of fourth-order one-sided boundary stencils.
- Added `tests/test_fd_boundary_stencils.m` and wired it into `run/run_phase2_validation.m` to validate both the stencil footprint and polynomial exactness of the revised boundary-difference operators.
- Current high-priority gaps still open after this batch: the primitive-five interior operator in Part3 remains an intermediate lift from the legacy pencil rather than a direct paper-A-style primitive-five assembly.

Date: 2026-04-08
Phase: Literature-guided audit continuation, batch 5

- Corrected the post-processing frequency interpretation in both `main_double_wedge_part4.m` and `src/core/run_part4_primitive5.m` by adding `src/core/interpret_sigma_eigenvalues.m` and making the paper-A relation `sigma = -i*omega` explicit.
- Part4 now reports the absolute frequency magnitude for plots/tables and saves the signed frequency and `omega` values separately, instead of treating `imag(sigma)/(2*pi)` as the physical frequency.
- Added `tests/test_sigma_frequency_convention.m` and extended `tests/test_part4_primitive5_smoke.m` so the sigma/omega convention is validated both as a standalone helper and inside the primitive-five Part4 save path.
- Added clearer provenance metadata to `main_double_wedge_part3.m` so `Primitive5Report` states explicitly that the current primitive-five route is still a legacy4-to-primitive5 compatibility lift, not yet a direct paper-A primitive-five interior discretization.
- Switched the production default `Config.state_layout` and the validator defaults from `legacy4_rho_u_v_T` to `primitive5_u_v_w_T_p`, while keeping the legacy path available explicitly.
- Updated `main_double_wedge_part3.m` so the old raw-index BC overwrite block is no longer the default path; explicit mask-based BC application via `apply_structured_bc_rows.m` is now the authoritative boundary-treatment route.
- Added `README_codex_handoff.md` to reduce onboarding cost for a fresh Codex account and document the current goal, literature mapping, conventions, validations, and next steps.

Date: 2026-04-08
Phase: Collaboration handoff and folder classification

- Added `docs/coordination/README.md`, `ACTIVE_CONTEXT.md`, `WORK_QUEUE.md`, and `TASK_LOG.md` to standardize multi-account handoff and require a completed-task record after each task.
- Added `docs/PROJECT_STRUCTURE.md` so the repository layout, root-level production-path exceptions, and output locations are explicit.
- Reworked `README_codex_handoff.md` into a compact top-level index that points new Codex sessions to the coordination docs first.
- Added `outputs/logs/README.md` so the declared log directory now exists in the repository layout.
- No solver equations, numerics, or BC formulas were changed in this batch.

Date: 2026-04-09
Phase: Legacy4 semi-artificial-viscosity filter pass

- Reoriented the active production default back to the legacy four-variable path `q = [rho'', u'', v'', T'']^T` by switching the default `Config.state_layout` and validator defaults from `primitive5_u_v_w_T_p` to `legacy4_rho_u_v_T`.
- Disabled sponge damping by default for this phase so boundary absorption is not mixed with pseudo-mode suppression; the sponge helper remains available only when explicitly requested.
- Replaced the previous pressure-gradient-sensor-based diagonal damping on the main Part3 path with a Hildebrand-style scale-selective fourth-difference filter matrix assembled in computational coordinates and added directly to the operator pencil as `LNS_L <- LNS_L + epsilon_av * Kav`.
- Added `src/core/build_semi_artificial_viscosity_matrix.m` to build the block-diagonal filter matrix with the cross-shaped stencil active only on rows `i = 3..Nx-2`, `j = 3..Ny-2`, leaving later BC-row replacement authoritative.
- Kept the filter self-coupled by variable only; no cross-variable artificial-viscosity coupling is introduced.
- Added `tests/test_semi_artificial_viscosity_matrix.m` to validate the exact stencil coefficients, the boundary-row exclusion rule, and the stronger damping of checkerboard-rich content relative to smooth content.
- Added `run/run_legacy4_semi_artificial_viscosity_scan.m`, which performs a synthetic legacy4 operator sensitivity sweep for `epsilon_av = [0, 0.005, 0.01, 0.0125, 0.02]` and saves a figure, MAT summary, and text log under `outputs/`.
- Scan result on the synthetic legacy4 operator-level benchmark: the checker-rich mode is the raw leading mode at `epsilon_av = 0`, but it is strongly damped by `epsilon_av >= 0.005` while the matched smooth mode changes only weakly.
- Validation run after this batch: `test_config_fields`, `test_semi_artificial_viscosity_matrix`, `run_legacy4_semi_artificial_viscosity_scan`, and `run_phase2_validation` all passed except the existing `test_matrix_sizes` skip caused by the missing root `Part3_Results.mat`.

Date: 2026-04-09
Phase: Folder cleanup and file classification

- Removed the unreferenced duplicate `AGENTS_updated.md` from the repository root so the instruction source is once again unambiguous: `AGENTS.md`.
- Removed the root-level `run.m`, which had been shadowing MATLAB's built-in `run(...)` and had already interfered with validation commands.
- Added `docs/prompts/` and moved the saved task prompt `第一轮提示词.txt` there so prompt archives no longer clutter the repository root.
- Added `paper/notes/` and moved the longer literature-comparison markdown files there so the top level of `paper/` is now mainly the reference PDFs.
- Deleted the unreferenced transient `paper/S_pages/` extracted-image directory because the source PDF `paper/S.pdf` remains in place and the page images were not used anywhere in the repository.
- Updated the structure and handoff docs to reflect the cleaned root layout and the new prompt/note locations.
- Validation after cleanup: `run(fullfile('run','run_phase2_validation.m'))` now works again without root-level `run.m` shadowing; the validation suite passed with the existing `test_matrix_sizes` skip for missing `Part3_Results.mat`.

Date: 2026-04-09
Phase: Plot text localization pass

- Unified user-facing plot titles, axis labels, and colorbar labels to Chinese on the active plotting paths in `main_double_wedge_part1.m`, `main_double_wedge_part2.m`, `main_double_wedge_part4.m`, `src/core/run_part4_primitive5.m`, `src/core/plot_boundary_map.m`, `src/core/plot_mode_u_bubble_gallery.m`, `src/core/read_phenglei_baseflow.m`, `build_boundary_masks.m`, `src/core/build_boundary_masks.m`, and `run/run_legacy4_semi_artificial_viscosity_scan.m`.
- Removed the remaining mixed-language plotting terms from visible labels, including `Legacy4`, `Sutherland`, `Jacobian`, `Christoffel`, `Laplacian`, `Re/Im`, `rad/s`, and `St`, while keeping mathematical symbols and variable notation intact.
- Validation after this batch: `run(fullfile('run','run_phase2_validation.m'))` passed again except for the existing `test_matrix_sizes` skip caused by the missing root `Part3_Results.mat`; `run_legacy4_semi_artificial_viscosity_scan` also passed and regenerated the scan figure with Chinese labels.

Date: 2026-04-09
Phase: Curvilinear derivative audit follow-up

- Investigated the reported discrepancy between Tecplot `ddx` derivatives and the Part2 physical derivatives on the full-resolution grid.
- Verified that the curvilinear metric identities and the physical first/second-derivative assembly route are mathematically self-consistent on a manufactured scalar field over a non-orthogonal, spatially varying structured mapping.
- Added `tests/test_curvilinear_scalar_operators.m` to validate `Dx`, `Dy`, `Dxx`, `Dyy`, and `Dxy` on a curved grid against exact physical derivatives; this passed with very small interior errors.
- Added the new test to `run/run_phase2_validation.m` so derivative self-consistency on a curved grid is now part of the standard validation sequence.
- Important risk still open: the root-level `main_double_wedge_part2.m` uses its own private `FD4_Uniform` implementation with 5-point one-sided boundary closures, while the shared `src/core` derivative utilities and sparse-operator tests use a different third-order boundary closure. The interior formulas agree, but current automated tests still do not directly exercise the private Part2 implementation on a real PHengLEI mesh.
- Current interpretation: a 20% pointwise mismatch against Tecplot, especially for second derivatives, is not yet sufficient evidence that the Part2 chain-rule formulas are wrong. The remaining likely causes are boundary-point comparisons, shock/non-smooth regions, and a derivative-definition mismatch between Tecplot `ddx` and the solver's structured-grid curvilinear operator.

Date: 2026-04-09
Phase: Legacy helper shadowing fix for Part4 mode diagnostics

- Investigated the reported `compute_mode_diagnostics` crash in `main_double_wedge_part4` where MATLAB rejected the newer `'StateLayout'` name-value pair.
- Root cause: MATLAB can resolve an older shadowing `compute_mode_diagnostics.m` from the current folder or another higher-priority location before the updated helper expected by `src/core/rank_mode_candidates.m`.
- Added `src/core/safe_compute_mode_diagnostics.m` as a robust wrapper. It first tries the current name-value call, and if it detects an old helper that does not accept `'StateLayout'`, it warns once and retries in legacy4 compatibility mode.
- Kept the fallback limited to `legacy4_rho_u_v_T`; for non-legacy layouts the wrapper now raises a clear error instructing the user to replace the stale helper instead of silently returning wrong diagnostics.
- Updated `src/core/rank_mode_candidates.m` and `run/run_legacy4_semi_artificial_viscosity_scan.m` to call the safe wrapper instead of calling `compute_mode_diagnostics` directly.
- Added `tests/test_rank_mode_candidates_legacy_compatibility.m` to simulate exactly this shadowing failure mode with a temporary old-style helper in the current folder; the fallback path now passes in validation.

Date: 2026-04-09
Phase: Full-resolution 270x128 local test-file execution

- Added `run/run_user_test_baseflow_fullres_legacy4.m` so the local root-level `double_wedge_baseflow.dat` test file can be run end-to-end through the legacy Part2 to Part4 path without any extra downsampling.
- Removed an unintended Statistics Toolbox requirement from `main_double_wedge_part1.m` and `main_double_wedge_part2.m` by replacing `prctile(...)` with a local percentile helper.
- Completed a full `270 x 128` legacy4 run in `outputs/mat/user_test_baseflow_270x128_fullres_legacy4/`.
- Leading mode from that run: `sigma_r ~= +2.094271e-01`, `sigma_i ~= +4.707634e-01`, `f_nd ~= 0.074924`, residual `~= 3.00e-15`, low `y` centroid `~= 0.136941`.
- The saved `u'` figures show support concentrated near the lower-wall compression region around `x ~= 20 to 26`, `y ~= 13 to 16`, not the upper-layer packet observed in the separate user-provided `812 x 382` screenshot review.
- Important limitation: this local test-file run still behaves like a smoke case, not a credible physical validation case, because preprocessing and derivative diagnostics remain poor on the current file under the current interpretation: EOS relative error `~= 4.90e-01`, wall-temperature relative mismatch `~= 2.75`, and Part2 continuity-residual max `~= 9.50e+02`.

Date: 2026-04-10
Phase: Direct primitive-five v5 production-path rebuild

- Replaced the corrupted or overgrown root `main_double_wedge_part1.m` through `main_double_wedge_part4.m` scripts with clean wrappers that now dispatch into new `v5` implementations.
- Added a direct primitive-five Part3 assembly in `Main_DoubleWedge_Part3_v5.m` with state vector `q = [u'', v'', w'', T'', p'']^T`, density eliminated through the equation of state, a pressure-evolution row, shock-localized fourth-difference semi-artificial viscosity, and a restricted top/outlet sponge.
- Added a new Part4 solve/filter/report path in `Main_DoubleWedge_Part4_v5.m` with per-row plus Gamma-based preconditioning, explicit wall-energy filtering, explicit checker filtering, region-energy reporting, and matrix-health export.
- Added `Diagnose_MatrixHealth.m` so row-norm distributions, block magnitudes, zero rows, zero columns, and preconditioning effectiveness can be checked without opening the solver manually.
- Corrected the primitive-five symmetry BC contract in `src/core/apply_structured_bc_rows.m`: `w''` is no longer forced to zero on the symmetry segment and now uses the requested Neumann row.
- Reduced-grid smoke validation on the new chain completed through Part4 in `outputs/mat/codex_v5_smoke/`.
- On that smoke case, the active-row matrix row-norm ratio dropped from about `4.7e4` before scaling to about `3.7e1` after the new preconditioner.
- Remaining limitation after this batch: the new `v5` chain is connected and much cleaner, but its physical credibility still needs to be judged on the intended real case and across a `beta` scan rather than from the reduced-grid smoke run.

Date: 2026-04-10
Phase: Full-resolution 270x128 v5 benchmark and documentation sync

- Added `run/run_user_test_baseflow_fullres_v5.m` so the local root-level `double_wedge_baseflow.dat` benchmark can be run end-to-end through the direct primitive-five `v5` chain at full `270 x 128` resolution.
- The runner now supports a quick `ReuseExistingCase` summary-only path so already-computed Part1 to Part4 artifacts can be re-summarized without rerunning the full eigensolve.
- Completed the full benchmark with `beta = 0`, `n_eigs = 8`, `sigma = 0 + 0.05i`, and `top_type = inlet`, writing artifacts under `outputs/mat/user_test_baseflow_270x128_fullres_v5/`.
- Matrix conditioning after Part4 scaling remains much healthier than before scaling on this benchmark: active-row row-norm ratio improved from about `1.36e5` to about `4.34e1`, with zero rows and zero columns both equal to `0`.
- The benchmark still did not produce a credible spectrum: the best residual among the computed modes is only about `6.69e-1`, no mode passes the residual threshold, and the reported leading eigenvalue stays pinned near the shift at `sigma ~= 2.276e-4 + 4.991e-2 i`.
- Morphology filters look less pathological than the old free-stream-polluted cases on this benchmark because the leading mode has `wall_energy_frac ~= 0.862`, `free_stream_energy_frac ~= 0.021`, `sponge_energy_frac ~= 6.0e-4`, and `checker_ratio ~= 0.755`; however, this does not rescue the run because the residual gate still fails completely.
- Baseflow and Part2 diagnostics on this benchmark remain imperfect and should stay visible during future debugging: `eos_relative_error ~= 2.60e+01`, `wall_temperature_relative_mismatch ~= 2.08e-01`, and `continuity_residual_max ~= 1.10e+02`.
- Updated the main README and handoff docs so the active production default, the new benchmark runner, and the non-credible benchmark outcome are now explicit.

Date: 2026-04-10
Phase: Descriptor-residual repair and publication-aware v5 ranking

- Diagnosed the large `Part4_v5` residuals correctly: the scaled reduced solve itself was converged (`~1e-10` scaled residuals), but the post-processing path had been deleting all `Gamma = 0` algebraic boundary columns together with the algebraic rows, so the reconstructed full-system eigenvectors violated the BC algebraic constraints and showed artificial `O(1)` residuals.
- Reworked `Main_DoubleWedge_Part4_v5.m` to solve the full scaled descriptor pencil instead of the reduced active-row-only pencil.
- Added separate saved residual channels for total, active-row, algebraic-row, and scaled residuals so future debugging can distinguish a bad eigensolve from a bad descriptor reduction.
- Added `src/core/build_filter_selection_summary.m` so strict residual/wall/checker filtering now reports explicit status instead of silently selecting every mode when the strict set is empty.
- Added `src/core/evaluate_mode_validity_tags.m` and reused those tags inside `Part4_v5` ordering, so publication-gate-passing modes are ranked ahead of compact-support pseudo-modes among the already residual-clean candidates.
- Re-ran the full `270 x 128` benchmark `Part4` solve with the repaired descriptor path. The leading mode is now `sigma_r ~= +2.824e-06`, `sigma_i ~= +4.996e-02`, total residual `~= 1.77e-08`, algebraic residual contribution `~= 1.77e-15`, `wall_energy_frac ~= 0.962`, `free_stream_energy_frac ~= 0.021`, `sponge_energy_frac ~= 0.0018`, and `checker_ratio ~= 0.082`.
- Under the current strict gates this leading benchmark mode is now marked `publication_allowed = true`; however, this must still be interpreted only as a solver-structure milestone because the local benchmark baseflow remains diagnostically weak (`eos_relative_error ~= 2.60e+01`, `continuity_residual_max ~= 1.10e+02`).

Date: 2026-04-10
Phase: No-sponge inlet-boundary correction and wall-relative diagnostic fix

- The user clarified the active baseflow BC set explicitly: top=`inlet`, south-upstream=`symmetry`, south-downstream=`wall`, east=`outlet`, with no top farfield boundary for this case.
- Reverted the mistaken temporary `farfield` top-edge assumption in the active modular defaults and benchmark runner.
- Disabled sponge damping by default on the active `v5` audit path so operator debugging is no longer entangled with sponge-driven damping.
- Fixed a real geometry-sensitive bug in `compute_mode_diagnostics.m` and `build_mode_reference_masks.m`: `peak_distance_to_wall`, `peak_distance_to_farfield`, `upper_layer_penalty`, `lower_layer`, and related wall-normal diagnostics are now computed from column-wise local wall distance instead of from the global `Y` range. This matters on the rising downstream wedge because a physically wall-attached mode there can have a large absolute `Y` value while still being very close to the local wall.
- Extended `tests/test_mode_diagnostics.m` with a tilted-wall regression to keep that interpretation correct.
- Re-ran the full `270 x 128` benchmark with `top=inlet` and `UseSponge=false`. The leading mode is now `sigma_r ~= +3.109e-05`, `sigma_i ~= +4.996e-02`, total residual `~= 5.74e-08`, algebraic residual contribution `~= 2.12e-15`, `wall_energy_frac ~= 0.888`, `free_stream_energy_frac ~= 0.0797`, `checker_ratio ~= 0.197`, and zero sponge energy.
- Quantitatively this no-sponge leading mode is wall-attached: the `u'` peak occurs at `j=8` with wall distance `~= 0.0262`, and the near-wall-band `u'` maximum (`~= 4.22e-02`) exceeds the upper-layer-band maximum (`~= 9.45e-03`). The remaining inconsistency is mainly visual: the original-style smoothed gallery still makes the upper weak stripes look more prominent than the raw amplitude peak suggests.

Date: 2026-04-10
Phase: Claude-style shock-band clipping and low-frequency shift on v5

- Reworked the active `v5` operator and filtering path to match the user's new shock-mode diagnosis rather than only changing the plots.
- `Main_DoubleWedge_Part3_v5.m` now builds an explicit shock mask from `|grad rho|`, dilates it, excludes the near-wall 10 percent strip, clips second-derivative spikes against non-shock interior statistics, recomputes `mu_x` and `mu_y` from the clipped `dMU_dT`, removes every remaining `d2MU_dT2` contribution from the primitive-five momentum and energy rows, and keeps sponge defaults at zero.
- The existing fourth-difference SAV path is still used, but its defaults are now much more aggressive and explicitly shock-focused (`epsilon = 0.05`, percentile `85`, dilation `5`).
- `Main_DoubleWedge_Part4_v5.m` now uses `sigma = 0.05 + 0.02i`, a larger Krylov dimension, whole-vector near-wall fractions, `|u'|` checker ratios, saved shock-energy fractions, and energy-normalized near-wall diagnostic plots.
- Re-ran the full local `270 x 128` benchmark under `outputs/mat/user_test_baseflow_270x128_fullres_v5_claude_fix/`.
- Solver-side result: the leading mode is no longer part of the old degenerate `St = 0.0080` shock pack. The first six selected frequencies are now `0.002046, 0.000693, 0.003458, 0.004578, 0.006240, 0.001631`, all distinct.
- Benchmark leading mode on this run: `sigma ~= +8.063e-02 + 1.285e-02 i`, residual `~= 3.77e-09`, wall-energy fraction `~= 0.972`, free-stream fraction `~= 1.35e-4`, shock-energy fraction `~= 0.193`, checker ratio `~= 0.276`.
- New operator-health signal: `Part3` now reports a shock/nonshock row-max ratio of only `~= 0.105`, so the shock rows are no longer dominating the assembled operator by raw magnitude on this benchmark.
- Remaining risk after this batch: the saved `mode_validity_report` still marks the leading mode `publication_allowed = false` because the compact-support gate rejects it, so the next debugging question may now be a filter-design question rather than an operator singularity question.

Date: 2026-04-10
Phase: Paper-A v6 production-chain consolidation

- Replaced the remaining runnable `v5`/legacy production branches with a single `v6` path rooted at `main_double_wedge_part1.m` through `main_double_wedge_part4.m`.
- `Part2_v6` now emits shared `BaseflowPhysicsAudit`, `GeometryAudit`, and `BaseflowMasks` structs; `Part3_v6` carries them into the operator MAT file; `Part4_v6` uses them directly for ranking, phase anchoring, and plotting.
- `Part4_v6` now solves the full scaled descriptor pencil with a low-frequency `sigma_triplet`, ranks by residual/checker gates plus bubble/near-wall/shock support, and emits only the reference figure contract (`Fig13`, `Fig18`, `Fig19`, `Fig22`).
- Deleted the runnable legacy4 chain, the old primitive5 transition layer, wall-relative plotting modules, and their legacy-only runners/tests so the repository no longer exposes multiple competing production paths.
- Updated `validate_config.m` so missing defaults now resolve to the Paper-A primitive-five route with top=`inlet`, no sponge, and the localized SAV defaults.
- Retained unit tests now pass under `run_phase2_validation`.
- A `270 x 128` structural smoke case under `outputs/mat/codex_v6_smoke_270x128/` completes through `Part4_v6`; current leading smoke mode is `sigma ~= -1.858e-04 + 1.984e-02 i`, residual `~= 1.22e-08`, bubble overlap `~= 2.06e-02`, near-wall energy `~= 4.68e-01`, and checker ratio `~= 9.1e-02`.
- This smoke result should still not be treated as physical validation because the local `270 x 128` baseflow remains diagnostically weak; it only confirms that the new production path, ranking logic, phase alignment, and figure contract run end-to-end.

Date: 2026-04-14
Phase: Headerless real-case reader compatibility

- Investigated a real-case `run_user_test_baseflow_fullres_v6` failure on a headerless PHengLEI export where `read_phenglei_baseflow` defaulted to `cfg.reader.n_expected_vars = 11` and raised `The Tecplot data length is not divisible by 11 columns.`
- Updated `src/core/read_phenglei_baseflow.m` so the headerless path now infers the actual column count from the parsed scalar count and the required grid-point count `I * J` when `expected_dims` is supplied.
- The reader still enforces the required first 11 fields (`x`, `y`, `z`, `rho`, `u`, `v`, `w`, `p`, `T`, `mach`, `cp`), but it now accepts extra trailing columns and reports them through `base.metadata.num_extra_vars`.
- Updated `Main_DoubleWedge_Part1_v6.m` so `Config.Nvar` records the actual imported column count instead of the fallback guess.
- Added `tests/test_read_phenglei_headerless_infer_num_vars.m` and verified both the existing multi-line-header case and the new headerless-inference case.
- Validation after this batch: `run_phase2_validation` passed with the same pre-existing `test_matrix_sizes` skip for a missing root `Part3_Results.mat`.
- Added `run/run_baseflow_import_audit_v6.m` so a real-case PHengLEI file can be audited before `Part2`: the helper reports inferred column count, extra trailing columns, pointwise-EOS error percentiles, and `p / (rho*T/(gamma*Ma^2))` statistics.
- Smoke-check on the bundled `270 x 128` file showed that the max-based EOS metric can be dominated by a small set of outlier points even when the median and 95th-percentile pressure-ratio statistics remain close to the expected equation of state. This does not remove the real-case hard gate, but it is now diagnosable without entering `Part2`.

Date: 2026-04-14
Phase: Low-memory descriptor-solve fallback

- Investigated a real-case `Part4_v6` failure where `eigs` ran out of memory on the configured descriptor shifts and `solve_paperA_descriptor_modes` returned no finite eigenpairs.
- Exposed `KrylovDimensionFloor` and `KrylovDimensionCap` through `Main_DoubleWedge_Part1_v6.m` and `run/run_user_test_baseflow_fullres_v6.m` so large cases can be launched with explicit low-memory solver settings.
- Updated `src/core/solve_paperA_descriptor_modes.m` so each shift now tries a descending list of Krylov dimensions instead of aborting after the first out-of-memory failure.
- Kept the default behavior for smaller systems unchanged; the more aggressive Krylov downscaling is only triggered for large descriptor systems or after an explicit memory failure.
- Added per-shift attempt logging and improved the final no-eigenpair error so it reports the Krylov dimensions that were tried.
- Validation after this batch: `run_phase2_validation` passed with the same pre-existing `test_matrix_sizes` skip; a reduced-grid low-memory smoke case also completed through the full `run_user_test_baseflow_fullres_v6` path.

Date: 2026-04-14
Phase: Robust real-case EOS gate for localized shock/corner outliers

- Investigated the user-side `812 x 382` `Part2_v6` hard-stop after the import audit showed a strong contradiction: `eos_relative_error ~= 3.55e-01` by pointwise max, but the bulk pressure-ratio statistics stayed close to the expected relation.
- The user then localized the worst EOS points and confirmed that they cluster mainly in the shock region and near a geometric corner rather than through the bulk flow.
- Updated `Main_DoubleWedge_Part2_v6.m` so `BaseflowPhysicsAudit` now stores `eos_relative_error_stats`, `eos_hard_gate_metric`, `eos_bad_point_count`, `eos_bad_point_fraction`, and `pressure_ratio_stats`.
- Reworked the real-case EOS hard-stop so it now uses the 95th-percentile EOS error as the bulk-pass criterion and downgrades the pointwise max EOS error to a warning-only localized-outlier signal.
- Kept the continuity gate unchanged and did not modify the Part3 or Part4 operator assembly in this batch.
- Validation after this batch: `run_phase2_validation` passed with the same pre-existing `test_matrix_sizes` skip.

Date: 2026-04-15
Phase: Part3 beta-term and pressure-closure audit without full Part4 rerun

- Continued the second-round repair pass under a new runtime constraint from the user: avoid rerunning the expensive real-case `Part4_v6` solve while still checking the high-`beta` operator path.
- Refactored `Main_DoubleWedge_Part3_v6.m` so the explicit spanwise terms are now assembled through `src/core/build_paperA_beta_terms_v6.m` instead of remaining mixed into the viscous-row helpers. This isolates the linear `-i*beta` couplings and the quadratic `-mu*beta^2` damping terms for direct structural testing.
- Added `src/core/build_paperA_pressure_closure_audit_v6.m` and now save `PressureClosureAudit` into `Part3_Results.mat` together with a new `BetaAssemblyAudit` struct. The saved audit fields expose the `pressure_scale`, `rho_from_p`, `rho_from_T`, and EOS-ratio identities directly at the `Part3` stage.
- Added three tests tailored to this cheaper second-round path: `test_paperA_beta_terms_v6.m`, `test_paperA_pressure_closure_audit_v6.m`, and `test_part3_beta_audit_smoke.m`. The smoke test stops after `Part3_v6` and confirms that the new audit structs are emitted without invoking a full `Part4` eigensolve.
- Validation after this batch: the targeted beta tests passed, and `run_phase2_validation` also passed with the same old `test_matrix_sizes` skip caused by a missing external root `Part3_Results.mat`.

Date: 2026-04-16
Phase: Part3 pressure-row regularization and independent shock-source switch

- Investigated a user-side concern that the updated pressure-evolution closure introduced `px0`, `py0`, and `div0` terms into the pressure row without any shock-aware regularization, while the viscous-derivative path was already being clipped and partly zeroed in shock zones.
- Split the shock-stabilization controls explicitly in the production config path: `use_semi_artificial_viscosity` still governs only the added `Kav` matrix, while a new top-level `use_shock_source_regularization` switch now governs the derivative/source clipping path in `Part3_v6`.
- Added `pressure_row_regularization` defaults to both `Main_DoubleWedge_Part1_v6.m` and `src/core/validate_config.m`. The new block exposes whether the weighted coefficients entering `LPu`, `LPv`, and `LPP` should be audited only, clipped against non-shock statistics, or explicitly suppressed in shock zones.
- Added `src/core/build_paperA_pressure_row_regularization_v6.m` so the pressure-row handling is isolated, testable, and saved through a new `PressureRowAudit` struct in `Part3_Results.mat`.
- Kept the default behavior intentionally conservative: the new helper clips shock-zone weighted coefficients (`px0/a^2`, `py0/a^2`, `div0/a^2`) but does not zero them unless the user explicitly enables suppression. This avoids silently deleting physically meaningful pressure-gradient terms while still damping obvious shock-driven spikes.
- Extended the retained validation suite with `test_paperA_pressure_row_regularization_v6` and updated the existing `Part3` smoke test so the new audit field is exercised without running `Part4_v6`.
- Validation after this batch: targeted pressure-row tests passed, and `run_phase2_validation` passed again with the same pre-existing `test_matrix_sizes` skip.

Date: 2026-04-16
Phase: Configurable v6 runner and manual sweep script

- Reworked `run/run_user_test_baseflow_fullres_v6.m` so it is no longer only a fixed structural benchmark helper. The runner now accepts `RunPart4`, `Part3Variant`, and explicit override fields for SAV, shock-source regularization, and pressure-row regularization.
- Added `run/run_global_stability_case_v6.m` as an editable script with a top-of-file parameter block. This gives user-side sweeps one stable manual entry point while keeping the actual run logic centralized in the shared runner.
- Kept the production wrapper unchanged: `main_double_wedge_part3.m` still dispatches to `Main_DoubleWedge_Part3_v6.m`. The archived `Main_DoubleWedge_Part3_v6_pre_pressure_fix_20260414.m` is exposed only as a comparison option through `Part3Variant`.
- Added `tests/test_run_user_test_baseflow_part3_only_v6.m` to smoke-test the new runner on a coarse `270 x 128` import without paying for `Part4_v6`.
- Validation after this batch: the new runner smoke test passed, and the retained `run_phase2_validation` suite passed again with the same old `test_matrix_sizes` skip.

Date: 2026-04-16
Phase: General sigma-shift scan support for the v6 runner

- A user-side review pointed out that the new manual script still exposed only one `SigmaShift` value even though shift scans are a recurring need during mode-selection debugging.
- Added `run/run_sigma_shift_scan_v6.m` as a general scan helper that loops over a user-supplied complex shift list, launches one case per shift through the shared configurable runner, and writes one aggregated `sigma_shift_scan_summary.mat/.txt`.
- Updated `run/run_global_stability_case_v6.m` so a non-empty `sigma_shift_list` automatically switches the script into scan mode. The script also exposes `lock_sigma_triplet_to_shift` so each scan point can either use a single matching shift or retain a shared `SigmaTriplet`.
- Added `tests/test_run_sigma_shift_scan_part3_only_v6.m` to keep this cheaper scan path covered without invoking `Part4_v6`.
- Validation after this batch: the new sigma-shift scan smoke test passed, and the retained `run_phase2_validation` suite passed again with the same pre-existing `test_matrix_sizes` skip.

Date: 2026-04-16
Phase: Reuse-safe provenance for the configurable v6 runner

- A broader code review of the new runner found that `ReuseExistingCase=true` could silently mislabel an old case as if it had been generated with the current call arguments. The old summary path reused `Part*_Results.mat` but still reported `ExpectedDims`, stride, top boundary, and `Part3Variant` from the current request.
- Hardened `run/run_user_test_baseflow_fullres_v6.m` by saving explicit immutable case identity in `RunnerCaseMetadata.mat` on fresh runs. The identity currently includes the baseflow path token, raw expected dimensions, downsampling stride, top boundary type, and actual `Part3` variant used for the saved operator chain.
- Reuse now fails hard when the current request does not match the saved case identity or the effective Part1/Part3 settings embedded in `Part1_Results.mat`. This turns silent provenance drift into an explicit `ReuseMismatch` error, which is much safer for user-side comparisons and archived screenshot interpretation.
- Added `tests/test_run_user_test_reuse_case_provenance_v6.m` to cover both the safe reuse path and the mismatch rejection path, and inserted that test into `run_phase2_validation`.
- Validation after this batch: targeted runner tests passed, and `run_phase2_validation` passed again with the same pre-existing `test_matrix_sizes` skip.

Date: 2026-04-16
Phase: Portable transfer bundle for 812x382 user-side runs

- Added a dedicated transfer artefact directory `outputs/transfer/double_wedge_812x382_portable_20260416/` so the active production solver path can be copied to another computer without manually rebuilding the dependency set.
- The transfer bundle preserves the path layout required by `setup_double_wedge_paths.m` and includes the root solver entry files, `run/`, `src/`, `tests/`, `docs/`, `paper/`, key README files, and the small local benchmark baseflow for smoke testing.
- Added `TRANSFER_README_812x382.md` inside the bundle with explicit instructions for placing the real `812 x 382` baseflow file, editing `run/run_global_stability_case_v6.m`, and choosing `RunPart4=false` first for cheaper `Part3` audits.
- Updated `AGENTS.md` so future requests to move the solver to another machine are handled by generating one dedicated transfer folder rather than by ad hoc file selection.
- Validation after this batch: confirmed the transfer directory contains the expected top-level files and subfolders, then ran `run_phase2_validation` from inside the transfer-bundle root and cleaned the temporary package-local `outputs/` it generated. No solver logic changed in this packaging step.

Date: 2026-04-16
Phase: Repository document cleanup and stale-iteration removal

- Reorganized the document layer by type instead of leaving ad hoc plan/report files at the repository root.
- Moved the still-useful long-lived notes `investigation_report.md` and `literature_shock_pollution_survey.md` under `docs/background/` and added a `docs/background/README.md` that defines the boundary between retained background notes and active coordination logs.
- Removed stale iterative documents that had already been superseded by later `docs/audit.md` entries and the current `docs/coordination/` state: `docs/DEBUG_REPORT.md`, `docs/FIX_LOG.md`, `docs/PLAN.md`, `full_code_check_and_fix_plan.md`, and `root_cause_fix_plan.md`.
- Updated `AGENTS.md`, `docs/coordination/README.md`, `docs/PROJECT_STRUCTURE.md`, and `README_codex_handoff.md` so future work follows the cleaned layout instead of recreating one-off plan/debug files.
- Cleaned the transfer bundle copy as well so it no longer carries an accidental nested `docs/docs/` duplicate.
- Validation after this batch: checked the root and `docs/` layouts directly and confirmed the transfer bundle now has one clean `docs/` tree.

Date: 2026-04-16
Phase: Part2 derivative-figure TeX label fix

- A user-side run that temporarily bypassed the real-case continuity gate revealed a separate, smaller failure in `src/core/write_baseflow_derivative_figures.m`: figure export crashed because the axis labels were written as `x^*` and `y^*`, which MATLAB's TeX interpreter does not accept during `saveas/print`.
- Updated those labels to `x^{*}` and `y^{*}` so the notation stays the same but the exported figure path is valid again.
- Validation after this batch: `checkcode` passed for the helper, and a direct smoke call to `write_baseflow_derivative_figures(...)` successfully wrote the PNG output.

Date: 2026-04-16
Phase: Part2 real-case continuity gate repair

- A user-side `812 x 382` audit showed that the real-case `Part2_v6` continuity hard-stop still failed after switching from `stride = 3` to `stride = 1`, which ruled out a purely downsampling-driven false positive.
- Rechecked the code and confirmed that the old gate was physically misnamed: `continuity_residual_max` was just `max(abs(ux + vy))`, i.e. a divergence proxy rather than the correct compressible steady mass-continuity residual.
- `src/core/build_paperA_baseflow_context.m` now records:
  - `divergence_proxy_max` and `divergence_proxy_stats`,
  - `mass_continuity_residual_max` and `mass_continuity_residual_stats`,
  - `mass_continuity_relative_max` and `mass_continuity_relative_stats`,
  - and aliases `continuity_residual_max` to the normalized mass-continuity metric for downstream compatibility.
- `Main_DoubleWedge_Part2_v6.m` now saves the new continuity diagnostics into `Part2Diagnostics` and no longer aborts the real-case path on `ux + vy`. The divergence proxy is warning-only, and the normalized mass-continuity metric is also warning-only until a trustworthy physical threshold is validated on the intended imported case.
- Added `tests/test_part2_mass_continuity_audit.m`, which uses a manufactured field with `rho*u = const`, `v = 0`, and nonzero `ux + vy` to prove that the new audit distinguishes compressible mass continuity from the old divergence proxy.
- Validation after this batch: the new unit test passed, `test_run_user_test_baseflow_part3_only_v6` still passed, and the retained `run_phase2_validation` suite passed again with only the same pre-existing `test_matrix_sizes` skip.

Date: 2026-04-16
Phase: Part4 reference-figure interpreter hardening

- A user-side `old3` run reached `Main_DoubleWedge_Part4_v6` and then failed in `write_paperA_reference_figures.m` during `saveas/print` because several titles and labels depended on fragile encoded strings or interpreter-sensitive syntax.
- Replaced the helper with a clean equivalent implementation that keeps the same reference-figure contract (`Fig13`, `Fig18`, `Fig19`, `Fig22`) but uses safer text handling:
  - eigenspectrum titles and `sigma_r / sigma_i` labels are now plain ASCII with `Interpreter='none'`,
  - the lead-marker annotations are now ASCII (`Lead`, `#k`) with `Interpreter='none'`,
  - shared field plots now use `x^{*}` / `y^{*}` and non-TeX subplot titles.
- Per the user request, no new expensive `Part4` solve was launched after this patch. Validation was limited to `checkcode` on the updated helper.

Date: 2026-04-17
Phase: Plotted-lead metadata, shock-core mask, and north-edge contract consistency

- A static code review found that `Main_DoubleWedge_Part4_v6.m` was computing `plot_leading_mode_index` as the original unsorted mode index and then overwriting it with the sorted position just before saving `Part4_Results.mat`. This made the saved metadata self-contradictory and broke downstream interpretation.
- `Main_DoubleWedge_Part4_v6.m` now keeps the sorted plotted-lead position and the original mode index as separate saved values, and the new shared helper `src/core/resolve_part4_plot_lead_position.m` resolves both the repaired format and older saved result files.
- `run/run_user_test_baseflow_fullres_v6.m` now routes all Part4 summary reads through that helper and explicitly preserves the `no_physical_plot_candidate` state instead of crashing on `NaN` indexing or silently manufacturing a plotted leader.
- `src/core/build_paperA_mode_masks.m` now intersects `shock_core` with the actual `ShockInfo.shock_mask` before handing it to the Part4 ranking logic. This keeps the hard `shock_core` gates consistent with the near-wall protection already applied by `Part3_v6`.
- `src/core/assert_realcase_boundary_contract.m` now excludes the top corners from the north-edge inlet contract when the side edges own those corners, matching the deterministic ownership already implemented in `src/core/build_boundary_masks.m`.
- Added focused regressions `test_resolve_part4_plot_lead_position`, `test_realcase_boundary_contract`, and `test_run_user_test_reuse_no_plot_lead_v6`, and extended `test_paperA_mode_masks` to lock in the new shock-core subset rule.
- Validation after this batch: the targeted no-`Part4` tests passed, and `run_phase2_validation` passed again with only the same pre-existing `test_matrix_sizes` skip.

Date: 2026-04-20
Phase: Path-precedence hardening and explicit no-plot fallback enforcement

- Investigated a reproducible workspace-shadowing issue where MATLAB resolved `run_user_test_baseflow_fullres_v6.m`, `run_phase2_validation.m`, and `setup_double_wedge_paths.m` from another repo copy even after the current workspace had been added to the path.
- Updated `setup_double_wedge_paths.m` so it now:
  - prefers the explicit/current workspace root before helper-path fallbacks,
  - compares path entries by canonicalized path token,
  - removes duplicate canonical entries,
  - and re-adds the active repo root / `run` / `src/core` / optional `tests` paths at the front of the MATLAB path.
- Carried that path contract through the active `v6` chain and reusable runner layer by switching the main `Part1`/`Part2`/`Part3`/`Part4` entry points plus the runner/scan scripts to resolve `project_root` through `setup_double_wedge_paths()` rather than through `mfilename('fullpath')` alone.
- Rechecked the `Part4` candidate-selection chain with a cheap synthetic case and confirmed the remaining gap: `rank_paperA_modes.m` still let a bubble-looking but high-residual mode flow back into `selected_for_plots` because `debug_all_modes_fallback` was feeding the same `plot_candidate_mask` used by the real plot path.
- Split that logic into two layers:
  - a debug-only ranking pool that can still keep diagnostic ordering when all residual gates fail,
  - and a true plot-eligible pool that now stays empty unless at least one residual-qualified mode exists.
- The saved selection summary is now explicit and self-consistent in the no-residual case: `status = plot_status = 'no_physical_plot_candidates'`, `num_plot_candidates = 0`, and `num_selected_modes = 0`.
- Added `tests/test_setup_double_wedge_paths_precedence.m` to reproduce the path-shadowing case against the bundled transfer copy, extended `tests/test_plot_lead_selection.m` with a high-residual bubble-support regression, and rewrote `tests/test_matrix_sizes.m` so it now reuses or generates a cheap local `Part3_Results.mat` artefact instead of depending on a historical root-level file.
- Validation after this batch: `run_phase2_validation` passed on the cheap path with the new path-precedence regression included, and the old `test_matrix_sizes` skip is now gone.

Date: 2026-04-21
Phase: Runner-level forced low-memory descriptor fallback

- A follow-up user-side report showed that the descriptor solve could still fail on the intended `812 x 382` case after downsampling because the resulting system remained below the automatic `large_system_threshold = 4e5`, even though the standard shift-invert plan was still too memory-hungry in practice.
- Added a new runner-only switch `ForceLowMemoryDescriptor` to `run/run_global_stability_case_v6.m`, `run/run_sigma_shift_scan_v6.m`, and `run/run_user_test_baseflow_fullres_v6.m`.
- The switch works by rewriting `Config.descriptor_solver.large_system_threshold` to `1` after `Part1`, which forces `solve_paperA_descriptor_modes.m` onto the existing large-system low-memory policy without changing the default thresholds for ordinary runs.
- Added `tests/test_run_user_test_force_low_memory_descriptor_v6.m` and included it in `run/run_phase2_validation.m`; the smoke test confirms that a tiny full `Part4` case still completes and records `SolveAudit.memory_policy = 'large_system_low_memory'`.

Date: 2026-04-21
Phase: Coupled-mode diagnostics, adjoint lead audit, and resolvent-path integration

- Extended `rank_paperA_modes.m` with a new coupling-audit layer that classifies modes as `bubble_centred`, `shock_bubble_coupled`, `shock_dominated`, `boundary_supported`, or compact-interior candidates instead of relying only on residual and bubble overlap.
- Added shared helper infrastructure for this research-path branch:
  - `src/core/compute_mode_support_field.m`
  - `src/core/build_mode_coupling_audit.m`
  - `src/core/build_scaled_descriptor_pencil_v6.m`
  - `src/core/compute_direct_adjoint_lead_diagnostic.m`
  - `src/core/compute_descriptor_resolvent_scan.m`
- `Main_DoubleWedge_Part4_v6.m` now saves explicit family/coupling outputs (`ModeFamily_s`, `physical_candidate_score_s`, `bubble_shock_phase_deg_s`, `bubble_shock_sync_s`, `ModeCouplingAudit`) and can optionally save `AdjointLeadAudit` plus `WavemakerLeadMap`.
- `run/run_user_test_baseflow_fullres_v6.m` now propagates these new diagnostics into `run_summary.mat/.txt`, and the runner exposes `EnableAdjointLeadDiagnostics` so reused or scanned cases can request the direct/adjoint path without changing the base operator defaults.
- Added two reusable scan entry points aligned with the current literature-driven research plan:
  - `run/run_beta_scan_v6.m`
  - `run/run_resolvent_gain_scan_v6.m`
- Added the corresponding focused regressions and smoke tests:
  - `test_mode_coupling_audit`
  - `test_direct_adjoint_lead_diagnostic`
  - `test_descriptor_resolvent_scan`
  - `test_run_beta_scan_part3_only_v6`
  - `test_run_resolvent_gain_scan_v6`
  - `test_run_user_test_reuse_coupled_summary_v6`
- Validation after this batch: the targeted new tests passed, the affected runner smokes passed, and a full local `run_phase2_validation` pass completed successfully with the expanded suite.

Date: 2026-04-21
Phase: Staged research workflow runner

- Added `run/run_research_workflow_v6.m` as a new reusable orchestration layer above the existing runner/scan functions. It packages the current recommended research sequence into one explicit workflow:
  - Part3 audits
  - regularization comparison
  - coarse beta scan
  - refined Part4
  - resolvent scan
- Added `run/run_research_workflow_case_v6.m` as the editable manual entry script so the user can switch from the structural benchmark to the intended `812 x 382` case by changing one parameter block instead of rebuilding the whole sequence from chat instructions.
- Kept `run/run_global_stability_case_v6.m` unchanged so the old one-shot and sigma-shift workflows remain available for focused debugging.
- Added `tests/test_run_research_workflow_part3_only_v6.m` and inserted it into `run_phase2_validation`; the smoke test keeps the new orchestration layer connected to the same `v6` production path without paying for a full expensive workflow.
- Validation after this batch: `checkcode` passed on the new workflow files, the dedicated smoke test passed, and a full local `run_phase2_validation` pass completed successfully.

Date: 2026-04-22
Phase: Conservative workflow defaults for low-memory intended-case runs

- Investigated a new user report that `run/run_research_workflow_case_v6.m` still exhausted memory on repeated intended-case launches.
- The issue was no longer only the descriptor solver internals; the editable workflow script itself still stacked several expensive stages by default: `stride = 1`, coarse `beta` scan with `RunBetaScanPart4 = true`, refined `Part4` enabled, resolvent enabled, and relatively aggressive `n_eigs` values.
- Reworked the case-script defaults so they now match the previously documented conservative first pass for intended `812 x 382` runs: `stride_x = stride_y = 3`, coarse `beta` scan stays on `Part3` only, refined `Part4` and resolvent start disabled, the default `beta` list and `n_eigs` values are reduced, `SigmaTriplet` is pinned to the primary shift, and the Krylov floor/cap are explicitly reduced.
- Updated `run/run_research_workflow_v6.m` so refined `Part4` adjoint diagnostics are truly optional through `EnableRefinedAdjointLeadDiagnostics` instead of being hard-wired on.
- Added `tests/test_run_research_workflow_refined_part4_no_adjoint_v6` to verify that a tiny refined workflow case can complete through `Part4` while saving an explicitly disabled `AdjointLeadAudit`.
- Validation after this batch: `checkcode` passed on the modified workflow files, the targeted workflow smoke tests passed, and a full local `run_phase2_validation` pass completed successfully with the new workflow-no-adjoint regression included.

Date: 2026-04-21
Phase: Repository cleanup for stale-copy fixtures and dead helper removal

- Reworked `tests/test_setup_double_wedge_paths_precedence.m` so it now creates a tiny synthetic stale-copy fixture under the system temp directory instead of depending on a bundled transfer-copy mirror under `outputs/transfer/`.
- This keeps the path-shadow regression intact while removing the need to ship a full second repo copy inside the main workspace.
- Deleted two unreferenced helpers, `src/core/local_run_case_script.m` and `src/core/local_run_main.m`, which were no longer called by the active runner chain, tests, or reusable helpers.
- Removed the old in-repo transfer bundle under `outputs/transfer/double_wedge_812x382_portable_20260416/` after the test no longer depended on it.
- Updated the active coordination and structure docs so the repo now treats cross-machine transfer bundles as on-demand external artefacts rather than as long-lived generated content checked into the working tree.
- Validation after this batch: `test_setup_double_wedge_paths_precedence` passed locally on the new temp-fixture path, and a full `run_phase2_validation` pass still completed successfully after the transfer-mirror removal.

Date: 2026-04-22
Phase: Sidharth 2018 benchmark contracts, operator ablations, and publication-plot gating

- Added an explicit benchmark-profile layer centered on `Sidharth2018` instead of leaving the production chain implicitly driven by scattered defaults.
- `Main_DoubleWedge_Part1_v6.m` now carries benchmark/profile metadata into `Config` and, for the `Sidharth2018` profile, defaults the literature-correction route to:
  - `use_sponge = false`
  - `use_semi_artificial_viscosity = true`
  - `use_shock_source_regularization = false`
  - `pressure_row_regularization.enabled = false`
- `Part2_v6` now saves `LiteratureBenchmarkAudit` plus `BaseflowReferenceTable`, and the baseflow context now records separation / reattachment / bubble-length / `delta99` style metrics together with a free-stream mask.
- `Part3_v6` now saves explicit post-BC operator-ablation outputs:
  - `PostBCAblationAudit`
  - `OperatorAblationTable`
  - and BC row overwrite masks from `apply_structured_bc_rows.m`
- `Part4_v6` now separates sorted lead, plot lead, and publication lead, saves component-level mode support audits (`ComponentModeAudit`), literature-facing comparison tables (`ModeReferenceTable`, `EigenReferenceTable`, `FigureCriteriaTable`), and explicit plot provenance / plot contract metadata (`PlotProvenanceAudit`, `PlotContractAudit`).
- `write_paperA_reference_figures.m` now enforces the no-physical-candidate contract: when no physical plot lead exists it writes only the spectrum and does not emit misleading lead-mode cloud figures. The same helper now also supports a separate Sidharth figure contract (`w/u/v/T/p` bubble-window figure plus `w'` gallery) when the benchmark target requests it.
- Runner/workflow integration now carries `BenchmarkProfile` end-to-end through:
  - `run_user_test_baseflow_fullres_v6.m`
  - `run_beta_scan_v6.m`
  - `run_sigma_shift_scan_v6.m`
  - `run_resolvent_gain_scan_v6.m`
  - `run_research_workflow_v6.m`
  - `run_paperA_validation_suite.m`
- Added a new preset entry point `run/run_sidharth2018_workflow_v6.m` that packages the intended code-correction order:
  - baseline Part3 audit
  - regularization ablation
  - coarse beta scan
  - refined Part4 plotting
- The runner summary path is now backward-compatible with older `Part2_Results.mat` / `Part4_Results.mat` files by backfilling missing literature tables and plot-provenance fields instead of crashing.
- Added or extended focused regressions for:
  - BC row overwrite masks
  - component-level mode-filter metrics
  - Part3 operator-ablation outputs
  - no-physical-candidate figure behavior
  - reuse-time benchmark-profile provenance
  - Sidharth preset workflow smoke execution
- Validation after this batch:
  - `run_phase2_validation` passed end-to-end on 2026-04-22 with the expanded suite.
  - A new full `270 x 128` structural case was launched under `outputs/mat/sidharth2018_structural_270x128_v6/`; it completed through `Part3` and wrote `Part1_Results.mat`, `Part2_Results.mat`, `Part3_Results.mat`, and `Diagnose_MatrixHealth_Report.mat`, but the `Part4` solve did not finish within the current 30-minute CLI timeout window, so no `Part4_Results.mat` or `run_summary.txt` is available yet from that run.

Date: 2026-04-23
Phase: Pressure-component checker gates for Sidharth disturbance plots

- Audited the pressure-row concern against the active `v6` operator and kept the corrected pressure-equation scaling intact: `G_p = D(1/a^2)` with pressure-row advection assembled as `-D(u0/a^2)Dx - D(v0/a^2)Dy` before descriptor normalization. The older visually smoother pressure field is still treated as a suppressed-acoustics comparison branch, not as the production operator.
- Fixed the confirmed mode-filter blind spot where `checker_ratio` only measured `u'`. `compute_mode_filter_metrics.m` now saves per-component checker ratios and direct `p'` support aliases so pressure-only acoustic/checker tails are visible in saved diagnostics and ranking tables.
- `rank_paperA_modes.m` now applies a pressure-quality gate for Sidharth plot eligibility, rejecting candidates with excessive `p_checker_ratio`, `p_free_stream_overlap`, `p_outlet_overlap`, `p_outlet_wall_overlap`, or `p_shock_core_overlap`. `select_paperA_plot_lead_index.m` also penalizes these pressure-tail metrics when choosing among already eligible plotted candidates.
- The default shock-source and pressure-row regularization route is now conservative and explicit: core validation, `Part3`, helper defaults, and editable workflow scripts default these mechanisms off, while explicit runner parameters still enable them for ablation studies.
- Validation after this batch:
  - targeted tests passed for mode-filter metrics, plot-lead selection, config defaults, pressure-row regularization, and reused Part4 summaries,
  - full `run_phase2_validation` passed end-to-end on 2026-04-23.

Date: 2026-04-23
Phase: Static review follow-up for descriptor recovery and plot fallback safety

- Reviewed the external static-audit claims against the active code. The descriptor scaling recovery risk was already resolved in production: `solve_paperA_descriptor_modes.m` applies `EigVecs_all = Dc * EigVecs_scaled_all` before computing physical residuals and passing modes to Part4 ranking/extraction.
- Confirmed that the active SAV path still uses the shock-localized wrapper around the fourth-difference filter and that no operator change was warranted from this review.
- Tightened the one real plot-selection issue found during review: `residual_only_fallback` now remains diagnostic-only. Modes that pass residual but fail all active checker gates no longer populate `plot_candidate_mask` or `selected_for_plots`.
- Corrected the plotted-lead selector score so `u_peak_in_bubble` is rewarded, matching the ranking score and the physical Sidharth/Paper-A plot intent.
- Added/extended `test_plot_lead_selection` coverage for checker-failed residual fallback, full plot-lead candidate pools, and the `u'` bubble-peak score sign.
- Validation after this batch:
  - targeted plot-lead and mode-filter/config/pressure-row tests passed,
  - full `run_phase2_validation` passed end-to-end after clearing a stale generated beta-scan test directory.

Date: 2026-04-23
Phase: Sidharth support-basis, phase-anchor, and lead-provenance alignment

- Rechecked the production `v6` path against a focused static review of ranking, phase anchoring, lead provenance, validity-report thresholds, plot-lead pool truncation, and free-stream mask sourcing.
- Confirmed that SAV and beta terms were not the main issue in this review; the remaining high-risk selection layer was inconsistent support/provenance semantics.
- `compute_mode_filter_metrics.m` now defaults production support fractions to `component_energy` instead of fixed `u_dominant`, and saves the active support basis in the metrics. Component-specific diagnostics remain available for `u/v/w/T/p`.
- Added `src/core/build_paperA_mode_filter_thresholds.m` so `rank_paperA_modes.m` and `Main_DoubleWedge_Part4_v6.m` consume the same resolved threshold bundle, including structural checker overrides, pressure gates, plot gates, near-wall support, gallery size, and free-stream fallback eta.
- `choose_mode_phase_factor.m`, `Main_DoubleWedge_Part4_v6.m`, and `refresh_saved_paperA_outputs.m` now pass and record `ReferenceComponent`; `w`-reference Sidharth modes anchor phase on `w'` first instead of being forced through a `u'` anchor.
- `Main_DoubleWedge_Part4_v6.m` now saves explicit `sorted_lead`, `plot_lead`, and `publication_lead` summaries, plus separate region-energy summaries and lead eigenvalue/frequency aliases. Legacy `leading_*` fields are retained only as plot-lead compatibility aliases to avoid mixing sorted and plotted semantics.
- `rank_paperA_modes.m` now exposes `plot_lead_candidate_mask` for the full eligible plotted-lead pool, while `selected_for_plots` controls only the gallery subset. `select_paperA_plot_lead_index.m` uses that full pool and now rewards, rather than penalizes, `u_peak_in_bubble` during secondary lead selection.
- `build_paperA_mode_masks.m` now consumes saved `BaseflowMasks.free_stream_mask` when present. `build_paperA_baseflow_context.m` writes this mask using configurable `mode_filter.free_stream_eta_threshold` instead of an untraceable hard-coded Part4 fallback.
- Validation after this batch intentionally did not run a new `Part4_v6` eigensolve. Targeted unit/reuse tests and Part3-only smokes passed for config defaults, support metrics, phase anchors, mode masks, plot-lead selection, no-candidate plotting, reuse summaries, beta audit, baseflow Part3-only, beta-scan Part3-only, and Sidharth workflow Part3-only.

Date: 2026-04-23
Phase: Static review follow-up for beta viscous coupling and pressure-closure audits

- Checked the external Claude review against the production `v6` chain and only changed the claims that were verifiably real in code or tests.
- Fixed the confirmed spanwise viscous cross-coupling bug in `src/core/build_paperA_beta_terms_v6.m`: `Luw` and `Lvw` now use the Stokes-consistent `-(2/3) i beta mu_x` and `-(2/3) i beta mu_y` pointwise terms instead of the old `+(1/3)` coefficients.
- Replaced the tautological pressure-closure diagnostics in `src/core/build_paperA_pressure_closure_audit_v6.m` with independent EOS-facing residuals and ratios that actually compare `rho_from_p`, `pressure_scale`, and `p0` back against `rho0`.
- Replaced the small-matrix `inv(M)` call in `src/core/build_structured_scalar_operators.m` with `M \ eye(3)` and switched `src/core/preprocess_baseflow.m` from finite-difference Sutherland derivatives to analytic `dmu_dT` and `d2mu_dT2`.
- Added regression coverage for the corrected beta-gradient coefficients and the analytic Sutherland derivatives, and updated the Part3 smoke and summary writer to consume the new pressure-closure audit fields.
- Explicitly did not change `src/core/build_uniform_fd_matrix.m` row-2 second-derivative stencils or `src/core/apply_structured_bc_rows.m` outlet rows in this batch: both remain treated as design-contract questions, not confirmed implementation bugs, and the current FD boundary behavior is already locked by `test_fd_boundary_stencils`.
- Validation after this batch:
  - targeted tests passed for beta terms, pressure closure audits, analytic Sutherland derivatives, structured scalar operators, and Part3 beta-audit smoke,
  - full `run_phase2_validation` passed end-to-end on 2026-04-23 after re-running with `setup_double_wedge_paths('IncludeTests', true)`.
