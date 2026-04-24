function Main_DoubleWedge_Part3_v6_pre_pressure_fix_20260414()
%MAIN_DOUBLEWEDGE_PART3_V6 Assemble the Paper-A-style primitive-five EVP.

    setup_double_wedge_paths();

    if exist('Part2_Results.mat', 'file') ~= 2
        error('Main_DoubleWedge_Part3_v6:MissingPart2', ...
            'Part2_Results.mat is required before running Part3.');
    end

    data = load('Part2_Results.mat');
    Config = local_normalize_config(data.Config);
    Metrics = data.Metrics;
    BaseflowPhysicsAudit = local_get_optional_field(data, 'BaseflowPhysicsAudit', struct()); %#ok<NASGU>
    GeometryAudit = local_get_optional_field(data, 'GeometryAudit', struct()); %#ok<NASGU>
    BaseflowMasks = local_get_optional_field(data, 'BaseflowMasks', struct()); %#ok<NASGU>
    if isfield(data, 'ops')
        ops = data.ops;
    else
        ops = build_structured_scalar_operators(Metrics);
    end

    Ny = data.Ny;
    Nx = data.Nx;
    N = Ny * Nx;
    Ndof = 5 * N;
    ShockInfo = local_detect_shock_region(data.dX, Ny, Nx, Config); %#ok<NASGU>
    [dX_clip, dMU_dT_clip, d2MU_dT2_clip, DerivativeClipInfo] = ...
        local_clip_baseflow_derivatives(data.dX, data.dMU_dT, data.d2MU_dT2, ShockInfo.shock_mask, Config); %#ok<NASGU>
    dX_clip.mu_x = dMU_dT_clip .* dX_clip.Tx;
    dX_clip.mu_y = dMU_dT_clip .* dX_clip.Ty;
    shock_gate = double(~ShockInfo.shock_mask(:));

    beta = Config.beta;
    R_nd = 1.0 / (Config.gamma * Config.Ma_inf^2);
    Cv_nd = Config.Cv_nd;
    fac_vis = 1.0 / Config.Re_inf;
    fac_heat = Config.gamma / (Config.Re_inf * Config.Pr);

    u0 = data.U(:);
    v0 = data.V(:);
    rho0 = data.RHO(:);
    T0 = data.TT(:);
    p0 = data.PP(:);
    mu0 = data.MU(:);
    mu_x = dX_clip.mu_x(:);
    mu_y = dX_clip.mu_y(:);
    dm = dMU_dT_clip(:);
    if Config.shock_source_regularization.suppress_viscosity_gradient_terms_in_shock
        mu_x = mu_x .* shock_gate;
        mu_y = mu_y .* shock_gate;
        dm = dm .* shock_gate;
    end

    ux0 = dX_clip.ux(:);
    uy0 = dX_clip.uy(:);
    uxx0 = dX_clip.uxx(:);
    uxy0 = dX_clip.uxy(:);
    vx0 = dX_clip.vx(:);
    vy0 = dX_clip.vy(:);
    vxx0 = dX_clip.vxx(:);
    vxy0 = dX_clip.vxy(:);
    vyy0 = dX_clip.vyy(:);
    Tx0 = dX_clip.Tx(:);
    Ty0 = dX_clip.Ty(:);
    Txx0 = dX_clip.Txx(:);
    Tyy0 = dX_clip.Tyy(:);
    div0 = dX_clip.div(:);

    D = @(x) spdiags(x(:), 0, N, N);
    Z = sparse(N, N);
    I = speye(N);
    Dx = ops.Dx;
    Dy = ops.Dy;
    Dxx = ops.Dxx;
    Dxy = ops.Dxy;
    Dyy = ops.Dyy;
    conv_op = D(u0) * Dx + D(v0) * Dy;

    rho_from_p = 1.0 ./ max(R_nd * T0, eps);
    rho_from_T = -rho0 ./ max(T0, eps);
    accel_x = u0 .* ux0 + v0 .* uy0;
    accel_y = u0 .* vx0 + v0 .* vy0;
    advect_T0 = u0 .* Tx0 + v0 .* Ty0;

    Luu = -D(rho0) * conv_op - D(rho0 .* ux0);
    Luv = -D(rho0 .* uy0);
    Luw = Z;
    LuT = D(-accel_x .* rho_from_T);
    LuP = -Dx - D(accel_x .* rho_from_p);

    Lvu = -D(rho0 .* vx0);
    Lvv = -D(rho0) * conv_op - D(rho0 .* vy0);
    Lvw = Z;
    LvT = D(-accel_y .* rho_from_T);
    LvP = -Dy - D(accel_y .* rho_from_p);

    Lwu = Z;
    Lwv = Z;
    Lww = -D(rho0) * conv_op;
    LwT = Z;
    LwP = -1i * beta * I;

    LTu = -D(rho0 .* Cv_nd .* Tx0) - D(p0) * Dx;
    LTv = -D(rho0 .* Cv_nd .* Ty0) - D(p0) * Dy;
    LTw = -1i * beta * D(p0);
    LTT = -D(rho0 .* Cv_nd) * conv_op - D(Cv_nd .* advect_T0 .* rho_from_T);
    LTP = -D(div0 + Cv_nd .* advect_T0 .* rho_from_p);

    LPu = -D(R_nd .* T0 .* rho0) * Dx;
    LPv = -D(R_nd .* T0 .* rho0) * Dy;
    LPw = -1i * beta * D(R_nd .* T0 .* rho0);
    LPT = Z;
    LPP = -D(u0) * Dx - D(v0) * Dy - D(div0);

    [Luu, Luv, Luw, LuT] = local_add_x_momentum_viscous( ...
        Luu, Luv, Luw, LuT, Dxx, Dxy, Dyy, Dx, Dy, I, ...
        mu0, mu_x, mu_y, dm, ...
        ux0, uy0, uxx0, uxy0, vx0, vy0, vxy0, vyy0, Tx0, Ty0, ...
        fac_vis, beta, D);
    [Lvu, Lvv, Lvw, LvT] = local_add_y_momentum_viscous( ...
        Lvu, Lvv, Lvw, LvT, Dxx, Dxy, Dyy, Dx, Dy, I, ...
        mu0, mu_x, mu_y, dm, ...
        ux0, uy0, uxy0, vx0, vy0, vxx0, vyy0, Tx0, Ty0, ...
        fac_vis, beta, D);
    [Lwu, Lwv, Lww] = local_add_z_momentum_viscous( ...
        Lwu, Lwv, Lww, Dxx, Dyy, Dx, Dy, I, ...
        mu0, mu_x, mu_y, fac_vis, beta, D);
    [LTu, LTv, LTw, LTT] = local_add_energy_terms( ...
        LTu, LTv, LTw, LTT, Dxx, Dyy, Dx, Dy, I, ...
        mu0, mu_x, mu_y, dm, ...
        ux0, uy0, vx0, vy0, div0, ...
        Txx0, Tyy0, Tx0, Ty0, fac_vis, fac_heat, beta, D);

    L_block = [ ...
        Luu, Luv, Luw, LuT, LuP; ...
        Lvu, Lvv, Lvw, LvT, LvP; ...
        Lwu, Lwv, Lww, LwT, LwP; ...
        LTu, LTv, LTw, LTT, LTP; ...
        LPu, LPv, LPw, LPT, LPP];
    G_block = blkdiag( ...
        D(rho0), ...
        D(rho0), ...
        D(rho0), ...
        D(rho0 .* Cv_nd), ...
        D(1.0 ./ max(R_nd .* T0 .* Config.gamma, eps)));

    P = local_block_to_interleaved_permutation(N, 5);
    LNS_L = P * L_block * P.';
    LNS_Gam = P * G_block * P.';

    sigma_sp = zeros(Ny, Nx);
    SpongeInfo = struct('max_sigma', 0.0, 'min_sigma', 0.0, 'j_cut', Ny, 'i_cut', Nx); %#ok<NASGU>
    if Config.use_sponge
        [sigma_sp, SpongeInfo] = build_restricted_sponge_profile(data.X, data.Y, ...
            'SigmaMax', Config.sponge_sigma_max, ...
            'FarfieldFraction', Config.sponge_farfield_frac, ...
            'OutletFraction', Config.sponge_outlet_frac, ...
            'Power', Config.sponge_power); %#ok<NASGU>
        LNS_L = LNS_L - spdiags(repelem(sigma_sp(:), 5), 0, Ndof, Ndof);
    end

    Kav = sparse(Ndof, Ndof); %#ok<NASGU>
    SavInfo = struct('active_rows', 0, 'active_points', 0, 'shock_mask', false(Ny, Nx), ...
        'shock_mask_dilated', false(Ny, Nx), 'shock_threshold', NaN); %#ok<NASGU>
    if Config.use_semi_artificial_viscosity && Config.semi_artificial_viscosity.epsilon > 0
        [Kav, SavInfo] = build_shock_localized_sav_matrix(dX_clip, Ny, Nx, ...
            'StateLayout', Config.state_layout, ...
            'Percentile', Config.semi_artificial_viscosity.shock_percentile, ...
            'DilationSteps', Config.semi_artificial_viscosity.dilation_steps, ...
            'ShockMask', ShockInfo.shock_mask); %#ok<NASGU>
        LNS_L = LNS_L + Config.semi_artificial_viscosity.epsilon * Kav;
    end

    [LNS_L, LNS_Gam, BCRowAudit] = apply_structured_bc_rows( ...
        LNS_L, LNS_Gam, data.BoundaryMasks, data.X, ...
        'Verbose', false, ...
        'StateLayout', Config.state_layout, ...
        'WallModel', local_get_optional_field(Config, 'wall_model', 'adiabatic')); %#ok<NASGU>

    row_norm_before = full(max(abs(LNS_L), [], 2));
    gamma_diag = full(diag(LNS_Gam));
    active_rows = abs(gamma_diag) > 0;
    row_ratio_before = max(row_norm_before(active_rows)) / ...
        max(min(row_norm_before(active_rows)), 1.0e-30);
    OperatorHealth = struct(); %#ok<NASGU>
    OperatorHealth.state_layout = Config.state_layout;
    OperatorHealth.operator_model = Config.operator_model;
    OperatorHealth.max_abs_row = max(row_norm_before);
    OperatorHealth.min_abs_row = min(row_norm_before);
    OperatorHealth.sponge_max = max(sigma_sp(:));
    OperatorHealth.sav_active_rows = SavInfo.active_rows;
    OperatorHealth.row_ratio_before = row_ratio_before;
    row_norm = full(max(abs(LNS_L), [], 2));
    shock_rows = repelem(ShockInfo.shock_mask(:), 5);
    nonshock_rows = ~shock_rows;
    if any(shock_rows)
        OperatorHealth.max_shock_row = max(row_norm(shock_rows));
    else
        OperatorHealth.max_shock_row = 0.0;
    end
    if any(nonshock_rows)
        OperatorHealth.max_nonshock_row = max(row_norm(nonshock_rows));
    else
        OperatorHealth.max_nonshock_row = 0.0;
    end
    OperatorHealth.shock_to_nonshock_row_ratio = ...
        OperatorHealth.max_shock_row / max(OperatorHealth.max_nonshock_row, 1.0e-30);
    OperatorHealth.zero_rows = find(row_norm <= 1.0e-30);
    col_norm = full(max(abs(LNS_L), [], 1)).';
    OperatorHealth.zero_cols = find(col_norm <= 1.0e-30);
    OperatorHealth.active_rows = nnz(active_rows);
    OperatorHealth.total_rows = numel(active_rows);
    OperatorAudit = OperatorHealth; %#ok<NASGU>

    X = data.X; %#ok<NASGU>
    Y = data.Y; %#ok<NASGU>
    U = data.U; %#ok<NASGU>
    V = data.V; %#ok<NASGU>
    W = data.W; %#ok<NASGU>
    TT = data.TT; %#ok<NASGU>
    RHO = data.RHO; %#ok<NASGU>
    PP = data.PP; %#ok<NASGU>
    MU = data.MU; %#ok<NASGU>
    dMU_dT = dMU_dT_clip; %#ok<NASGU>
    d2MU_dT2 = d2MU_dT2_clip; %#ok<NASGU>
    dX = dX_clip; %#ok<NASGU>
    Metrics = data.Metrics; %#ok<NASGU>
    BoundaryMasks = data.BoundaryMasks; %#ok<NASGU>
    BoundaryInfo = data.BoundaryInfo; %#ok<NASGU>
    Nx = data.Nx; %#ok<NASGU>
    Ny = data.Ny; %#ok<NASGU>

    save('Part3_Results.mat', ...
        'Config', 'X', 'Y', 'U', 'V', 'W', 'TT', 'RHO', 'PP', ...
        'MU', 'dMU_dT', 'd2MU_dT2', 'dX', 'Metrics', ...
        'BoundaryMasks', 'BoundaryInfo', 'LNS_L', 'LNS_Gam', ...
        'Kav', 'SavInfo', 'sigma_sp', 'SpongeInfo', 'BCRowAudit', ...
        'OperatorAudit', 'OperatorHealth', 'ShockInfo', 'DerivativeClipInfo', ...
        'BaseflowPhysicsAudit', 'GeometryAudit', 'BaseflowMasks', ...
        'Ndof', 'Nx', 'Ny', '-v7.3');
