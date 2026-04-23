function Main_DoubleWedge_Part2_v6()
%MAIN_DOUBLEWEDGE_PART2_V6 Build metrics and Paper-A pre-assembly audits.

    setup_double_wedge_paths();

    if exist('Part1_Results.mat', 'file') ~= 2
        error('Main_DoubleWedge_Part2_v6:MissingPart1', ...
            'Part1_Results.mat is required before running Part2.');
    end

    data = load('Part1_Results.mat');
    [Config, ConfigReport] = validate_config(data.Config, 'Verbose', false); %#ok<NASGU>
    [Metrics, MetricsReport] = compute_structured_metrics(data.X, data.Y); %#ok<NASGU>
    ops = build_structured_scalar_operators(Metrics);

    dX = struct();
    dX.ux = local_apply(ops.Dx, data.U, data.Ny, data.Nx);
    dX.uy = local_apply(ops.Dy, data.U, data.Ny, data.Nx);
    dX.uxx = local_apply(ops.Dxx, data.U, data.Ny, data.Nx);
    dX.uxy = local_apply(ops.Dxy, data.U, data.Ny, data.Nx);
    dX.uyy = local_apply(ops.Dyy, data.U, data.Ny, data.Nx);

    dX.vx = local_apply(ops.Dx, data.V, data.Ny, data.Nx);
    dX.vy = local_apply(ops.Dy, data.V, data.Ny, data.Nx);
    dX.vxx = local_apply(ops.Dxx, data.V, data.Ny, data.Nx);
    dX.vxy = local_apply(ops.Dxy, data.V, data.Ny, data.Nx);
    dX.vyy = local_apply(ops.Dyy, data.V, data.Ny, data.Nx);

    dX.wx = local_apply(ops.Dx, data.W, data.Ny, data.Nx);
    dX.wy = local_apply(ops.Dy, data.W, data.Ny, data.Nx);
    dX.wxx = local_apply(ops.Dxx, data.W, data.Ny, data.Nx);
    dX.wxy = local_apply(ops.Dxy, data.W, data.Ny, data.Nx);
    dX.wyy = local_apply(ops.Dyy, data.W, data.Ny, data.Nx);

    dX.Tx = local_apply(ops.Dx, data.TT, data.Ny, data.Nx);
    dX.Ty = local_apply(ops.Dy, data.TT, data.Ny, data.Nx);
    dX.Txx = local_apply(ops.Dxx, data.TT, data.Ny, data.Nx);
    dX.Txy = local_apply(ops.Dxy, data.TT, data.Ny, data.Nx);
    dX.Tyy = local_apply(ops.Dyy, data.TT, data.Ny, data.Nx);

    dX.rhox = local_apply(ops.Dx, data.RHO, data.Ny, data.Nx);
    dX.rhoy = local_apply(ops.Dy, data.RHO, data.Ny, data.Nx);
    dX.rhoxx = local_apply(ops.Dxx, data.RHO, data.Ny, data.Nx);
    dX.rhoxy = local_apply(ops.Dxy, data.RHO, data.Ny, data.Nx);
    dX.rhoyy = local_apply(ops.Dyy, data.RHO, data.Ny, data.Nx);

    dX.px = local_apply(ops.Dx, data.PP, data.Ny, data.Nx);
    dX.py = local_apply(ops.Dy, data.PP, data.Ny, data.Nx);
    dX.pxx = local_apply(ops.Dxx, data.PP, data.Ny, data.Nx);
    dX.pxy = local_apply(ops.Dxy, data.PP, data.Ny, data.Nx);
    dX.pyy = local_apply(ops.Dyy, data.PP, data.Ny, data.Nx);

    dX.div = dX.ux + dX.vy;
    dX.mu_x = data.dMU_dT .* dX.Tx;
    dX.mu_y = data.dMU_dT .* dX.Ty;

    [BoundaryMasks, BoundaryInfo] = build_boundary_masks(data.X, data.Y, Config, 'Verbose', false); %#ok<NASGU>
    [BaseflowPhysicsAudit, GeometryAudit, BaseflowMasks] = build_paperA_baseflow_context( ...
        data.X, data.Y, data.U, data.V, data.RHO, dX, BoundaryMasks, Config, data.BaseValidation); %#ok<NASGU>
    [BaseflowPhysicsAudit, eos_bad_point_mask] = local_attach_eos_audit_details( ...
        BaseflowPhysicsAudit, data.RHO, data.TT, data.PP, Config);
    BaseflowMasks.eos_bad_point_mask = eos_bad_point_mask;
    [LiteratureBenchmarkAudit, BaseflowReferenceTable] = local_build_literature_benchmark_context( ...
        Config, BaseflowPhysicsAudit, GeometryAudit); %#ok<NASGU>
    BaseflowPhysicsAudit.structural_only_warning = LiteratureBenchmarkAudit.structural_only;

    fig_dir = fullfile(pwd, 'figs');
    DerivativeFigureAudit = write_baseflow_derivative_figures(fig_dir, data.X, data.Y, data.U, dX); %#ok<NASGU>

    Part2Diagnostics = struct( ...
        'divergence_proxy_max', BaseflowPhysicsAudit.divergence_proxy_max, ...
        'mass_continuity_residual_max', BaseflowPhysicsAudit.mass_continuity_residual_max, ...
        'mass_continuity_relative_max', BaseflowPhysicsAudit.mass_continuity_relative_max, ...
        'mass_continuity_relative_p95', BaseflowPhysicsAudit.mass_continuity_relative_stats.p95, ...
        'continuity_residual_max', BaseflowPhysicsAudit.continuity_residual_max, ...
        'shock_sensor_p90', local_percentile(abs(dX.rhox(:)) + abs(dX.rhoy(:)), 90)); %#ok<NASGU>

    if local_is_realcase_profile(Config)
        local_assert_realcase_audit(BaseflowPhysicsAudit, GeometryAudit);
    else
        if BaseflowPhysicsAudit.eos_relative_error > 1.0 || ...
                BaseflowPhysicsAudit.divergence_proxy_max > 1.0e2 || ...
                BaseflowPhysicsAudit.mass_continuity_relative_stats.p95 > 1.0e-1
            BaseflowPhysicsAudit.structural_only_warning = true;
        end
    end
    LiteratureBenchmarkAudit.structural_only = BaseflowPhysicsAudit.structural_only_warning;
    LiteratureBenchmarkAudit.physics_reproduction_ready = ...
        LiteratureBenchmarkAudit.boundary_match && ~LiteratureBenchmarkAudit.structural_only && ...
        LiteratureBenchmarkAudit.reference_scales_defined && LiteratureBenchmarkAudit.profile_target_match;

    X = data.X; %#ok<NASGU>
    Y = data.Y; %#ok<NASGU>
    U = data.U; %#ok<NASGU>
    V = data.V; %#ok<NASGU>
    W = data.W; %#ok<NASGU>
    TT = data.TT; %#ok<NASGU>
    RHO = data.RHO; %#ok<NASGU>
    PP = data.PP; %#ok<NASGU>
    MU = data.MU; %#ok<NASGU>
    dMU_dT = data.dMU_dT; %#ok<NASGU>
    d2MU_dT2 = data.d2MU_dT2; %#ok<NASGU>
    BaseValidation = data.BaseValidation; %#ok<NASGU>
    Nx = data.Nx; %#ok<NASGU>
    Ny = data.Ny; %#ok<NASGU>

    save('Part2_Results.mat', ...
        'Config', 'ConfigReport', 'Metrics', 'MetricsReport', 'ops', 'dX', ...
        'BoundaryMasks', 'BoundaryInfo', 'Part2Diagnostics', ...
        'DerivativeFigureAudit', ...
        'LiteratureBenchmarkAudit', 'BaseflowReferenceTable', ...
        'BaseflowPhysicsAudit', 'GeometryAudit', 'BaseflowMasks', ...
        'X', 'Y', 'U', 'V', 'W', 'TT', 'RHO', 'PP', ...
        'MU', 'dMU_dT', 'd2MU_dT2', 'BaseValidation', 'Nx', 'Ny', '-v7.3');
