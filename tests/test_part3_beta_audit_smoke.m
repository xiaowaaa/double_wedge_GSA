function test_part3_beta_audit_smoke()
%TEST_PART3_BETA_AUDIT_SMOKE Run a tiny Part3 assembly and verify saved beta audits.

    project_root = fileparts(fileparts(mfilename('fullpath')));
    addpath(project_root);
    addpath(fullfile(project_root, 'run'));
    addpath(fullfile(project_root, 'src', 'core'));

    tmp_dir = fullfile(project_root, 'outputs', 'mat', 'test_part3_beta_audit_smoke');
    if exist(tmp_dir, 'dir') == 7
        rmdir(tmp_dir, 's');
    end
    mkdir(tmp_dir);

    old_dir = pwd;
    cleanup_dir = onCleanup(@() cd(old_dir)); %#ok<NASGU>
    cd(tmp_dir);

    Nx = 9;
    Ny = 7;
    [X, Y] = meshgrid(linspace(0.0, 1.0, Nx), linspace(0.0, 0.4, Ny));
    U = 1.0 + 0.05 * X;
    V = 0.02 * Y;
    W = zeros(Ny, Nx);
    TT = 1.0 + 0.03 * X;
    RHO = 1.0 + 0.01 * Y;

    cfg = config_case();
    cfg.reader.expected_dims = [Nx, Ny];
    cfg.reader.stride_x = 1;
    cfg.reader.stride_y = 1;
    cfg.boundary_map = struct('south', 'mixed_symmetry_wall', 'north', 'inlet', 'west', 'inlet', 'east', 'outlet');
    cfg.x_hinge = cfg.geometry.x_hinge;
    cfg.gamma = cfg.flow.gamma;
    cfg.Ma_inf = cfg.flow.Ma_inf;
    cfg.Re_inf = cfg.flow.Re_inf;
    cfg.Pr = cfg.flow.Pr;
    cfg.Cv_nd = cfg.flow.Cv;
    cfg.beta = 0.8;

    PP = (1.0 / (cfg.gamma * cfg.Ma_inf^2)) .* RHO .* TT;
    MU = ones(Ny, Nx);
    dMU_dT = zeros(Ny, Nx);
    d2MU_dT2 = zeros(Ny, Nx);

    Metrics = compute_structured_metrics(X, Y);
    ops = build_structured_scalar_operators(Metrics);
    dX = struct();
    dX.ux = reshape(ops.Dx * U(:), Ny, Nx);
    dX.uy = reshape(ops.Dy * U(:), Ny, Nx);
    dX.uxx = reshape(ops.Dxx * U(:), Ny, Nx);
    dX.uxy = reshape(ops.Dxy * U(:), Ny, Nx);
    dX.uyy = reshape(ops.Dyy * U(:), Ny, Nx);
    dX.vx = reshape(ops.Dx * V(:), Ny, Nx);
    dX.vy = reshape(ops.Dy * V(:), Ny, Nx);
    dX.vxx = reshape(ops.Dxx * V(:), Ny, Nx);
    dX.vxy = reshape(ops.Dxy * V(:), Ny, Nx);
    dX.vyy = reshape(ops.Dyy * V(:), Ny, Nx);
    dX.wx = reshape(ops.Dx * W(:), Ny, Nx);
    dX.wy = reshape(ops.Dy * W(:), Ny, Nx);
    dX.wxx = reshape(ops.Dxx * W(:), Ny, Nx);
    dX.wxy = reshape(ops.Dxy * W(:), Ny, Nx);
    dX.wyy = reshape(ops.Dyy * W(:), Ny, Nx);
    dX.Tx = reshape(ops.Dx * TT(:), Ny, Nx);
    dX.Ty = reshape(ops.Dy * TT(:), Ny, Nx);
    dX.Txx = reshape(ops.Dxx * TT(:), Ny, Nx);
    dX.Txy = reshape(ops.Dxy * TT(:), Ny, Nx);
    dX.Tyy = reshape(ops.Dyy * TT(:), Ny, Nx);
    dX.rhox = reshape(ops.Dx * RHO(:), Ny, Nx);
    dX.rhoy = reshape(ops.Dy * RHO(:), Ny, Nx);
    dX.rhoxx = reshape(ops.Dxx * RHO(:), Ny, Nx);
    dX.rhoxy = reshape(ops.Dxy * RHO(:), Ny, Nx);
    dX.rhoyy = reshape(ops.Dyy * RHO(:), Ny, Nx);
    dX.px = reshape(ops.Dx * PP(:), Ny, Nx);
    dX.py = reshape(ops.Dy * PP(:), Ny, Nx);
    dX.pxx = reshape(ops.Dxx * PP(:), Ny, Nx);
    dX.pxy = reshape(ops.Dxy * PP(:), Ny, Nx);
    dX.pyy = reshape(ops.Dyy * PP(:), Ny, Nx);
    dX.div = dX.ux + dX.vy;
    dX.mu_x = zeros(Ny, Nx);
    dX.mu_y = zeros(Ny, Nx);

    [BoundaryMasks, BoundaryInfo] = build_boundary_masks(X, Y, cfg, 'Verbose', false);
    BaseValidation = struct('eos_relative_error', 0.0, 'wall_temperature_relative_mismatch', 0.0, 'bottom_split_ok', true);
    [BaseflowPhysicsAudit, GeometryAudit, BaseflowMasks] = build_paperA_baseflow_context( ...
        X, Y, U, V, RHO, dX, BoundaryMasks, cfg, BaseValidation);

    save('Part2_Results.mat', ...
        'cfg', 'Metrics', 'ops', 'dX', 'BoundaryMasks', 'BoundaryInfo', ...
        'BaseflowPhysicsAudit', 'GeometryAudit', 'BaseflowMasks', ...
        'X', 'Y', 'U', 'V', 'W', 'TT', 'RHO', 'PP', 'MU', 'dMU_dT', 'd2MU_dT2', ...
        'Nx', 'Ny', '-v7.3');
    movefile('Part2_Results.mat', 'Part2_Results_tmp.mat');
    data = load('Part2_Results_tmp.mat');
    data.Config = cfg; %#ok<STRNU>
    save('Part2_Results.mat', '-struct', 'data', '-v7.3');
    delete('Part2_Results_tmp.mat');

    Main_DoubleWedge_Part3_v6();
    part3 = load('Part3_Results.mat');

    assert(isfield(part3, 'BetaAssemblyAudit'), 'Part3 should save BetaAssemblyAudit.');
    assert(isfield(part3, 'PressureClosureAudit'), 'Part3 should save PressureClosureAudit.');
    assert(isfield(part3, 'PressureRowAudit'), 'Part3 should save PressureRowAudit.');
    assert(isfield(part3, 'PostBCAblationAudit'), 'Part3 should save PostBCAblationAudit.');
    assert(isfield(part3, 'OperatorAblationTable') && istable(part3.OperatorAblationTable), ...
        'Part3 should save the operator ablation summary table.');
    assert(abs(part3.BetaAssemblyAudit.beta - cfg.beta) < 1.0e-12, ...
        'Saved beta audit should record the configured beta.');
    assert(part3.BetaAssemblyAudit.has_spanwise_terms, ...
        'Nonzero beta should report active spanwise terms.');
    assert(part3.PostBCAblationAudit.beta.has_effective_post_bc_terms, ...
        'The post-BC audit should confirm beta terms survive BC overwrite.');
    assert(any(strcmp(cellstr(part3.OperatorAblationTable.mechanism), 'beta')), ...
        'The saved ablation table should include one beta entry.');
    assert(part3.PressureClosureAudit.rho_from_p_gamma_residual_max < 1.0e-10, ...
        'Pressure closure audit should preserve rho_from_p = gamma * pressure_scale.');
    assert(isfield(part3.PressureRowAudit, 'fields') && isfield(part3.PressureRowAudit.fields, 'px'), ...
        'Pressure-row audit should expose per-field shock statistics.');

    fprintf('[test_part3_beta_audit_smoke] PASS\n');
end