end

function Config = local_normalize_config(Config)
%LOCAL_NORMALIZE_CONFIG Force the v6 primitive-five production settings.

    Config.state_layout = 'primitive5_u_v_w_T_p';
    Config.operator_model = 'paperA_primitive5_direct_v6';
    if ~isfield(Config, 'n_eigs'), Config.n_eigs = 80; end
    if ~isfield(Config, 'sigma') || isempty(Config.sigma), Config.sigma = 0.05 + 0.02i; end
    if ~isfield(Config, 'sigma_triplet') || isempty(Config.sigma_triplet)
        Config.sigma_triplet = [0.00 + 0.005i, 0.00 + 0.010i, 0.00 + 0.020i, 0.02 + 0.020i, 0.05 + 0.020i];
    end
    if ~isfield(Config, 'use_sponge'), Config.use_sponge = false; end
    if ~isfield(Config, 'sponge_sigma_max'), Config.sponge_sigma_max = 0.0; end
    if ~isfield(Config, 'sponge_farfield_frac'), Config.sponge_farfield_frac = 0.0; end
    if ~isfield(Config, 'sponge_outlet_frac'), Config.sponge_outlet_frac = 0.0; end
    if ~isfield(Config, 'sponge_power'), Config.sponge_power = 4; end
    if ~isfield(Config, 'use_semi_artificial_viscosity'), Config.use_semi_artificial_viscosity = true; end
    if ~isfield(Config, 'semi_artificial_viscosity')
        Config.semi_artificial_viscosity = struct();
    end
    if ~isfield(Config.semi_artificial_viscosity, 'epsilon')
        Config.semi_artificial_viscosity.epsilon = 5.0e-2;
    end
    if ~isfield(Config.semi_artificial_viscosity, 'shock_percentile')
        Config.semi_artificial_viscosity.shock_percentile = 85.0;
    end
    if ~isfield(Config.semi_artificial_viscosity, 'dilation_steps')
        Config.semi_artificial_viscosity.dilation_steps = 5;
    end
    if ~isfield(Config.semi_artificial_viscosity, 'near_wall_fraction')
        Config.semi_artificial_viscosity.near_wall_fraction = 0.10;
    end
    if ~isfield(Config, 'shock_source_regularization')
        Config.shock_source_regularization = struct();
    end
    if ~isfield(Config.shock_source_regularization, 'clip_percentile')
        Config.shock_source_regularization.clip_percentile = 95.0;
    end
    if ~isfield(Config.shock_source_regularization, 'dmu_clip_percentile')
        Config.shock_source_regularization.dmu_clip_percentile = 95.0;
    end
    if ~isfield(Config.shock_source_regularization, 'zero_second_derivatives_in_shock')
        Config.shock_source_regularization.zero_second_derivatives_in_shock = true;
    end
    if ~isfield(Config.shock_source_regularization, 'suppress_viscosity_gradient_terms_in_shock')
        Config.shock_source_regularization.suppress_viscosity_gradient_terms_in_shock = true;
    end
    if ~isfield(Config, 'beta')
        Config.beta = 0.0;
    end
    if ~isfield(Config, 'wall_model') || isempty(Config.wall_model)
        Config.wall_model = 'adiabatic';
    end
    Config.wall_model = normalize_wall_model(Config.wall_model, ...
        'ErrorIdentifier', 'Main_DoubleWedge_Part3_v6_pre_pressure_fix_20260414:WallModel');
    if ~isfield(Config, 'T_wall') && isfield(Config, 'T_wall_nd')
        Config.T_wall = Config.T_wall_nd * Config.T_inf;
    elseif ~isfield(Config, 'T_wall')
        Config.T_wall = 298.0;
    end
    Config.T_wall_nd = Config.T_wall / Config.T_inf;
    if ~isfield(Config, 'plot_contract')
        Config.plot_contract = 'paperA_reference_mainset_v1';
    end
    if ~isfield(Config, 'plot_debug_fields')
        Config.plot_debug_fields = false;
    end
    if ~isfield(Config, 'plot_debug_mode_diagnosis')
        Config.plot_debug_mode_diagnosis = false;
    end
    if ~isfield(Config, 'plot_wall_relative_figures')
        Config.plot_wall_relative_figures = false;
    end
    Config.epsilon_art = Config.semi_artificial_viscosity.epsilon;