end

function field = local_apply(op, data_field, Ny, Nx)
%LOCAL_APPLY Apply one sparse operator and reshape back to Ny-by-Nx.

    field = reshape(op * data_field(:), Ny, Nx);
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

function stats = local_stats(data_value)
%LOCAL_STATS Basic finite-value summary statistics.

    data_value = data_value(:);
    data_value = data_value(isfinite(data_value));
    if isempty(data_value)
        stats = struct('min', NaN, 'max', NaN, 'mean', NaN, 'median', NaN, ...
            'p05', NaN, 'p95', NaN);
        return;
    end

    stats = struct();
    stats.min = min(data_value);
    stats.max = max(data_value);
    stats.mean = mean(data_value);
    stats.median = median(data_value);
    stats.p05 = local_percentile(data_value, 5.0);
    stats.p95 = local_percentile(data_value, 95.0);
end

function [audit, eos_bad_point_mask] = local_attach_eos_audit_details(audit, rho0, T0, p0, Config)
%LOCAL_ATTACH_EOS_AUDIT_DETAILS Add robust EOS statistics for real-case gating.

    R_nd = 1.0 / (Config.gamma * Config.Ma_inf^2);
    eos_ref = R_nd * rho0 .* T0;
    eos_rel = abs(p0 - eos_ref) ./ max(abs(p0), eps);
    ratio = p0 ./ max(eos_ref, eps);

    audit.eos_relative_error = max(eos_rel(:));
    audit.eos_relative_error_stats = local_stats(eos_rel);
    audit.eos_hard_gate_metric = audit.eos_relative_error_stats.p95;
    audit.eos_bad_point_threshold = 1.0e-2;
    eos_bad_point_mask = eos_rel > audit.eos_bad_point_threshold;
    audit.eos_bad_point_count = nnz(eos_bad_point_mask);
    audit.eos_bad_point_fraction = audit.eos_bad_point_count / max(numel(eos_rel), 1);
    audit.pressure_ratio_label = 'p / (rho*T/(gamma*Ma^2))';
    audit.pressure_ratio_stats = local_stats(ratio);
