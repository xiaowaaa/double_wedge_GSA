# Hypersonic Double-Wedge PHengLEI Bi-Global LNS (MATLAB 2020a)

## Project Status

This repository now runs on a single Paper-A-aligned MATLAB production chain for three-dimensional spanwise-periodic bi-global/global stability analysis of a two-dimensional PHengLEI double-wedge baseflow. The active implementation is organized around:

- explicit structured-grid boundary masks
- direct primitive-five perturbation variables on the active `v6` production path
- scaled descriptor generalized eigenvalue solves with low-frequency shift families
- physics-first mode ranking based on bubble/near-wall/shock support
- reference-style result figures with energy-normalized leading-mode `u'` and `v'`
- reproducible outputs under `outputs/`

The root production chain is `main_double_wedge_part1.m` through `main_double_wedge_part4.m`, and those entry files now dispatch into `Main_DoubleWedge_Part*_v6.m`.

The current workspace does not contain a bundled `baseflow/` directory. A root-level `double_wedge_baseflow.dat` test file is present, and the active benchmark/validation runners are now:

- `run/run_user_test_baseflow_fullres_v6.m`
- `run/run_paperA_validation_suite.m`

This local `I=270`, `J=128` file remains a structural benchmark dataset rather than the final physical case.

## Governing Convention

The entire project uses

`q'(x,y,z,t) = qhat(x,y) * exp(sigma*t + i*beta*z)`

with

- `sigma = sigma_r + i*sigma_i`
- `sigma = -i*omega`
- `beta = 2*pi/lambda_z`

The active production-path unknowns are the primitive perturbation variables

`q = [u', v', w', T', p']^T`

with `rho'` eliminated through the equation of state inside the current direct `v6` Part3 assembly.

Older legacy4 and transitional production paths have been removed from the runnable codebase.

## Physical Scope

- Baseflow: 2D steady PHengLEI solution
- Perturbation: 3D spanwise-periodic
- Free stream: `Ma = 7`, `Re = 1e5`, `T_inf = 191 K`
- Wall thermal model:
  - `wall_model = 'isothermal'`, default `Tw = 298 K`
  - `wall_model = 'adiabatic'`

The phrase "adiabatic wall 298 K" is treated as physically ambiguous. The code does not conflate the two models.

## Boundary Interpretation

Default structured-grid interpretation:

- bottom, `x < 0`: symmetry
- bottom, `x >= 0`: wall
- left: inlet
- right: outlet
- top: inlet for the active double-wedge case

Expected `boundary_condition.hypara` mapping:

- `2 => wall / solid surface`
- `3 => symmetry`
- `5 => inflow`
- `6 => outflow / extrapolation`

The code does not blindly trust these labels. It first builds geometry-based masks from the imported structured grid and then cross-checks any optional hypara file.

## Repository Layout

- `run/config_case.m`
  Central case configuration, including file paths, physics, boundary options, eigensolver settings and quality checks.

- `run/run_all.m`
  Main entry point. It reads the baseflow, preprocesses it, and then continues through the later solver stages when those stage files are present.

- `src/core/read_phenglei_baseflow.m`
  Robust PHengLEI Tecplot POINT reader with header parsing, headerless fallback, downsampling and boundary-audit plotting.

- `src/core/preprocess_baseflow.m`
  Baseflow integrity checks, Sutherland-law derivatives, EOS consistency, bubble/shock seed masks and wall-model validation.

- `src/core/*.m`
  Metrics, geometry, LNS assembly, BC/sponge application, scaling, eigensolve, reconstruction and post-processing modules.

- `tests/*.m`
  Validation scaffolding and pipeline checks.

- `docs/audit.md`
  Running audit trail of assumptions, blocking findings and major changes.

- `docs/coordination/*.md`
  Cross-account handoff notes, current status, work queue and completed-task log.

- `outputs/`
  All logs, figures and MAT artifacts.

## Phase-Oriented Workflow

### Phase 1: audit and reader sanity

1. Set `cfg.io.baseflow_file`.
2. Optionally set `cfg.io.boundary_file`.
3. Run `addpath('run'); addpath(fullfile('src','core')); cfg = config_case();`
4. Run `base = read_phenglei_baseflow(cfg);`
5. Run `base = preprocess_baseflow(base, cfg);`

This phase writes a boundary-audit figure to `outputs/figs/`.

### Phase 2: validation scaffolding

Planned validation sequence for this repository:

1. `tests/test_config_fields.m`
2. `run/run_phase2_validation.m`
3. `run/run_user_test_baseflow_fullres_v6.m`

### Phase 3: blocking fixes

Only after configuration and boundary mapping are validated:

- fix missing config fields
- fix boundary-mask / BC mismatches
- fix BC logic that depends only on raw edge indices
- disable invalid physical filtering paths when reference scales are missing

### Phase 4: eigensolve and diagnostics

The full pipeline will:

- assemble the active bi-global LNS operator on the chosen state layout
- apply BC rows and sponge terms directly to the operator pencil
- solve multiple shift candidates with `eigs`
- rank candidate modes by residual and physical quality
- reconstruct primitive perturbations
- save spectra, mode contours and quality reports

## How To Run

From the project root:

```matlab
addpath(fullfile(pwd, 'run'));
addpath(fullfile(pwd, 'src', 'core'));

summary = run_user_test_baseflow_fullres_v5();
```

This benchmark runner uses the local `double_wedge_baseflow.dat` file at full `270 x 128` resolution, writes a dedicated case directory under `outputs/mat/`, and saves `Part1_Results.mat` through `Part4_Results.mat` plus matrix-health and summary artifacts.

For modular manual control:

```matlab
addpath(fullfile(pwd, 'run'));
addpath(fullfile(pwd, 'src', 'core'));

cfg = config_case();
cfg.io.baseflow_file = 'C:/absolute/path/to/your/phenglei_double_wedge_baseflow.dat';
cfg.io.boundary_file = 'C:/absolute/path/to/boundary_condition.hypara';

results = run_all(cfg);
```

If the downstream stage files are not all installed yet, `run_all` stops after preprocessing, saves the stage MAT files, and reports which later modules are still missing.

## Important Assumptions

- The PHengLEI export is Tecplot ASCII with pointwise ordering compatible with `reshape(...,[I,J]).'`.
- The structured-grid convention is explicitly `M(j,i)`.
- `w` in the baseflow should be near zero for a 2D steady solution; it is still retained and checked.
- No smoothing is allowed to "fix" checkerboard or noisy eigenmodes.
- `cfg.flow.U_ref` and `cfg.flow.L_ref` become mandatory if physical frequency filtering is enabled.

## Outputs

All artifacts are written under `outputs/`:

- `outputs/figs/`
  boundary maps, baseflow plots, eigenspectra and mode figures

- `outputs/mat/`
  stage MAT files and final results

- `outputs/logs/`
  diary and text logs

For a new Codex session, start with `README_codex_handoff.md`.

## Next Modules

The next implementation batches populate:

- metrics and dual finite-volume geometry
- active LNS operator assembly on the selected state layout
- BC and sponge enforcement
- scaling and linearization verification
- eigensolve, mode selection, plotting and diagnostics