end

function value = local_get_optional_field(S, name, default_value)
%LOCAL_GET_OPTIONAL_FIELD Return a struct field when it exists.

    if isstruct(S) && isfield(S, name)
        value = S.(name);
    else
        value = default_value;
    end
end

function P = local_block_to_interleaved_permutation(N, nvar)
%LOCAL_BLOCK_TO_INTERLEAVED_PERMUTATION Map block ordering to node-interleaved ordering.

    Ndof = N * nvar;
    rows = zeros(Ndof, 1);
    cols = (1:Ndof).';
    ptr = 0;
    for var = 1:nvar
        for node = 1:N
            ptr = ptr + 1;
            rows(ptr) = (node - 1) * nvar + var;
        end
    end
    P = sparse(rows, cols, 1, Ndof, Ndof);
end

function [Luu, Luv, Luw, LuT] = local_add_x_momentum_viscous( ...
        Luu, Luv, Luw, LuT, Dxx, Dxy, Dyy, Dx, Dy, I, ...
        mu0, mu_x, mu_y, dm, ...
        ux0, uy0, uxx0, uxy0, vx0, vy0, vxy0, vyy0, Tx0, Ty0, ...
        fac_vis, beta, D)
%LOCAL_ADD_X_MOMENTUM_VISCOUS Add the primitive-five x-momentum viscous terms.

    Luu = Luu + fac_vis * ( ...
        D((4/3) * mu0) * Dxx + D(mu0) * Dyy - D(mu0 * beta^2) * I + ...
        D((4/3) * mu_x) * Dx + D(mu_y) * Dy);
    Luv = Luv + fac_vis * ( ...
        D((1/3) * mu0) * Dxy + D((-2/3) * mu_x) * Dy + D(mu_y) * Dx);
    Luw = Luw + fac_vis * (D(1i * beta * mu0 / 3.0) * Dx + D(1i * beta * mu_x / 3.0));

    strain_x = (4/3) * ux0 - (2/3) * vy0;
    shear_xy = uy0 + vx0;
    LuT = LuT + fac_vis * ( ...
        D(dm .* strain_x) * Dx + D(dm .* shear_xy) * Dy + ...
        D(dm .* ((4/3) * uxx0 - (2/3) * vxy0 + uxy0 + vyy0)));