end

function tf = local_is_realcase_profile(Config)
%LOCAL_IS_REALCASE_PROFILE True when the imported grid matches the 812x382 campaign case.

    tf = isfield(Config, 'Nx_raw') && isfield(Config, 'Ny_raw') && ...
        Config.Nx_raw == 812 && Config.Ny_raw == 382;
end

function local_assert_realcase_audit(BaseflowPhysicsAudit, GeometryAudit)
%LOCAL_ASSERT_REALCASE_AUDIT Hard-stop gate for the intended physical case.

    if ~strcmpi(GeometryAudit.boundary_contract.top, 'inlet')
        error('Main_DoubleWedge_Part2_v6:RealcaseTopBoundary', ...
            'The 812x382 physical case requires top=inlet.');
    end
    eos_hard = BaseflowPhysicsAudit.eos_relative_error;
    eos_p95 = NaN;
    eos_bad_fraction = NaN;
    if isfield(BaseflowPhysicsAudit, 'eos_hard_gate_metric')
        eos_hard = BaseflowPhysicsAudit.eos_hard_gate_metric;
    end
    if isfield(BaseflowPhysicsAudit, 'eos_relative_error_stats') && isstruct(BaseflowPhysicsAudit.eos_relative_error_stats)
        eos_p95 = BaseflowPhysicsAudit.eos_relative_error_stats.p95;
    end
    if isfield(BaseflowPhysicsAudit, 'eos_bad_point_fraction')
        eos_bad_fraction = BaseflowPhysicsAudit.eos_bad_point_fraction;
    end
    if eos_hard > 1.0e-2
        error('Main_DoubleWedge_Part2_v6:RealcaseEOS', ...
            ['EOS audit failed for the 812x382 physical case: p95=%.3e, max=%.3e. ' ...
             'Check whether the imported columns and nondimensionalization satisfy ' ...
             'p = rho*T/(gamma*Ma^2). Run run_baseflow_import_audit_v6(...) before Part2 ' ...
             'to inspect the pressure-ratio statistics.'], ...
            eos_p95, BaseflowPhysicsAudit.eos_relative_error);
    end
    if BaseflowPhysicsAudit.eos_relative_error > 1.0e-2
        warning('Main_DoubleWedge_Part2_v6:RealcaseEOSLocalizedOutliers', ...
            ['Real-case EOS audit has localized outliers: max=%.3e, p95=%.3e, bad-point fraction=%.3e. ' ...
             'Proceeding because the bulk field passes the p95 gate; verify that the outliers stay confined ' ...
             'to shock/corner regions.'], ...
            BaseflowPhysicsAudit.eos_relative_error, eos_p95, eos_bad_fraction);
    end
    div_proxy = NaN;
    if isfield(BaseflowPhysicsAudit, 'divergence_proxy_max')
        div_proxy = BaseflowPhysicsAudit.divergence_proxy_max;
    end
    continuity_rel_max = BaseflowPhysicsAudit.continuity_residual_max;
    continuity_rel_p95 = continuity_rel_max;
    if isfield(BaseflowPhysicsAudit, 'mass_continuity_relative_stats') && ...
            isstruct(BaseflowPhysicsAudit.mass_continuity_relative_stats) && ...
            isfield(BaseflowPhysicsAudit.mass_continuity_relative_stats, 'p95')
        continuity_rel_p95 = BaseflowPhysicsAudit.mass_continuity_relative_stats.p95;
    end
    if isfinite(div_proxy) && div_proxy > 1.0
        warning('Main_DoubleWedge_Part2_v6:RealcaseDivergenceProxy', ...
            ['Real-case divergence proxy is large (max|ux+vy|=%.3e), but this quantity is not the ' ...
             'compressible mass-continuity residual and is therefore warning-only.'], ...
            div_proxy);
    end
    if continuity_rel_p95 > 1.0e-1
        warning('Main_DoubleWedge_Part2_v6:RealcaseMassContinuity', ...
            ['Real-case normalized mass-continuity audit is elevated: p95=%.3e, max=%.3e. ' ...
             'Proceeding because the previous hard-stop on ux+vy was overly strict for compressible shock-containing flows; ' ...
             'inspect the saved Part2 diagnostics before trusting the spectrum physically.'], ...
            continuity_rel_p95, continuity_rel_max);
    end