end

function [Lvu, Lvv, Lvw, LvT] = local_add_y_momentum_viscous( ...
        Lvu, Lvv, Lvw, LvT, Dxx, Dxy, Dyy, Dx, Dy, I, ...
        mu0, mu_x, mu_y, dm, ...
        ux0, uy0, uxy0, vx0, vy0, vxx0, vyy0, Tx0, Ty0, ...
        fac_vis, beta, D)
%LOCAL_ADD_Y_MOMENTUM_VISCOUS Add the primitive-five y-momentum viscous terms.

    Lvu = Lvu + fac_vis * ( ...
        D((1/3) * mu0) * Dxy + D(mu_x) * Dy + D((-2/3) * mu_y) * Dx);
    Lvv = Lvv + fac_vis * ( ...
        D(mu0) * Dxx + D((4/3) * mu0) * Dyy - D(mu0 * beta^2) * I + ...
        D(mu_x) * Dx + D((4/3) * mu_y) * Dy);
    Lvw = Lvw + fac_vis * (D(1i * beta * mu0 / 3.0) * Dy + D(1i * beta * mu_y / 3.0));

    shear_xy = vx0 + uy0;
    strain_y = (4/3) * vy0 - (2/3) * ux0;
    LvT = LvT + fac_vis * ( ...
        D(dm .* shear_xy) * Dx + D(dm .* strain_y) * Dy + ...
        D(dm .* (vxx0 + (1/3) * uxy0 + (4/3) * vyy0)));
end

function [Lwu, Lwv, Lww] = local_add_z_momentum_viscous( ...
        Lwu, Lwv, Lww, Dxx, Dyy, Dx, Dy, I, ...
        mu0, mu_x, mu_y, fac_vis, beta, D)
%LOCAL_ADD_Z_MOMENTUM_VISCOUS Add the primitive-five z-momentum viscous terms.

    Lwu = Lwu + fac_vis * (D(1i * beta * mu0 / 3.0) * Dx + D(1i * beta * mu_x));
    Lwv = Lwv + fac_vis * (D(1i * beta * mu0 / 3.0) * Dy + D(1i * beta * mu_y));
    Lww = Lww + fac_vis * ( ...
        D(mu0) * Dxx + D(mu0) * Dyy - D((4/3) * mu0 * beta^2) * I + ...
        D(mu_x) * Dx + D(mu_y) * Dy);
end

function [LTu, LTv, LTw, LTT] = local_add_energy_terms( ...
        LTu, LTv, LTw, LTT, Dxx, Dyy, Dx, Dy, I, ...
        mu0, mu_x, mu_y, dm, ...
        ux0, uy0, vx0, vy0, div0, ...
        Txx0, Tyy0, Tx0, Ty0, fac_vis, fac_heat, beta, D)
%LOCAL_ADD_ENERGY_TERMS Add heat conduction and viscous-dissipation terms.

    Cu_phi = fac_vis * mu0 .* (4.0 * ux0 - (4.0 / 3.0) * div0);
    Cv_phi = fac_vis * mu0 .* (4.0 * vy0 - (4.0 / 3.0) * div0);
    Cuv_phi = fac_vis * 2.0 * mu0 .* (uy0 + vx0);
    Phi0 = 2.0 * (ux0.^2 + vy0.^2) + (uy0 + vx0).^2 - (2.0 / 3.0) * div0.^2;

    LTu = LTu + D(Cu_phi) * Dx + D(Cuv_phi) * Dy;
    LTv = LTv + D(Cuv_phi) * Dx + D(Cv_phi) * Dy;
    LTw = LTw;
    LTT = LTT + fac_heat * ( ...
        D(mu0) * Dxx + D(mu0) * Dyy - D(mu0 * beta^2) * I + ...
        D(mu_x) * Dx + D(mu_y) * Dy + ...
        D(dm .* (Txx0 + Tyy0))) + ...
        D(fac_vis * dm .* Phi0);