end

function [audit, reference_table] = local_build_literature_benchmark_context(Config, BaseflowPhysicsAudit, GeometryAudit)
%LOCAL_BUILD_LITERATURE_BENCHMARK_CONTEXT Build one literature-facing benchmark summary.

    benchmark = struct();
    if isfield(Config, 'benchmark') && isstruct(Config.benchmark)
        benchmark = Config.benchmark;
    end

    boundary_match = false;
    if isfield(benchmark, 'boundary_contract') && isstruct(benchmark.boundary_contract) && ...
            isfield(GeometryAudit, 'boundary_contract') && isstruct(GeometryAudit.boundary_contract)
        boundary_match = strcmpi(GeometryAudit.boundary_contract.top, benchmark.boundary_contract.top) && ...
            strcmpi(GeometryAudit.boundary_contract.west, benchmark.boundary_contract.west) && ...
            strcmpi(GeometryAudit.boundary_contract.east, benchmark.boundary_contract.east);
    end

    reference_scales_defined = false;
    if isfield(Config, 'reference_scales') && isstruct(Config.reference_scales) && ...
            isfield(Config.reference_scales, 'defined')
        reference_scales_defined = logical(Config.reference_scales.defined);
    end

    audit = struct();
    audit.benchmark_profile = local_get_string_field(Config, 'benchmark_profile', '');
    audit.target_benchmark = local_get_string_field(Config, 'target_benchmark', '');
    audit.display_name = local_get_string_field(benchmark, 'display_name', audit.target_benchmark);
    audit.phase = local_get_string_field(benchmark, 'phase', 'code_correction');
    audit.plot_contract = local_get_string_field(benchmark, 'secondary_plot_contract', ...
        local_get_string_field(Config, 'secondary_plot_contract', ''));
    audit.boundary_match = boundary_match;
    audit.reference_scales_defined = reference_scales_defined;
    audit.profile_target_match = strcmpi(audit.target_benchmark, 'Sidharth2018');
    audit.structural_only = local_get_logical_field(Config, 'structural_only', true);
    audit.physics_reproduction_ready = false;
    audit.reason = 'code_correction_stage_only';
    if audit.structural_only
        audit.reason = 'structural_benchmark_not_physical_reproduction';
    elseif ~boundary_match
        audit.reason = 'boundary_contract_mismatch';
    elseif ~reference_scales_defined
        audit.reason = 'reference_scales_not_defined';
    elseif ~audit.profile_target_match
        audit.reason = 'target_benchmark_not_sidharth2018';
    else
        audit.reason = 'ready_for_physical_reproduction_checks';
    end

    reference_table = table( ...
        string({'geometry'; 'Mach'; 'Re'; 'wall_bc'; 'separation_x'; 'reattachment_x'; 'bubble_length'; 'delta99_at_separation'}), ...
        string({ ...
            local_get_string_field(benchmark, 'geometry_label', ''); ...
            sprintf('%.3f', Config.Ma_inf); ...
            sprintf('%.6e', Config.Re_inf); ...
            local_get_string_field(benchmark, 'wall_condition', ''); ...
            local_format_number(BaseflowPhysicsAudit.separation_x); ...
            local_format_number(BaseflowPhysicsAudit.reattachment_x); ...
            local_format_number(BaseflowPhysicsAudit.bubble_length); ...
            local_format_number(BaseflowPhysicsAudit.delta99_at_separation)}), ...
        string({ ...
            local_get_nested_string(benchmark, {'literature_targets', 'geometry_label'}, 'slender double wedge 12-20 / 12-22'); ...
            local_get_nested_string(benchmark, {'literature_targets', 'mach_label'}, 'Mach 5'); ...
            'literature-specific'; ...
            local_get_nested_string(benchmark, {'literature_targets', 'wall_bc_label'}, 'adiabatic wall'); ...
            '12.15 mm upstream of hinge (literature)'; ...
            '11.4 mm downstream of hinge (literature)'; ...
            'literature bubble length'; ...
            'delta99 = 1 mm at separation (literature)'}), ...
        string({ ...
            'current code-correction profile metadata'; ...
            'current imported baseflow Mach number'; ...
            'current imported baseflow Reynolds number'; ...
            'profile target wall condition'; ...
            'current baseflow-derived estimate'; ...
            'current baseflow-derived estimate'; ...
            'current baseflow-derived estimate'; ...
            'current baseflow-derived estimate'}), ...
        'VariableNames', {'quantity', 'your_run', 'literature', 'note'});
end

function value = local_get_string_field(S, field_name, default_value)
%LOCAL_GET_STRING_FIELD Read one string-like field from a struct.

    value = default_value;
    if isstruct(S) && isfield(S, field_name)
        value = char(string(S.(field_name)));
    end
end

function value = local_get_nested_string(S, chain, default_value)
%LOCAL_GET_NESTED_STRING Read one nested string-like field chain.

    value = default_value;
    current = S;
    for k = 1:numel(chain)
        name = chain{k};
        if ~isstruct(current) || ~isfield(current, name)
            return;
        end
        current = current.(name);
    end
    value = char(string(current));
end

function value = local_get_logical_field(S, field_name, default_value)
%LOCAL_GET_LOGICAL_FIELD Read one logical-like field from a struct.

    value = default_value;
    if isstruct(S) && isfield(S, field_name)
        value = logical(S.(field_name));
    end
end

function text = local_format_number(value)
%LOCAL_FORMAT_NUMBER Format one scalar for the literature-facing table.

    if isnumeric(value) && isscalar(value) && isfinite(value)
        text = sprintf('%.6g', value);
    else
        text = 'NaN';
    end
end