end

function info = local_detect_shock_region(dX, Ny, Nx, Config)
%LOCAL_DETECT_SHOCK_REGION Build the dilated shock mask used by the v5 operator.

    grad_rho = hypot(dX.rhox, dX.rhoy);
    shock_threshold = local_percentile(grad_rho(:), ...
        Config.semi_artificial_viscosity.shock_percentile);
    shock_raw = grad_rho > shock_threshold;
    shock_mask = shock_raw;
    for k = 1:round(Config.semi_artificial_viscosity.dilation_steps)
        shock_mask = local_dilate_mask(shock_mask);
    end

    near_wall_rows = min(Ny, max(1, round(Ny * Config.semi_artificial_viscosity.near_wall_fraction)));
    near_wall_mask = false(Ny, Nx);
    near_wall_mask(1:near_wall_rows, :) = true;
    shock_mask(near_wall_mask) = false;

    info = struct();
    info.grad_rho = grad_rho;
    info.shock_threshold = shock_threshold;
    info.shock_raw = shock_raw;
    info.shock_mask = shock_mask;
    info.near_wall_rows = near_wall_rows;
    info.coverage_fraction = nnz(shock_mask) / max(numel(shock_mask), 1);
end

function [dX_clip, dmu_clip, d2mu_clip, report] = local_clip_baseflow_derivatives(dX, dmu, d2mu, shock_mask, Config)
%LOCAL_CLIP_BASEFLOW_DERIVATIVES Clamp shock-driven second-derivative spikes.

    dX_clip = dX;
    dmu_clip = dmu;
    d2mu_clip = d2mu;
    report = struct();
    report.fields = struct();
    clip_percentile = Config.shock_source_regularization.clip_percentile;
    dmu_clip_percentile = Config.shock_source_regularization.dmu_clip_percentile;
    zero_second_derivatives = logical(Config.shock_source_regularization.zero_second_derivatives_in_shock);

    fields_to_clip = {'uxx', 'uyy', 'uxy', 'vxx', 'vyy', 'vxy', ...
        'Txx', 'Tyy', 'Txy', 'rhoxx', 'rhoyy'};
    for k = 1:numel(fields_to_clip)
        field_name = fields_to_clip{k};
        if ~isfield(dX_clip, field_name)
            continue;
        end
        [dX_clip.(field_name), clip_hi, n_clipped] = local_clip_field(dX_clip.(field_name), shock_mask, clip_percentile);
        n_zeroed = 0;
        if zero_second_derivatives
            n_zeroed = nnz(shock_mask);
            dX_clip.(field_name)(shock_mask) = 0.0;
        end
        report.fields.(field_name) = struct('clip_abs', clip_hi, 'num_clipped', n_clipped, 'num_zeroed', n_zeroed);
    end

    [dmu_clip, dmu_hi, n_dmu] = local_clip_field(dmu_clip, shock_mask, dmu_clip_percentile);
    [d2mu_clip, d2mu_hi, n_d2mu] = local_clip_field(d2mu_clip, shock_mask, clip_percentile);
    n_d2mu_zeroed = 0;
    if zero_second_derivatives
        n_d2mu_zeroed = nnz(shock_mask);
        d2mu_clip(shock_mask) = 0.0;
    end
    report.dMU_dT = struct('clip_abs', dmu_hi, 'num_clipped', n_dmu);
    report.d2MU_dT2 = struct('clip_abs', d2mu_hi, 'num_clipped', n_d2mu, 'num_zeroed', n_d2mu_zeroed);
end

function [field_out, clip_hi, n_clipped] = local_clip_field(field_in, shock_mask, pct)
%LOCAL_CLIP_FIELD Clip one derivative field using non-shock statistics.

    field_out = field_in;
    interior_values = abs(field_in(~shock_mask));
    interior_values = interior_values(isfinite(interior_values));
    if numel(interior_values) <= 10
        clip_hi = inf;
        n_clipped = 0;
        return;
    end

    clip_hi = local_percentile(interior_values, pct);
    if ~(isfinite(clip_hi) && clip_hi > 0)
        clip_hi = max(interior_values);
    end
    if ~(isfinite(clip_hi) && clip_hi > 0)
        clip_hi = inf;
        n_clipped = 0;
        return;
    end

    clip_mask = shock_mask & (abs(field_in) > clip_hi);
    field_out(clip_mask) = sign(field_in(clip_mask)) .* clip_hi;
    n_clipped = nnz(clip_mask);
end

function mask_out = local_dilate_mask(mask_in)
%LOCAL_DILATE_MASK Apply one 5-point logical dilation step.

    mask_out = mask_in | circshift(mask_in, [1, 0]) | circshift(mask_in, [-1, 0]) | ...
        circshift(mask_in, [0, 1]) | circshift(mask_in, [0, -1]);
end

function value = local_percentile(data_value, pct)
%LOCAL_PERCENTILE Toolbox-free percentile helper.

    data_value = sort(data_value(:));
    if isempty(data_value)
        value = 0.0;
        return;
    end

    pct = min(max(pct, 0.0), 100.0);
    idx = 1 + (numel(data_value) - 1) * pct / 100.0;
    i_lo = floor(idx);
    i_hi = ceil(idx);
    if i_lo == i_hi
        value = data_value(i_lo);
    else
        w_hi = idx - i_lo;
        w_lo = 1.0 - w_hi;
        value = w_lo * data_value(i_lo) + w_hi * data_value(i_hi);
    end
end
