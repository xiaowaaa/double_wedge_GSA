function summary = run_user_test_baseflow_fullres_v6(varargin)
%RUN_USER_TEST_BASEFLOW_FULLRES_V6 Run configurable v6 global-stability cases.

    p = inputParser;
    p.FunctionName = 'run_user_test_baseflow_fullres_v6';
    addParameter(p, 'BaseflowFile', '', @(x) ischar(x) || (isstring(x) && isscalar(x)));
    addParameter(p, 'ExpectedDims', [270, 128], @(x) isnumeric(x) && numel(x) == 2);
    addParameter(p, 'StrideX', 1, @(x) isnumeric(x) && isscalar(x) && x >= 1);
    addParameter(p, 'StrideY', 1, @(x) isnumeric(x) && isscalar(x) && x >= 1);
    addParameter(p, 'TopType', 'inlet', @(x) ischar(x) || (isstring(x) && isscalar(x)));
    addParameter(p, 'BenchmarkProfile', 'sidharth2018_code_correction_v1', ...
        @(x) ischar(x) || (isstring(x) && isscalar(x)));
    addParameter(p, 'UseSponge', false, @(x) islogical(x) || isnumeric(x));
    addParameter(p, 'NEigs', 80, @(x) isnumeric(x) && isscalar(x) && x >= 1);
    addParameter(p, 'Beta', 0.0, @(x) isnumeric(x) && isscalar(x) && isfinite(x));
    addParameter(p, 'SigmaShift', 0.05 + 0.02i, @(x) isnumeric(x) && isscalar(x));
    addParameter(p, 'SigmaTriplet', [], @(x) isempty(x) || isnumeric(x));
    addParameter(p, 'KrylovDimensionFloor', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && x >= 8));
    addParameter(p, 'KrylovDimensionCap', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && x >= 8));
    addParameter(p, 'MachInf', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && isfinite(x) && x > 0));
    addParameter(p, 'ReInf', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && isfinite(x) && x > 0));
    addParameter(p, 'TInf', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && isfinite(x) && x > 0));
    addParameter(p, 'Gamma', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && isfinite(x) && x > 1.0));
    addParameter(p, 'Pr', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && isfinite(x) && x > 0));
    addParameter(p, 'WallModel', '', @(x) ischar(x) || (isstring(x) && isscalar(x)));
    addParameter(p, 'WallTemperature', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && isfinite(x) && x > 0));
    addParameter(p, 'ForceLowMemoryDescriptor', false, @(x) islogical(x) || isnumeric(x));
    addParameter(p, 'CaseName', 'user_test_baseflow_270x128_fullres_v6', ...
        @(x) ischar(x) || (isstring(x) && isscalar(x)));
    addParameter(p, 'ReuseExistingCase', false, @(x) islogical(x) || isnumeric(x));
    addParameter(p, 'RunPart4', true, @(x) islogical(x) || isnumeric(x));
    addParameter(p, 'FigureDirectory', '', @(x) ischar(x) || (isstring(x) && isscalar(x)));
    addParameter(p, 'Part3Variant', 'current_v6', @(x) local_is_part3_variant(x));
    addParameter(p, 'UseSemiArtificialViscosity', [], @(x) isempty(x) || islogical(x) || isnumeric(x));
    addParameter(p, 'SavEpsilon', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && isfinite(x)));
    addParameter(p, 'SavShockPercentile', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && isfinite(x)));
    addParameter(p, 'SavDilationSteps', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && x >= 0));
    addParameter(p, 'SavNearWallFraction', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && x >= 0));
    addParameter(p, 'UseShockSourceRegularization', [], @(x) isempty(x) || islogical(x) || isnumeric(x));
    addParameter(p, 'ShockClipPercentile', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && isfinite(x)));
    addParameter(p, 'ShockDmuClipPercentile', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && isfinite(x)));
    addParameter(p, 'ZeroSecondDerivativesInShock', [], @(x) isempty(x) || islogical(x) || isnumeric(x));
    addParameter(p, 'SuppressViscosityGradientTermsInShock', [], @(x) isempty(x) || islogical(x) || isnumeric(x));
    addParameter(p, 'UsePressureRowRegularization', [], @(x) isempty(x) || islogical(x) || isnumeric(x));
    addParameter(p, 'PressureGradientClipPercentile', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && isfinite(x)));
    addParameter(p, 'PressureDivergenceClipPercentile', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && isfinite(x)));
    addParameter(p, 'SuppressPressureGradientsInShock', [], @(x) isempty(x) || islogical(x) || isnumeric(x));
    addParameter(p, 'SuppressPressureDivergenceInShock', [], @(x) isempty(x) || islogical(x) || isnumeric(x));
    addParameter(p, 'EnableAdjointLeadDiagnostics', [], @(x) isempty(x) || islogical(x) || isnumeric(x));
    parse(p, varargin{:});

    paths = setup_double_wedge_paths();
    project_root = paths.project_root;

    baseflow_file = char(string(p.Results.BaseflowFile));
    if strlength(string(baseflow_file)) == 0
        baseflow_file = fullfile(project_root, 'double_wedge_baseflow.dat');
    end

    requested_part3_variant = local_canonical_part3_variant(p.Results.Part3Variant);
    case_dir = fullfile(project_root, 'outputs', 'mat', char(string(p.Results.CaseName)));
    metadata_file = fullfile(case_dir, 'RunnerCaseMetadata.mat');
    if exist(case_dir, 'dir') ~= 7
        mkdir(case_dir);
    end
    figure_dir = char(string(p.Results.FigureDirectory));
    if strlength(string(figure_dir)) == 0
        figure_dir = fullfile(case_dir, 'figs');
    end

    old_dir = pwd;
    cleanup_obj = onCleanup(@() cd(old_dir)); %#ok<NASGU>
    cd(case_dir);

    runner_metadata = struct();
    if ~logical(p.Results.ReuseExistingCase)
        Main_DoubleWedge_Part1_v6( ...
            'BaseflowFile', baseflow_file, ...
            'ExpectedDims', double(p.Results.ExpectedDims(:)).', ...
            'StrideX', p.Results.StrideX, ...
            'StrideY', p.Results.StrideY, ...
            'TopType', p.Results.TopType, ...
            'BenchmarkProfile', p.Results.BenchmarkProfile, ...
            'UseSponge', p.Results.UseSponge, ...
            'Beta', p.Results.Beta, ...
            'NEigs', p.Results.NEigs, ...
            'SigmaShift', p.Results.SigmaShift, ...
            'SigmaTriplet', p.Results.SigmaTriplet, ...
            'KrylovDimensionFloor', p.Results.KrylovDimensionFloor, ...
            'KrylovDimensionCap', p.Results.KrylovDimensionCap, ...
            'MachInf', p.Results.MachInf, ...
            'ReInf', p.Results.ReInf, ...
            'TInf', p.Results.TInf, ...
            'Gamma', p.Results.Gamma, ...
            'Pr', p.Results.Pr, ...
            'WallModel', p.Results.WallModel, ...
            'WallTemperature', p.Results.WallTemperature);
        local_apply_part1_config_overrides('Part1_Results.mat', p.Results);
        Main_DoubleWedge_Part2_v6();
        part3_variant_used = local_run_part3_variant(requested_part3_variant);
        matrix_report = Diagnose_MatrixHealth('Part3_Results.mat'); %#ok<NASGU>
        save('Diagnose_MatrixHealth_Report.mat', 'matrix_report', '-v7.3');
        if logical(p.Results.RunPart4)
            Main_DoubleWedge_Part4_v6('FigureDirectory', figure_dir);
        end
    else
        runner_metadata = local_load_runner_case_metadata(metadata_file, case_dir);
        reuse_part1 = load('Part1_Results.mat', 'Config');
        local_validate_reuse_request( ...
            p.Results, requested_part3_variant, baseflow_file, reuse_part1.Config, ...
            runner_metadata, case_dir);
        part3_variant_used = runner_metadata.case_identity.part3_variant_used;
        if exist('Diagnose_MatrixHealth_Report.mat', 'file') == 2
            matrix_data = load('Diagnose_MatrixHealth_Report.mat', 'matrix_report');
            matrix_report = matrix_data.matrix_report; %#ok<NASGU>
        else
            matrix_report = Diagnose_MatrixHealth('Part3_Results.mat'); %#ok<NASGU>
            save('Diagnose_MatrixHealth_Report.mat', 'matrix_report', '-v7.3');
        end
    end

    part1 = load('Part1_Results.mat', 'Config', 'BaseValidation', 'Nx', 'Ny');
    part1.Config = local_normalize_runner_config(part1.Config);
    part2 = local_load_part2_results('Part2_Results.mat', part1.Config);
    if isempty(fieldnames(runner_metadata))
        case_identity = local_build_case_identity( ...
            project_root, baseflow_file, p.Results, requested_part3_variant, part3_variant_used);
        runner_metadata = local_build_runner_case_metadata(case_identity);
    else
        case_identity = runner_metadata.case_identity;
    end
    has_part4 = exist('Part4_Results.mat', 'file') == 2;

    if logical(p.Results.RunPart4)
        if ~has_part4
            error('run_user_test_baseflow_fullres_v6:MissingPart4', ...
                'RunPart4=true but Part4_Results.mat is missing in case directory: %s', case_dir);
        end
        part4 = load('Part4_Results.mat');
        part4 = local_backfill_part4_fields(part4);
        solve_config = local_pick_solve_config(part4, part1);
        solve_config = local_normalize_runner_config(solve_config);
        [lead_idx, lead_original_idx, lead_audit] = resolve_part4_plot_lead_position(part4);
        top_modes = local_build_top_modes(part4);
        summary = local_build_part4_summary( ...
            case_dir, case_identity, p.Results, solve_config, ...
            part1, part2, part4, matrix_report, top_modes, ...
            lead_idx, lead_original_idx, lead_audit, ...
            figure_dir);
    else
        part3 = load('Part3_Results.mat');
        solve_config = local_pick_solve_config(part3, part1);
        solve_config = local_normalize_runner_config(solve_config);
        top_modes = struct([]);
        summary = local_build_part3_summary( ...
            case_dir, case_identity, p.Results, solve_config, ...
            part1, part2, part3, matrix_report, figure_dir);
    end

    if ~logical(p.Results.ReuseExistingCase)
        runner_metadata.case_identity = case_identity;
        runner_metadata.stage_completed = summary.stage_completed;
        local_save_runner_case_metadata(metadata_file, runner_metadata);
    end

    save('run_summary.mat', 'summary', 'top_modes', 'matrix_report', '-v7.3');
    local_write_summary_text(fullfile(case_dir, 'run_summary.txt'), summary, top_modes);

    fprintf('\n[user_test_baseflow_fullres_v6] Case directory: %s\n', case_dir);
    fprintf('[user_test_baseflow_fullres_v6] Working grid: Nx=%d, Ny=%d\n', ...
        summary.working_dims(1), summary.working_dims(2));
    if strcmp(summary.stage_completed, 'Part4')
        if isfield(summary, 'leading_mode_available') && ~summary.leading_mode_available
            fprintf(['[user_test_baseflow_fullres_v6] No physical plotted lead is available; ' ...
                'selection_status=%s, resolution=%s\n'], ...
                summary.selection_summary.status, summary.leading_mode_resolution.status);
        else
            fprintf(['[user_test_baseflow_fullres_v6] Leading mode: sigma_r=%+.6e, ' ...
                'sigma_i=%+.6e, residual=%.3e, bubble=%.3f, near_wall=%.3f, checker=%.3f\n'], ...
                summary.leading_sigma_r, summary.leading_sigma_i, summary.leading_residual, ...
                summary.leading_bubble_overlap, summary.leading_near_wall_energy_frac, summary.leading_checker_ratio);
        end
    else
        fprintf(['[user_test_baseflow_fullres_v6] Part3-only summary: row_ratio=%.3e, ' ...
            'shock_cov=%.3f, pressure_clip=%d, sav_active=%d\n'], ...
            summary.operator_health.row_ratio_before, ...
            summary.shock_info.coverage_fraction, ...
            summary.pressure_row_audit.total_clipped, ...
            summary.sav_info.active_rows);
    end
end

function local_apply_part1_config_overrides(part1_file, opts)
%LOCAL_APPLY_PART1_CONFIG_OVERRIDES Apply optional run-time Config overrides after Part1.

    data = load(part1_file);
    Config = local_normalize_runner_config(data.Config);
    changed = false;

    [Config.use_semi_artificial_viscosity, tf] = local_optional_override(Config.use_semi_artificial_viscosity, opts.UseSemiArtificialViscosity);
    changed = changed || tf;
    [Config.semi_artificial_viscosity.epsilon, tf] = local_optional_override(Config.semi_artificial_viscosity.epsilon, opts.SavEpsilon);
    changed = changed || tf;
    [Config.semi_artificial_viscosity.shock_percentile, tf] = local_optional_override(Config.semi_artificial_viscosity.shock_percentile, opts.SavShockPercentile);
    changed = changed || tf;
    [Config.semi_artificial_viscosity.dilation_steps, tf] = local_optional_override(Config.semi_artificial_viscosity.dilation_steps, opts.SavDilationSteps);
    changed = changed || tf;
    [Config.semi_artificial_viscosity.near_wall_fraction, tf] = local_optional_override(Config.semi_artificial_viscosity.near_wall_fraction, opts.SavNearWallFraction);
    changed = changed || tf;

    [Config.use_shock_source_regularization, tf] = local_optional_override(Config.use_shock_source_regularization, opts.UseShockSourceRegularization);
    changed = changed || tf;
    [Config.shock_source_regularization.clip_percentile, tf] = local_optional_override(Config.shock_source_regularization.clip_percentile, opts.ShockClipPercentile);
    changed = changed || tf;
    [Config.shock_source_regularization.dmu_clip_percentile, tf] = local_optional_override(Config.shock_source_regularization.dmu_clip_percentile, opts.ShockDmuClipPercentile);
    changed = changed || tf;
    [Config.shock_source_regularization.zero_second_derivatives_in_shock, tf] = local_optional_override( ...
        Config.shock_source_regularization.zero_second_derivatives_in_shock, opts.ZeroSecondDerivativesInShock);
    changed = changed || tf;
    [Config.shock_source_regularization.suppress_viscosity_gradient_terms_in_shock, tf] = local_optional_override( ...
        Config.shock_source_regularization.suppress_viscosity_gradient_terms_in_shock, opts.SuppressViscosityGradientTermsInShock);
    changed = changed || tf;

    [Config.pressure_row_regularization.enabled, tf] = local_optional_override(Config.pressure_row_regularization.enabled, opts.UsePressureRowRegularization);
    changed = changed || tf;
    [Config.pressure_row_regularization.gradient_clip_percentile, tf] = local_optional_override( ...
        Config.pressure_row_regularization.gradient_clip_percentile, opts.PressureGradientClipPercentile);
    changed = changed || tf;
    [Config.pressure_row_regularization.divergence_clip_percentile, tf] = local_optional_override( ...
        Config.pressure_row_regularization.divergence_clip_percentile, opts.PressureDivergenceClipPercentile);
    changed = changed || tf;
    [Config.pressure_row_regularization.suppress_pressure_gradients_in_shock, tf] = local_optional_override( ...
        Config.pressure_row_regularization.suppress_pressure_gradients_in_shock, opts.SuppressPressureGradientsInShock);
    changed = changed || tf;
    [Config.pressure_row_regularization.suppress_divergence_in_shock, tf] = local_optional_override( ...
        Config.pressure_row_regularization.suppress_divergence_in_shock, opts.SuppressPressureDivergenceInShock);
    changed = changed || tf;
    [Config.analysis.compute_adjoint_lead, tf] = local_optional_override( ...
        Config.analysis.compute_adjoint_lead, opts.EnableAdjointLeadDiagnostics);
    changed = changed || tf;

    if logical(opts.ForceLowMemoryDescriptor)
        if ~isfield(Config, 'descriptor_solver') || ~isstruct(Config.descriptor_solver)
            Config.descriptor_solver = struct();
        end
        [Config.descriptor_solver.large_system_threshold, tf] = local_optional_override( ...
            local_get_descriptor_solver_field(Config, 'large_system_threshold', 4.0e5), 1);
        changed = changed || tf;
    end

    Config.epsilon_art = Config.semi_artificial_viscosity.epsilon;
    if changed
        data.Config = Config;
        save(part1_file, '-struct', 'data', '-v7.3');
    end
end

function summary = local_build_part4_summary(case_dir, case_identity, opts, solve_config, part1, part2, part4, matrix_report, top_modes, lead_idx, lead_original_idx, lead_audit, figure_dir)
%LOCAL_BUILD_PART4_SUMMARY Build the full Part4 summary struct.

    summary = struct();
    summary.case_dir = case_dir;
    summary.figure_directory = figure_dir;
    summary.baseflow_file = case_identity.baseflow_file_display;
    summary.raw_dims = [part1.Config.Nx_raw, part1.Config.Ny_raw];
    summary.working_dims = [part1.Nx, part1.Ny];
    summary.expected_dims = case_identity.expected_dims;
    summary.stride = case_identity.stride;
    summary.top_type = case_identity.top_type;
    summary.benchmark_profile = local_get_optional_field(solve_config, 'benchmark_profile', '');
    summary.target_benchmark = local_get_optional_field(solve_config, 'target_benchmark', '');
    summary.primary_plot_contract = local_get_optional_field(solve_config, 'plot_contract', '');
    summary.secondary_plot_contract = local_get_optional_field(solve_config, 'secondary_plot_contract', '');
    summary.reference_scales = local_get_optional_field(solve_config, 'reference_scales', struct('defined', false));
    summary.n_eigs = solve_config.n_eigs;
    summary.beta = solve_config.beta;
    summary.Ma_inf = solve_config.Ma_inf;
    summary.Re_inf = solve_config.Re_inf;
    summary.T_inf = solve_config.T_inf;
    summary.gamma = solve_config.gamma;
    summary.Pr = solve_config.Pr;
    summary.wall_model = solve_config.wall_model;
    summary.T_wall = solve_config.T_wall;
    summary.T_wall_nd = solve_config.T_wall_nd;
    summary.sigma_shift = solve_config.sigma;
    summary.sigma_triplet = solve_config.sigma_triplet;
    summary.state_layout = solve_config.state_layout;
    summary.operator_model = solve_config.operator_model;
    summary.use_sponge = solve_config.use_sponge;
    summary.use_semi_artificial_viscosity = solve_config.use_semi_artificial_viscosity;
    summary.use_shock_source_regularization = solve_config.use_shock_source_regularization;
    summary.pressure_row_regularization = solve_config.pressure_row_regularization;
    summary.base_validation = part1.BaseValidation;
    summary.baseflow_physics_audit = part2.BaseflowPhysicsAudit;
    summary.geometry_audit = part2.GeometryAudit;
    summary.literature_benchmark_audit = local_get_optional_field(part2, 'LiteratureBenchmarkAudit', struct());
    summary.baseflow_reference_table = local_get_optional_field(part2, 'BaseflowReferenceTable', table());
    summary.part2_diagnostics = part2.Part2Diagnostics;
    summary.matrix_report = matrix_report;
    summary.matrix_health = part4.MatrixHealth;
    summary.leading_mode_position = lead_idx;
    summary.leading_mode_original_index = lead_original_idx;
    summary.leading_mode_available = isfinite(lead_idx);
    summary.leading_mode_resolution = lead_audit;
    if summary.leading_mode_available
        summary.leading_sigma = part4.EigVals_s(lead_idx);
        summary.leading_sigma_r = real(part4.EigVals_s(lead_idx));
        summary.leading_sigma_i = imag(part4.EigVals_s(lead_idx));
        summary.leading_freq_nd = part4.St_s(lead_idx);
        summary.leading_freq_signed = part4.freq_signed_s(lead_idx);
        summary.leading_omega = part4.OmegaVals_s(lead_idx);
        summary.leading_residual = part4.res_s(lead_idx);
        summary.leading_residual_active = part4.res_active_s(lead_idx);
        summary.leading_residual_algebraic = part4.res_algebraic_s(lead_idx);
        summary.leading_residual_scaled = part4.res_scaled_s(lead_idx);
        summary.leading_bubble_overlap = part4.bubble_overlap_s(lead_idx);
        summary.leading_wall_energy_frac = part4.wall_energy_frac_s(lead_idx);
        summary.leading_near_wall_energy_frac = part4.near_wall_energy_frac_s(lead_idx);
        summary.leading_free_stream_energy_frac = part4.free_stream_energy_frac_s(lead_idx);
        summary.leading_sponge_energy_frac = part4.sponge_energy_frac_s(lead_idx);
        summary.leading_outlet_energy_frac = part4.outlet_energy_frac_s(lead_idx);
        summary.leading_outlet_wall_energy_frac = part4.outlet_wall_energy_frac_s(lead_idx);
        summary.leading_shock_energy_frac = part4.shock_energy_frac_s(lead_idx);
        summary.leading_checker_ratio = part4.checker_ratio_s(lead_idx);
        summary.leading_farfield_ratio = part4.farfield_ratio_s(lead_idx);
        summary.leading_highfreq_ratio = part4.highfreq_ratio_s(lead_idx);
        summary.leading_selected_for_plots = logical(part4.ranking_table.selected_for_plots(lead_idx));
        summary.leading_selected_for_publication = logical(part4.ranking_table.selected_for_publication(lead_idx));
        summary.leading_mode_family = local_pick_vector_entry(part4.ModeFamily_s, lead_idx, '');
        summary.leading_physical_candidate_score = local_pick_vector_entry(part4.physical_candidate_score_s, lead_idx, NaN);
        summary.leading_bubble_shock_phase_deg = local_pick_vector_entry(part4.bubble_shock_phase_deg_s, lead_idx, NaN);
        summary.leading_bubble_shock_sync = local_pick_vector_entry(part4.bubble_shock_sync_s, lead_idx, NaN);
        summary.leading_reference_component = local_pick_coupling_field(part4.ModeCouplingAudit, lead_idx, 'reference_component', '');
        summary.leading_region_energy = struct( ...
            'bubble', part4.bubble_overlap_s(lead_idx), ...
            'near_wall', part4.near_wall_energy_frac_s(lead_idx), ...
            'free_stream', part4.free_stream_energy_frac_s(lead_idx), ...
            'sponge', part4.sponge_energy_frac_s(lead_idx), ...
            'shock', part4.shock_energy_frac_s(lead_idx), ...
            'outlet', part4.outlet_energy_frac_s(lead_idx), ...
            'outlet_wall', part4.outlet_wall_energy_frac_s(lead_idx));
    else
        summary.leading_sigma = NaN;
        summary.leading_sigma_r = NaN;
        summary.leading_sigma_i = NaN;
        summary.leading_freq_nd = NaN;
        summary.leading_freq_signed = NaN;
        summary.leading_omega = NaN;
        summary.leading_residual = NaN;
        summary.leading_residual_active = NaN;
        summary.leading_residual_algebraic = NaN;
        summary.leading_residual_scaled = NaN;
        summary.leading_bubble_overlap = NaN;
        summary.leading_wall_energy_frac = NaN;
        summary.leading_near_wall_energy_frac = NaN;
        summary.leading_free_stream_energy_frac = NaN;
        summary.leading_sponge_energy_frac = NaN;
        summary.leading_outlet_energy_frac = NaN;
        summary.leading_outlet_wall_energy_frac = NaN;
        summary.leading_shock_energy_frac = NaN;
        summary.leading_checker_ratio = NaN;
        summary.leading_farfield_ratio = NaN;
        summary.leading_highfreq_ratio = NaN;
        summary.leading_selected_for_plots = false;
        summary.leading_selected_for_publication = false;
        summary.leading_mode_family = '';
        summary.leading_physical_candidate_score = NaN;
        summary.leading_bubble_shock_phase_deg = NaN;
        summary.leading_bubble_shock_sync = NaN;
        summary.leading_reference_component = '';
        summary.leading_region_energy = struct( ...
            'bubble', NaN, ...
            'near_wall', NaN, ...
            'free_stream', NaN, ...
            'sponge', NaN, ...
            'shock', NaN, ...
            'outlet', NaN, ...
            'outlet_wall', NaN);
    end
    summary.num_selected_modes = nnz(part4.ranking_table.selected_for_plots);
    summary.freq_label = part4.freq_label;
    summary.selection_summary = part4.selection_summary;
    summary.mode_validity_report = part4.mode_validity_report;
    summary.mode_selection_audit = part4.ModeSelectionAudit;
    summary.mode_coupling_audit = part4.ModeCouplingAudit;
    summary.component_mode_audit = local_get_optional_field(part4, 'ComponentModeAudit', struct([]));
    summary.mode_reference_table = local_get_optional_field(part4, 'ModeReferenceTable', table());
    summary.eigen_reference_table = local_get_optional_field(part4, 'EigenReferenceTable', table());
    summary.figure_criteria_table = local_get_optional_field(part4, 'FigureCriteriaTable', table());
    summary.plot_provenance_audit = local_get_optional_field(part4, 'PlotProvenanceAudit', struct());
    summary.plot_contract_audit = local_get_optional_field(part4, 'PlotContractAudit', struct());
    summary.figure_audit = local_get_optional_field(part4, 'FigureAudit', struct());
    summary.adjoint_lead_audit = part4.AdjointLeadAudit;
    summary.has_wavemaker_map = ~isempty(part4.WavemakerLeadMap);
    summary.top_modes = top_modes;
    summary.part3_variant_requested = case_identity.part3_variant_requested;
    summary.part3_variant_used = case_identity.part3_variant_used;
    summary.run_part4_requested = logical(opts.RunPart4);
    summary.reuse_existing_case = logical(opts.ReuseExistingCase);
    summary.stage_completed = 'Part4';
    summary.has_part4 = true;
end

function summary = local_build_part3_summary(case_dir, case_identity, opts, solve_config, part1, part2, part3, matrix_report, figure_dir)
%LOCAL_BUILD_PART3_SUMMARY Build the cheaper Part3-only summary struct.

    summary = struct();
    summary.case_dir = case_dir;
    summary.figure_directory = figure_dir;
    summary.baseflow_file = case_identity.baseflow_file_display;
    summary.raw_dims = [part1.Config.Nx_raw, part1.Config.Ny_raw];
    summary.working_dims = [part1.Nx, part1.Ny];
    summary.expected_dims = case_identity.expected_dims;
    summary.stride = case_identity.stride;
    summary.top_type = case_identity.top_type;
    summary.benchmark_profile = local_get_optional_field(solve_config, 'benchmark_profile', '');
    summary.target_benchmark = local_get_optional_field(solve_config, 'target_benchmark', '');
    summary.primary_plot_contract = local_get_optional_field(solve_config, 'plot_contract', '');
    summary.secondary_plot_contract = local_get_optional_field(solve_config, 'secondary_plot_contract', '');
    summary.reference_scales = local_get_optional_field(solve_config, 'reference_scales', struct('defined', false));
    summary.n_eigs = solve_config.n_eigs;
    summary.beta = solve_config.beta;
    summary.Ma_inf = solve_config.Ma_inf;
    summary.Re_inf = solve_config.Re_inf;
    summary.T_inf = solve_config.T_inf;
    summary.gamma = solve_config.gamma;
    summary.Pr = solve_config.Pr;
    summary.wall_model = solve_config.wall_model;
    summary.T_wall = solve_config.T_wall;
    summary.T_wall_nd = solve_config.T_wall_nd;
    summary.sigma_shift = solve_config.sigma;
    summary.sigma_triplet = solve_config.sigma_triplet;
    summary.state_layout = solve_config.state_layout;
    summary.operator_model = solve_config.operator_model;
    summary.use_sponge = solve_config.use_sponge;
    summary.use_semi_artificial_viscosity = solve_config.use_semi_artificial_viscosity;
    summary.use_shock_source_regularization = solve_config.use_shock_source_regularization;
    summary.pressure_row_regularization = solve_config.pressure_row_regularization;
    summary.base_validation = part1.BaseValidation;
    summary.baseflow_physics_audit = part2.BaseflowPhysicsAudit;
    summary.geometry_audit = part2.GeometryAudit;
    summary.literature_benchmark_audit = local_get_optional_field(part2, 'LiteratureBenchmarkAudit', struct());
    summary.baseflow_reference_table = local_get_optional_field(part2, 'BaseflowReferenceTable', table());
    summary.part2_diagnostics = part2.Part2Diagnostics;
    summary.matrix_report = matrix_report;
    summary.operator_audit = local_get_optional_field(part3, 'OperatorAudit', struct());
    summary.operator_health = local_get_optional_field(part3, 'OperatorHealth', struct('row_ratio_before', NaN, 'shock_to_nonshock_row_ratio', NaN));
    summary.bc_row_audit = local_get_optional_field(part3, 'BCRowAudit', struct());
    summary.shock_info = local_get_optional_field(part3, 'ShockInfo', struct('coverage_fraction', NaN));
    summary.derivative_clip_info = local_get_optional_field(part3, 'DerivativeClipInfo', struct('total_clipped', 0, 'total_zeroed', 0));
    summary.sav_info = local_get_optional_field(part3, 'SavInfo', struct('active_rows', 0, 'active_points', 0));
    summary.beta_assembly_audit = local_get_optional_field(part3, 'BetaAssemblyAudit', struct('has_spanwise_terms', false));
    summary.pressure_closure_audit = local_get_optional_field(part3, 'PressureClosureAudit', struct());
    summary.pressure_row_audit = local_get_optional_field(part3, 'PressureRowAudit', struct('enabled', false, 'total_clipped', 0, 'total_zeroed', 0));
    summary.post_bc_ablation_audit = local_get_optional_field(part3, 'PostBCAblationAudit', struct());
    summary.operator_ablation_table = local_get_optional_field(part3, 'OperatorAblationTable', table());
    summary.part3_variant_requested = case_identity.part3_variant_requested;
    summary.part3_variant_used = case_identity.part3_variant_used;
    summary.run_part4_requested = logical(opts.RunPart4);
    summary.reuse_existing_case = logical(opts.ReuseExistingCase);
    summary.stage_completed = 'Part3';
    summary.has_part4 = false;
end

function top_modes = local_build_top_modes(part4)
%LOCAL_BUILD_TOP_MODES Build the compact top-mode summary array.

    n_show = min(5, numel(part4.EigVals_s));
    top_modes = repmat(struct( ...
        'index', 0, ...
        'sigma_r', 0.0, ...
        'sigma_i', 0.0, ...
        'freq_nd', 0.0, ...
        'freq_signed', 0.0, ...
        'residual', 0.0, ...
        'residual_active', 0.0, ...
        'residual_algebraic', 0.0, ...
        'residual_scaled', 0.0, ...
        'bubble_overlap', 0.0, ...
        'wall_energy_frac', 0.0, ...
        'near_wall_energy_frac', 0.0, ...
        'free_stream_energy_frac', 0.0, ...
        'sponge_energy_frac', 0.0, ...
        'outlet_energy_frac', 0.0, ...
        'outlet_wall_energy_frac', 0.0, ...
        'shock_energy_frac', 0.0, ...
        'checker_ratio', 0.0, ...
        'farfield_ratio', 0.0, ...
        'highfreq_ratio', 0.0, ...
        'mode_family', '', ...
        'physical_candidate_score', NaN, ...
        'bubble_shock_phase_deg', NaN, ...
        'bubble_shock_sync', NaN, ...
        'reference_component', '', ...
        'selected_for_plots', false, ...
        'selected_for_publication', false), n_show, 1);

    for k = 1:n_show
        top_modes(k).index = k;
        top_modes(k).sigma_r = real(part4.EigVals_s(k));
        top_modes(k).sigma_i = imag(part4.EigVals_s(k));
        top_modes(k).freq_nd = part4.St_s(k);
        top_modes(k).freq_signed = part4.freq_signed_s(k);
        top_modes(k).residual = part4.res_s(k);
        top_modes(k).residual_active = part4.res_active_s(k);
        top_modes(k).residual_algebraic = part4.res_algebraic_s(k);
        top_modes(k).residual_scaled = part4.res_scaled_s(k);
        top_modes(k).bubble_overlap = part4.bubble_overlap_s(k);
        top_modes(k).wall_energy_frac = part4.wall_energy_frac_s(k);
        top_modes(k).near_wall_energy_frac = part4.near_wall_energy_frac_s(k);
        top_modes(k).free_stream_energy_frac = part4.free_stream_energy_frac_s(k);
        top_modes(k).sponge_energy_frac = part4.sponge_energy_frac_s(k);
        top_modes(k).outlet_energy_frac = part4.outlet_energy_frac_s(k);
        top_modes(k).outlet_wall_energy_frac = part4.outlet_wall_energy_frac_s(k);
        top_modes(k).shock_energy_frac = part4.shock_energy_frac_s(k);
        top_modes(k).checker_ratio = part4.checker_ratio_s(k);
        top_modes(k).farfield_ratio = part4.farfield_ratio_s(k);
        top_modes(k).highfreq_ratio = part4.highfreq_ratio_s(k);
        top_modes(k).mode_family = local_pick_vector_entry(part4.ModeFamily_s, k, '');
        top_modes(k).physical_candidate_score = local_pick_vector_entry(part4.physical_candidate_score_s, k, NaN);
        top_modes(k).bubble_shock_phase_deg = local_pick_vector_entry(part4.bubble_shock_phase_deg_s, k, NaN);
        top_modes(k).bubble_shock_sync = local_pick_vector_entry(part4.bubble_shock_sync_s, k, NaN);
        top_modes(k).reference_component = local_pick_coupling_field(part4.ModeCouplingAudit, k, 'reference_component', '');
        top_modes(k).selected_for_plots = logical(part4.ranking_table.selected_for_plots(k));
        top_modes(k).selected_for_publication = logical(part4.ranking_table.selected_for_publication(k));
    end
end

function case_identity = local_build_case_identity(project_root, baseflow_file, opts, requested_part3_variant, part3_variant_used)
%LOCAL_BUILD_CASE_IDENTITY Capture the immutable identity of one saved case.

    case_identity = struct();
    case_identity.baseflow_file = char(string(baseflow_file));
    case_identity.baseflow_file_token = local_normalize_path_token(baseflow_file);
    case_identity.baseflow_file_display = local_display_baseflow_path(baseflow_file, project_root);
    case_identity.expected_dims = double(opts.ExpectedDims(:)).';
    case_identity.stride = [double(opts.StrideX), double(opts.StrideY)];
    case_identity.top_type = char(string(opts.TopType));
    case_identity.benchmark_profile = char(string(opts.BenchmarkProfile));
    case_identity.wall_model = local_resolve_wall_model_option(opts.WallModel);
    case_identity.part3_variant_requested = requested_part3_variant;
    case_identity.part3_variant_used = part3_variant_used;
end

function metadata = local_build_runner_case_metadata(case_identity)
%LOCAL_BUILD_RUNNER_CASE_METADATA Build one small MAT payload for reuse-safe provenance.

    metadata = struct();
    metadata.schema_version = 1;
    metadata.created_at = datestr(now, 'yyyy-mm-ddTHH:MM:SS');
    metadata.case_identity = case_identity;
end

function local_save_runner_case_metadata(metadata_file, metadata)
%LOCAL_SAVE_RUNNER_CASE_METADATA Persist the reuse-safe provenance payload.

    RunnerCaseMetadata = metadata; %#ok<NASGU>
    save(metadata_file, 'RunnerCaseMetadata', '-v7.3');
end

function metadata = local_load_runner_case_metadata(metadata_file, case_dir)
%LOCAL_LOAD_RUNNER_CASE_METADATA Load one saved provenance payload or fail hard.

    if exist(metadata_file, 'file') ~= 2
        error('run_user_test_baseflow_fullres_v6:MissingReuseMetadata', ...
            ['ReuseExistingCase=true but %s is missing in case directory: %s\n' ...
             'Re-run the case once with ReuseExistingCase=false to seed explicit provenance.'], ...
            'RunnerCaseMetadata.mat', case_dir);
    end
    data = load(metadata_file, 'RunnerCaseMetadata');
    if ~isfield(data, 'RunnerCaseMetadata') || ~isstruct(data.RunnerCaseMetadata) || ...
            ~isfield(data.RunnerCaseMetadata, 'case_identity')
        error('run_user_test_baseflow_fullres_v6:InvalidReuseMetadata', ...
            'RunnerCaseMetadata.mat is malformed in case directory: %s', case_dir);
    end
    metadata = data.RunnerCaseMetadata;
end

function local_validate_reuse_request(opts, requested_part3_variant, baseflow_file, Config, metadata, case_dir)
%LOCAL_VALIDATE_REUSE_REQUEST Reject reuse when current inputs do not match the saved case.

    requested = local_build_effective_reuse_request(opts, requested_part3_variant, baseflow_file);
    Config = local_normalize_runner_config(Config);
    mismatches = {};

    mismatches = local_collect_mismatch(mismatches, 'BaseflowFile', ...
        metadata.case_identity.baseflow_file_token, requested.baseflow_file_token);
    mismatches = local_collect_mismatch(mismatches, 'ExpectedDims', ...
        [Config.Nx_raw, Config.Ny_raw], requested.expected_dims);
    mismatches = local_collect_mismatch(mismatches, 'Stride', ...
        [Config.ds_x, Config.ds_y], requested.stride);
    mismatches = local_collect_mismatch(mismatches, 'TopType', ...
        Config.boundary_map.north, requested.top_type);
    mismatches = local_collect_mismatch(mismatches, 'BenchmarkProfile', ...
        local_get_optional_field(Config, 'benchmark_profile', ''), requested.benchmark_profile);
    mismatches = local_collect_mismatch(mismatches, 'MachInf', Config.Ma_inf, requested.mach_inf);
    mismatches = local_collect_mismatch(mismatches, 'ReInf', Config.Re_inf, requested.re_inf);
    mismatches = local_collect_mismatch(mismatches, 'TInf', Config.T_inf, requested.t_inf);
    mismatches = local_collect_mismatch(mismatches, 'Gamma', Config.gamma, requested.gamma);
    mismatches = local_collect_mismatch(mismatches, 'Pr', Config.Pr, requested.pr);
    mismatches = local_collect_mismatch(mismatches, 'WallModel', Config.wall_model, requested.wall_model);
    mismatches = local_collect_mismatch(mismatches, 'WallTemperature', Config.T_wall, requested.wall_temperature);
    mismatches = local_collect_mismatch(mismatches, 'Beta', Config.beta, requested.beta);
    mismatches = local_collect_mismatch(mismatches, 'NEigs', Config.n_eigs, requested.n_eigs);
    mismatches = local_collect_mismatch(mismatches, 'SigmaShift', Config.sigma, requested.sigma_shift);
    mismatches = local_collect_mismatch(mismatches, 'SigmaTriplet', Config.sigma_triplet, requested.sigma_triplet);
    mismatches = local_collect_mismatch(mismatches, 'KrylovDimensionFloor', ...
        Config.krylov_dimension_floor, requested.krylov_dimension_floor);
    mismatches = local_collect_mismatch(mismatches, 'KrylovDimensionCap', ...
        Config.krylov_dimension_cap, requested.krylov_dimension_cap);
    mismatches = local_collect_mismatch(mismatches, 'ForceLowMemoryDescriptor', ...
        local_get_descriptor_solver_field(Config, 'large_system_threshold', 4.0e5) <= 1, ...
        requested.force_low_memory_descriptor);
    mismatches = local_collect_mismatch(mismatches, 'UseSponge', Config.use_sponge, requested.use_sponge);
    mismatches = local_collect_mismatch(mismatches, 'UseSemiArtificialViscosity', ...
        Config.use_semi_artificial_viscosity, requested.use_semi_artificial_viscosity);
    mismatches = local_collect_mismatch(mismatches, 'SavEpsilon', ...
        Config.semi_artificial_viscosity.epsilon, requested.sav_epsilon);
    mismatches = local_collect_mismatch(mismatches, 'SavShockPercentile', ...
        Config.semi_artificial_viscosity.shock_percentile, requested.sav_shock_percentile);
    mismatches = local_collect_mismatch(mismatches, 'SavDilationSteps', ...
        Config.semi_artificial_viscosity.dilation_steps, requested.sav_dilation_steps);
    mismatches = local_collect_mismatch(mismatches, 'SavNearWallFraction', ...
        Config.semi_artificial_viscosity.near_wall_fraction, requested.sav_near_wall_fraction);
    mismatches = local_collect_mismatch(mismatches, 'UseShockSourceRegularization', ...
        Config.use_shock_source_regularization, requested.use_shock_source_regularization);
    mismatches = local_collect_mismatch(mismatches, 'ShockClipPercentile', ...
        Config.shock_source_regularization.clip_percentile, requested.shock_clip_percentile);
    mismatches = local_collect_mismatch(mismatches, 'ShockDmuClipPercentile', ...
        Config.shock_source_regularization.dmu_clip_percentile, requested.shock_dmu_clip_percentile);
    mismatches = local_collect_mismatch(mismatches, 'ZeroSecondDerivativesInShock', ...
        Config.shock_source_regularization.zero_second_derivatives_in_shock, requested.zero_second_derivatives_in_shock);
    mismatches = local_collect_mismatch(mismatches, 'SuppressViscosityGradientTermsInShock', ...
        Config.shock_source_regularization.suppress_viscosity_gradient_terms_in_shock, ...
        requested.suppress_viscosity_gradient_terms_in_shock);
    mismatches = local_collect_mismatch(mismatches, 'UsePressureRowRegularization', ...
        Config.pressure_row_regularization.enabled, requested.use_pressure_row_regularization);
    mismatches = local_collect_mismatch(mismatches, 'PressureGradientClipPercentile', ...
        Config.pressure_row_regularization.gradient_clip_percentile, requested.pressure_gradient_clip_percentile);
    mismatches = local_collect_mismatch(mismatches, 'PressureDivergenceClipPercentile', ...
        Config.pressure_row_regularization.divergence_clip_percentile, requested.pressure_divergence_clip_percentile);
    mismatches = local_collect_mismatch(mismatches, 'SuppressPressureGradientsInShock', ...
        Config.pressure_row_regularization.suppress_pressure_gradients_in_shock, requested.suppress_pressure_gradients_in_shock);
    mismatches = local_collect_mismatch(mismatches, 'SuppressPressureDivergenceInShock', ...
        Config.pressure_row_regularization.suppress_divergence_in_shock, requested.suppress_pressure_divergence_in_shock);
    mismatches = local_collect_mismatch(mismatches, 'Part3Variant', ...
        metadata.case_identity.part3_variant_used, requested.part3_variant_requested);

    if ~isempty(mismatches)
        error('run_user_test_baseflow_fullres_v6:ReuseMismatch', ...
            'ReuseExistingCase=true but the requested settings do not match the saved case in %s:%s- %s', ...
            case_dir, newline, strjoin(mismatches, [newline '- ']));
    end
end

function requested = local_build_effective_reuse_request(opts, requested_part3_variant, baseflow_file)
%LOCAL_BUILD_EFFECTIVE_REUSE_REQUEST Resolve one reuse request to effective solver settings.

    requested = struct();
    requested.baseflow_file_token = local_normalize_path_token(baseflow_file);
    requested.expected_dims = double(opts.ExpectedDims(:)).';
    requested.stride = [double(opts.StrideX), double(opts.StrideY)];
    requested.top_type = char(string(opts.TopType));
    requested.benchmark_profile = char(string(opts.BenchmarkProfile));
    requested.mach_inf = local_resolve_optional_override(opts.MachInf, 7.0);
    requested.re_inf = local_resolve_optional_override(opts.ReInf, 1.0e5);
    requested.t_inf = local_resolve_optional_override(opts.TInf, 191.0);
    requested.gamma = local_resolve_optional_override(opts.Gamma, 1.4);
    requested.pr = local_resolve_optional_override(opts.Pr, 0.71);
    requested.wall_model = local_resolve_wall_model_option(opts.WallModel);
    requested.wall_temperature = local_resolve_optional_override(opts.WallTemperature, 298.0);
    requested.beta = opts.Beta;
    requested.n_eigs = round(opts.NEigs);
    requested.sigma_shift = opts.SigmaShift;
    if isempty(opts.SigmaTriplet)
        requested.sigma_triplet = [0.00 + 0.005i, 0.00 + 0.010i, 0.00 + 0.020i, 0.02 + 0.020i, 0.05 + 0.020i];
    else
        requested.sigma_triplet = opts.SigmaTriplet(:).';
    end
    if isempty(opts.KrylovDimensionFloor)
        requested.krylov_dimension_floor = 120;
    else
        requested.krylov_dimension_floor = round(opts.KrylovDimensionFloor);
    end
    if isempty(opts.KrylovDimensionCap)
        requested.krylov_dimension_cap = 180;
    else
        requested.krylov_dimension_cap = round(opts.KrylovDimensionCap);
    end
    requested.force_low_memory_descriptor = logical(opts.ForceLowMemoryDescriptor);
    requested.use_sponge = logical(opts.UseSponge);
    requested.use_semi_artificial_viscosity = local_resolve_optional_override(opts.UseSemiArtificialViscosity, true);
    requested.sav_epsilon = local_resolve_optional_override(opts.SavEpsilon, 5.0e-2);
    requested.sav_shock_percentile = local_resolve_optional_override(opts.SavShockPercentile, 85.0);
    requested.sav_dilation_steps = local_resolve_optional_override(opts.SavDilationSteps, 5);
    requested.sav_near_wall_fraction = local_resolve_optional_override(opts.SavNearWallFraction, 0.10);
    requested.use_shock_source_regularization = local_resolve_optional_override(opts.UseShockSourceRegularization, false);
    requested.shock_clip_percentile = local_resolve_optional_override(opts.ShockClipPercentile, 95.0);
    requested.shock_dmu_clip_percentile = local_resolve_optional_override(opts.ShockDmuClipPercentile, 95.0);
    requested.zero_second_derivatives_in_shock = local_resolve_optional_override(opts.ZeroSecondDerivativesInShock, true);
    requested.suppress_viscosity_gradient_terms_in_shock = ...
        local_resolve_optional_override(opts.SuppressViscosityGradientTermsInShock, true);
    requested.use_pressure_row_regularization = local_resolve_optional_override(opts.UsePressureRowRegularization, false);
    requested.pressure_gradient_clip_percentile = ...
        local_resolve_optional_override(opts.PressureGradientClipPercentile, 95.0);
    requested.pressure_divergence_clip_percentile = ...
        local_resolve_optional_override(opts.PressureDivergenceClipPercentile, 95.0);
    requested.suppress_pressure_gradients_in_shock = ...
        local_resolve_optional_override(opts.SuppressPressureGradientsInShock, false);
    requested.suppress_pressure_divergence_in_shock = ...
        local_resolve_optional_override(opts.SuppressPressureDivergenceInShock, false);
    requested.part3_variant_requested = requested_part3_variant;
end

function mismatches = local_collect_mismatch(mismatches, label, saved_value, requested_value)
%LOCAL_COLLECT_MISMATCH Append one human-readable mismatch line when values differ.

    if ~local_values_match(saved_value, requested_value)
        mismatches{end+1} = sprintf('%s requested=%s saved=%s', ... %#ok<AGROW>
            label, local_format_value(requested_value), local_format_value(saved_value));
    end
end

function value = local_resolve_optional_override(override_value, default_value)
%LOCAL_RESOLVE_OPTIONAL_OVERRIDE Resolve one runner override against its default.

    if isempty(override_value)
        value = default_value;
    else
        value = override_value;
    end
end

function wall_model = local_resolve_wall_model_option(override_value)
%LOCAL_RESOLVE_WALL_MODEL_OPTION Resolve one wall-model option with defaults.

    if strlength(string(override_value)) == 0
        wall_model = 'adiabatic';
    else
        wall_model = char(string(override_value));
    end
    wall_model = normalize_wall_model(wall_model, ...
        'ErrorIdentifier', 'run_user_test_baseflow_fullres_v6:WallModel');
end

function value = local_get_descriptor_solver_field(Config, name, default_value)
%LOCAL_GET_DESCRIPTOR_SOLVER_FIELD Read one descriptor-solver field with fallback.

    value = default_value;
    if isstruct(Config) && isfield(Config, 'descriptor_solver') && isstruct(Config.descriptor_solver) && ...
            isfield(Config.descriptor_solver, name)
        candidate = Config.descriptor_solver.(name);
        if isnumeric(candidate) && isscalar(candidate) && isfinite(candidate)
            value = candidate;
        end
    end
end

function tf = local_values_match(lhs, rhs)
%LOCAL_VALUES_MATCH Compare numeric/string/logical settings with one tight tolerance.

    if isnumeric(lhs) || islogical(lhs)
        if ~(isnumeric(rhs) || islogical(rhs))
            tf = false;
            return;
        end
        lhs = double(lhs(:));
        rhs = double(rhs(:));
        tf = isequal(size(lhs), size(rhs)) && all(abs(lhs - rhs) <= 1.0e-12);
    else
        tf = strcmp(char(string(lhs)), char(string(rhs)));
    end
end

function text = local_format_value(value)
%LOCAL_FORMAT_VALUE Convert one value into a compact error-message token.

    if isnumeric(value) || islogical(value)
        text = mat2str(value);
    else
        text = char(string(value));
    end
end

function token = local_normalize_path_token(path_value)
%LOCAL_NORMALIZE_PATH_TOKEN Normalize one path for case-identity comparison on Windows.

    token = char(string(path_value));
    if isempty(token)
        return;
    end
    try
        token = char(java.io.File(token).getCanonicalPath());
    catch
        % Leave the original path token in place when canonicalization fails.
    end
    token = lower(strrep(token, '/', filesep));
end

function part2 = local_load_part2_results(part2_file, Config)
%LOCAL_LOAD_PART2_RESULTS Load Part2 outputs with backward-compatible field selection.

    info = whos('-file', part2_file);
    available = {info.name};
    requested = {'Part2Diagnostics', 'BaseflowPhysicsAudit', 'GeometryAudit', ...
        'LiteratureBenchmarkAudit', 'BaseflowReferenceTable'};
    requested = requested(ismember(requested, available));
    if isempty(requested)
        part2 = struct();
    else
        part2 = load(part2_file, requested{:});
    end
    part2 = local_backfill_part2_fields(part2, Config);
end

function part2 = local_backfill_part2_fields(part2, Config)
%LOCAL_BACKFILL_PART2_FIELDS Keep the runner compatible with older Part2 results.

    if ~isfield(part2, 'Part2Diagnostics') || ~isstruct(part2.Part2Diagnostics)
        part2.Part2Diagnostics = struct();
    end
    if ~isfield(part2, 'BaseflowPhysicsAudit') || ~isstruct(part2.BaseflowPhysicsAudit)
        part2.BaseflowPhysicsAudit = struct();
    end
    if ~isfield(part2, 'GeometryAudit') || ~isstruct(part2.GeometryAudit)
        part2.GeometryAudit = struct();
    end

    part2.BaseflowPhysicsAudit = local_ensure_struct_field(part2.BaseflowPhysicsAudit, 'eos_relative_error', NaN);
    part2.BaseflowPhysicsAudit = local_ensure_struct_field(part2.BaseflowPhysicsAudit, 'wall_model', 'adiabatic');
    part2.BaseflowPhysicsAudit = local_ensure_struct_field(part2.BaseflowPhysicsAudit, 'wall_temperature_target', NaN);
    part2.BaseflowPhysicsAudit = local_ensure_struct_field(part2.BaseflowPhysicsAudit, 'wall_temperature_target_nd', NaN);
    part2.BaseflowPhysicsAudit = local_ensure_struct_field(part2.BaseflowPhysicsAudit, 'wall_temperature_check_applied', false);
    part2.BaseflowPhysicsAudit = local_ensure_struct_field(part2.BaseflowPhysicsAudit, 'wall_temperature_relative_mismatch', NaN);
    part2.BaseflowPhysicsAudit = local_ensure_struct_field(part2.BaseflowPhysicsAudit, 'continuity_residual_max', NaN);
    part2.BaseflowPhysicsAudit = local_ensure_struct_field(part2.BaseflowPhysicsAudit, 'bubble_exists', false);
    part2.BaseflowPhysicsAudit = local_ensure_struct_field(part2.BaseflowPhysicsAudit, 'separation_x', NaN);
    part2.BaseflowPhysicsAudit = local_ensure_struct_field(part2.BaseflowPhysicsAudit, 'reattachment_x', NaN);
    part2.BaseflowPhysicsAudit = local_ensure_struct_field(part2.BaseflowPhysicsAudit, 'bubble_length', NaN);
    part2.BaseflowPhysicsAudit = local_ensure_struct_field(part2.BaseflowPhysicsAudit, 'delta99_at_separation', NaN);

    if ~isfield(part2, 'LiteratureBenchmarkAudit') || ~isstruct(part2.LiteratureBenchmarkAudit) || ...
            isempty(fieldnames(part2.LiteratureBenchmarkAudit))
        part2.LiteratureBenchmarkAudit = local_build_legacy_literature_benchmark_audit( ...
            Config, part2.BaseflowPhysicsAudit, part2.GeometryAudit);
    end
    if ~isfield(part2, 'BaseflowReferenceTable') || ~istable(part2.BaseflowReferenceTable)
        part2.BaseflowReferenceTable = local_build_legacy_baseflow_reference_table( ...
            Config, part2.BaseflowPhysicsAudit);
    end
end

function audit = local_build_legacy_literature_benchmark_audit(Config, BaseflowPhysicsAudit, GeometryAudit)
%LOCAL_BUILD_LEGACY_LITERATURE_BENCHMARK_AUDIT Infer a minimal literature audit from legacy files.

    reference_scales = local_get_optional_field(Config, 'reference_scales', struct('defined', false));
    boundary_contract = local_get_optional_field(GeometryAudit, 'boundary_contract', struct());
    config_top = '';
    if isfield(Config, 'boundary_map') && isstruct(Config.boundary_map) && isfield(Config.boundary_map, 'north')
        config_top = char(string(Config.boundary_map.north));
    end
    geometry_top = '';
    if isstruct(boundary_contract) && isfield(boundary_contract, 'top')
        geometry_top = char(string(boundary_contract.top));
    elseif isstruct(boundary_contract) && isfield(boundary_contract, 'north')
        geometry_top = char(string(boundary_contract.north));
    end

    audit = struct();
    audit.target_benchmark = local_get_optional_field(Config, 'target_benchmark', 'Sidharth2018');
    audit.benchmark_profile = local_get_optional_field(Config, 'benchmark_profile', 'sidharth2018_code_correction_v1');
    audit.boundary_contract_match = isempty(config_top) || isempty(geometry_top) || strcmpi(config_top, geometry_top);
    audit.reference_scales_defined = local_reference_scales_defined(reference_scales);
    audit.profile_target_match = strcmpi(audit.target_benchmark, 'Sidharth2018');
    audit.structural_only = logical(local_get_optional_field(Config, 'structural_only', true));
    audit.physics_reproduction_ready = audit.reference_scales_defined && ~audit.structural_only;
    audit.reason = 'legacy_part2_results_missing_literature_audit';
    if audit.structural_only
        audit.reason = 'legacy_part2_results_defaulted_to_structural_only';
    elseif ~audit.reference_scales_defined
        audit.reason = 'legacy_part2_results_missing_reference_scale_contract';
    end
    audit.bubble_exists = logical(local_get_optional_field(BaseflowPhysicsAudit, 'bubble_exists', false));
end

function tbl = local_build_legacy_baseflow_reference_table(Config, BaseflowPhysicsAudit)
%LOCAL_BUILD_LEGACY_BASEFLOW_REFERENCE_TABLE Build a minimal compare table from legacy Part2 fields.

    wall_bc = '';
    if isfield(Config, 'boundary_map') && isstruct(Config.boundary_map) && isfield(Config.boundary_map, 'south')
        wall_bc = char(string(Config.boundary_map.south));
    end

    names = {'geometry'; 'Mach'; 'Re'; 'wall_bc'; 'wall_temperature'; ...
        'separation_x'; 'reattachment_x'; 'bubble_length'; 'delta99_at_separation'};
    values = { ...
        local_get_optional_field(Config, 'geometry_name', 'double_wedge'); ...
        local_format_summary_value(local_get_optional_field(Config, 'Ma_inf', NaN)); ...
        local_format_summary_value(local_get_optional_field(Config, 'Re_inf', NaN)); ...
        local_get_optional_field(Config, 'wall_model', wall_bc); ...
        local_format_summary_value(local_get_optional_field(Config, 'T_wall', NaN)); ...
        local_format_summary_value(local_get_optional_field(BaseflowPhysicsAudit, 'separation_x', NaN)); ...
        local_format_summary_value(local_get_optional_field(BaseflowPhysicsAudit, 'reattachment_x', NaN)); ...
        local_format_summary_value(local_get_optional_field(BaseflowPhysicsAudit, 'bubble_length', NaN)); ...
        local_format_summary_value(local_get_optional_field(BaseflowPhysicsAudit, 'delta99_at_separation', NaN))};
    tbl = table(string(names), string(values), 'VariableNames', {'item', 'value'});
end

function local_write_summary_text(output_file, summary, top_modes)
%LOCAL_WRITE_SUMMARY_TEXT Write a compact text summary next to the case outputs.

    fid = open_output_text_file(output_file);
    if fid == -1
        warning('run_user_test_baseflow_fullres_v6:SummaryWrite', ...
            'Unable to write summary text file: %s', output_file);
        return;
    end

    cleanup_obj = onCleanup(@() fclose(fid)); %#ok<NASGU>

    fprintf(fid, '%s\n', localize_output_label('User test baseflow full-resolution v6 run'));
    fprintf(fid, '%s: %s\n', localize_output_label('run_stage'), summary.stage_completed);
    fprintf(fid, '%s: %s\n', localize_output_label('baseflow_file'), summary.baseflow_file);
    fprintf(fid, '%s: %s\n', localize_output_label('case_dir'), summary.case_dir);
    fprintf(fid, '%s: %s\n', localize_output_label('figure_directory'), summary.figure_directory);
    fprintf(fid, '%s: %d\n', localize_output_label('reuse_existing_case'), summary.reuse_existing_case);
    fprintf(fid, '%s: %d x %d\n', localize_output_label('expected_dims'), summary.expected_dims(1), summary.expected_dims(2));
    fprintf(fid, '%s: %d x %d\n', localize_output_label('working_dims'), summary.working_dims(1), summary.working_dims(2));
    fprintf(fid, '%s: %d x %d\n', localize_output_label('stride'), summary.stride(1), summary.stride(2));
    fprintf(fid, '%s: %s\n', localize_output_label('top_type'), summary.top_type);
    fprintf(fid, '%s: %s\n', localize_output_label('benchmark_profile'), local_format_summary_value(summary.benchmark_profile));
    fprintf(fid, '%s: %s\n', localize_output_label('target_benchmark'), local_format_summary_value(summary.target_benchmark));
    fprintf(fid, '%s: %s\n', localize_output_label('primary_plot_contract'), local_format_summary_value(summary.primary_plot_contract));
    fprintf(fid, '%s: %s\n', localize_output_label('secondary_plot_contract'), local_format_summary_value(summary.secondary_plot_contract));
    fprintf(fid, '%s: %s\n', localize_output_label('state_layout'), summary.state_layout);
    fprintf(fid, '%s: %s\n', localize_output_label('operator_model'), summary.operator_model);
    fprintf(fid, '%s: %.6g\n', localize_output_label('Ma_inf'), summary.Ma_inf);
    fprintf(fid, '%s: %.6g\n', localize_output_label('Re_inf'), summary.Re_inf);
    fprintf(fid, '%s: %.6g\n', localize_output_label('T_inf'), summary.T_inf);
    fprintf(fid, '%s: %.6g\n', localize_output_label('gamma'), summary.gamma);
    fprintf(fid, '%s: %.6g\n', localize_output_label('Pr'), summary.Pr);
    fprintf(fid, '%s: %s\n', localize_output_label('wall_model'), summary.wall_model);
    fprintf(fid, '%s: %.6g\n', localize_output_label('T_wall'), summary.T_wall);
    fprintf(fid, '%s: %.6g\n', localize_output_label('T_wall_nd'), summary.T_wall_nd);
    fprintf(fid, '%s: %s\n', localize_output_label('part3_variant_requested'), summary.part3_variant_requested);
    fprintf(fid, '%s: %s\n', localize_output_label('part3_variant_used'), summary.part3_variant_used);
    fprintf(fid, '%s: %d\n', localize_output_label('n_eigs'), summary.n_eigs);
    fprintf(fid, '%s: %.6f\n', localize_output_label('beta'), summary.beta);
    fprintf(fid, '%s: %d\n', localize_output_label('use_sponge'), summary.use_sponge);
    fprintf(fid, '%s: %d\n', localize_output_label('use_semi_artificial_viscosity'), summary.use_semi_artificial_viscosity);
    fprintf(fid, '%s: %d\n', localize_output_label('use_shock_source_regularization'), summary.use_shock_source_regularization);
    fprintf(fid, '%s: %d\n', localize_output_label('pressure_row_regularization_enabled'), summary.pressure_row_regularization.enabled);
    fprintf(fid, '%s: %+.6e%+.6ei\n', localize_output_label('sigma_shift'), real(summary.sigma_shift), imag(summary.sigma_shift));
    fprintf(fid, '%s: [', localize_output_label('sigma_triplet'));
    for k = 1:numel(summary.sigma_triplet)
        fprintf(fid, '%+.3e%+.3ei', real(summary.sigma_triplet(k)), imag(summary.sigma_triplet(k)));
        if k < numel(summary.sigma_triplet)
            fprintf(fid, ', ');
        end
    end
    fprintf(fid, ']\n');
    fprintf(fid, '%s: %.6e\n', localize_output_label('base_eos_relative_error'), summary.baseflow_physics_audit.eos_relative_error);
    fprintf(fid, '%s: %s\n', localize_output_label('base_wall_model'), local_format_summary_value(summary.baseflow_physics_audit.wall_model));
    fprintf(fid, '%s: %d\n', localize_output_label('base_wall_temperature_check_applied'), summary.baseflow_physics_audit.wall_temperature_check_applied);
    fprintf(fid, '%s: %.6g\n', localize_output_label('base_wall_temperature_target'), summary.baseflow_physics_audit.wall_temperature_target);
    fprintf(fid, '%s: %.6g\n', localize_output_label('base_wall_temperature_target_nd'), summary.baseflow_physics_audit.wall_temperature_target_nd);
    fprintf(fid, '%s: %.6e\n', localize_output_label('base_wall_temperature_relative_mismatch'), ...
        summary.baseflow_physics_audit.wall_temperature_relative_mismatch);
    fprintf(fid, '%s: %.6e\n', localize_output_label('continuity_residual_max'), summary.baseflow_physics_audit.continuity_residual_max);
    fprintf(fid, '%s: %d\n', localize_output_label('bubble_exists'), summary.baseflow_physics_audit.bubble_exists);
    local_write_named_fields(fid, 'Literature benchmark audit', summary.literature_benchmark_audit, { ...
        'benchmark_profile', 'target_benchmark', 'boundary_contract_match', ...
        'reference_scales_defined', 'profile_target_match', ...
        'structural_only', 'physics_reproduction_ready', 'reason'});
    local_write_table_block(fid, 'Baseflow reference table', summary.baseflow_reference_table);

    if strcmp(summary.stage_completed, 'Part4')
        fprintf(fid, '%s: %d\n', localize_output_label('leading_mode_available'), summary.leading_mode_available);
        fprintf(fid, '%s: %g\n', localize_output_label('leading_mode_position'), summary.leading_mode_position);
        fprintf(fid, '%s: %g\n', localize_output_label('leading_mode_original_index'), summary.leading_mode_original_index);
        fprintf(fid, '%s: %s\n', localize_output_label('leading_mode_resolution_status'), ...
            local_format_summary_value(summary.leading_mode_resolution.status));
        fprintf(fid, '%s: %s\n', localize_output_label('leading_mode_resolution_source'), ...
            local_format_summary_value(summary.leading_mode_resolution.source));
        fprintf(fid, '%s: %+.6e%+.6ei\n', localize_output_label('leading_sigma'), summary.leading_sigma_r, summary.leading_sigma_i);
        fprintf(fid, '%s: %+.6f\n', localize_output_label('leading_freq_nd'), summary.leading_freq_nd);
        fprintf(fid, '%s: %+.6f\n', localize_output_label('leading_freq_signed'), summary.leading_freq_signed);
        fprintf(fid, '%s: %.6e\n', localize_output_label('leading_residual'), summary.leading_residual);
        fprintf(fid, '%s: %.6e\n', localize_output_label('leading_residual_active'), summary.leading_residual_active);
        fprintf(fid, '%s: %.6e\n', localize_output_label('leading_residual_algebraic'), summary.leading_residual_algebraic);
        fprintf(fid, '%s: %.6e\n', localize_output_label('leading_residual_scaled'), summary.leading_residual_scaled);
        fprintf(fid, '%s: %.6f\n', localize_output_label('leading_bubble_overlap'), summary.leading_bubble_overlap);
        fprintf(fid, '%s: %.6f\n', localize_output_label('leading_near_wall_energy_frac'), summary.leading_near_wall_energy_frac);
        fprintf(fid, '%s: %.6f\n', localize_output_label('leading_free_stream_energy_frac'), summary.leading_free_stream_energy_frac);
        fprintf(fid, '%s: %.6f\n', localize_output_label('leading_outlet_energy_frac'), summary.leading_outlet_energy_frac);
        fprintf(fid, '%s: %.6f\n', localize_output_label('leading_outlet_wall_energy_frac'), summary.leading_outlet_wall_energy_frac);
        fprintf(fid, '%s: %.6f\n', localize_output_label('leading_shock_energy_frac'), summary.leading_shock_energy_frac);
        fprintf(fid, '%s: %.6f\n', localize_output_label('leading_checker_ratio'), summary.leading_checker_ratio);
        fprintf(fid, '%s: %s\n', localize_output_label('leading_mode_family'), ...
            local_format_summary_value(summary.leading_mode_family));
        fprintf(fid, '%s: %.6f\n', localize_output_label('leading_physical_candidate_score'), summary.leading_physical_candidate_score);
        fprintf(fid, '%s: %.6f\n', localize_output_label('leading_bubble_shock_phase_deg'), summary.leading_bubble_shock_phase_deg);
        fprintf(fid, '%s: %.6f\n', localize_output_label('leading_bubble_shock_sync'), summary.leading_bubble_shock_sync);
        fprintf(fid, '%s: %s\n', localize_output_label('leading_reference_component'), summary.leading_reference_component);
        fprintf(fid, '%s: %d\n', localize_output_label('leading_selected_for_plots'), summary.leading_selected_for_plots);
        fprintf(fid, '%s: %d\n', localize_output_label('leading_selected_for_publication'), summary.leading_selected_for_publication);
        fprintf(fid, '%s: %s\n', localize_output_label('selection_status'), ...
            local_format_summary_value(summary.selection_summary.status));
        fprintf(fid, '%s: %d\n', localize_output_label('publication_allowed'), summary.mode_validity_report.publication_allowed);
        fprintf(fid, '%s: %s\n', localize_output_label('mode_validity_primary_reason'), ...
            local_format_summary_value(summary.mode_validity_report.primary_reason));
        fprintf(fid, '%s: %d\n', localize_output_label('adjoint_lead_enabled'), summary.adjoint_lead_audit.enabled);
        if isfield(summary.adjoint_lead_audit, 'reason')
            fprintf(fid, '%s: %s\n', localize_output_label('adjoint_lead_reason'), ...
                local_format_summary_value(summary.adjoint_lead_audit.reason));
        end
        if isfield(summary.adjoint_lead_audit, 'wavemaker_bubble_frac')
            fprintf(fid, '%s: %.6f\n', localize_output_label('wavemaker_bubble_frac'), summary.adjoint_lead_audit.wavemaker_bubble_frac);
        end
        if isfield(summary.adjoint_lead_audit, 'wavemaker_shock_frac')
            fprintf(fid, '%s: %.6f\n', localize_output_label('wavemaker_shock_frac'), summary.adjoint_lead_audit.wavemaker_shock_frac);
        end
        fprintf(fid, '%s: %.6e\n', localize_output_label('matrix_row_ratio_before'), summary.matrix_health.row_norm_ratio_before);
        fprintf(fid, '%s: %.6e\n', localize_output_label('matrix_row_ratio_after'), summary.matrix_health.row_norm_ratio_after);
        fprintf(fid, '%s: %d\n', localize_output_label('matrix_zero_rows'), numel(summary.matrix_report.zero_rows));
        fprintf(fid, '%s: %d\n', localize_output_label('matrix_zero_cols'), numel(summary.matrix_report.zero_cols));
        local_write_table_block(fid, 'Mode reference table', summary.mode_reference_table);
        local_write_table_block(fid, 'Eigen reference table', summary.eigen_reference_table);
        local_write_table_block(fid, 'Figure criteria table', summary.figure_criteria_table);
        local_write_component_audit_block(fid, summary.component_mode_audit, summary.leading_mode_position);
        local_write_named_fields(fid, 'Plot provenance audit', summary.plot_provenance_audit, { ...
            'has_plot_lead', 'plot_mode_position', 'reference_component', ...
            'normalization', 'normalization_scale', ...
            'phase_anchor_type', 'phase_anchor_x', 'phase_anchor_y', ...
            'target_benchmark'});
        local_write_named_fields(fid, 'Plot contract audit', summary.plot_contract_audit, { ...
            'primary_plot_contract', 'secondary_plot_contract', 'target_benchmark', ...
            'selection_status', 'plot_status', 'has_plot_lead', ...
            'reference_component', 'normalization', 'normalization_scale', ...
            'phase_anchor_type', 'phase_anchor_x', 'phase_anchor_y', ...
            'figure_status', 'sidharth_component_contract', ...
            'sidharth_gallery_component'});
        local_write_named_fields(fid, 'Figure audit', summary.figure_audit, { ...
            'lead_plot_index', 'status', 'num_gallery_pages', 'sidharth_gallery_pages', ...
            'sidharth_component_contract', 'sidharth_gallery_component', ...
            'primary_plot_contract', 'secondary_plot_contract'});
        fprintf(fid, '\n%s:\n', localize_output_label('Top modes'));
        for k = 1:numel(top_modes)
            fprintf(fid, ['  #%d sigma=(%+.6e,%+.6e) 残差=%.6e 分离泡=%.6f 近壁=%.6f ' ...
                '自由流=%.6f 出口=%.6f 出口壁面=%.6f 激波=%.6f 棋盘比=%.6f 家族=%s 得分=%.6f 绘图=%d 发表=%d\n'], ...
                top_modes(k).index, top_modes(k).sigma_r, top_modes(k).sigma_i, ...
                top_modes(k).residual, top_modes(k).bubble_overlap, top_modes(k).near_wall_energy_frac, ...
                top_modes(k).free_stream_energy_frac, top_modes(k).outlet_energy_frac, ...
                top_modes(k).outlet_wall_energy_frac, top_modes(k).shock_energy_frac, ...
                top_modes(k).checker_ratio, top_modes(k).mode_family, top_modes(k).physical_candidate_score, ...
                top_modes(k).selected_for_plots, ...
                top_modes(k).selected_for_publication);
        end
    else
        fprintf(fid, '%s: %.6e\n', localize_output_label('operator_row_ratio_before'), summary.operator_health.row_ratio_before);
        fprintf(fid, '%s: %.6e\n', localize_output_label('operator_shock_to_nonshock_row_ratio'), summary.operator_health.shock_to_nonshock_row_ratio);
        fprintf(fid, '%s: %.6f\n', localize_output_label('shock_mask_coverage'), summary.shock_info.coverage_fraction);
        fprintf(fid, '%s: %d\n', localize_output_label('derivative_clip_total'), summary.derivative_clip_info.total_clipped);
        fprintf(fid, '%s: %d\n', localize_output_label('derivative_zero_total'), summary.derivative_clip_info.total_zeroed);
        fprintf(fid, '%s: %d\n', localize_output_label('sav_active_rows'), summary.sav_info.active_rows);
        fprintf(fid, '%s: %d\n', localize_output_label('sav_active_points'), summary.sav_info.active_points);
        fprintf(fid, '%s: %d\n', localize_output_label('beta_terms_active'), summary.beta_assembly_audit.has_spanwise_terms);
        fprintf(fid, '%s: %d\n', localize_output_label('pressure_row_total_clipped'), summary.pressure_row_audit.total_clipped);
        fprintf(fid, '%s: %d\n', localize_output_label('pressure_row_total_zeroed'), summary.pressure_row_audit.total_zeroed);
        if isfield(summary.pressure_closure_audit, 'rho_from_p_density_residual_max')
            fprintf(fid, '%s: %.6e\n', localize_output_label('pressure_closure_rho_from_p_density_residual_max'), ...
                summary.pressure_closure_audit.rho_from_p_density_residual_max);
        end
        if isfield(summary.pressure_closure_audit, 'pressure_scale_density_residual_max')
            fprintf(fid, '%s: %.6e\n', localize_output_label('pressure_closure_pressure_scale_density_residual_max'), ...
                summary.pressure_closure_audit.pressure_scale_density_residual_max);
        end
        if isfield(summary.pressure_closure_audit, 'linearized_eos_balance_residual_max')
            fprintf(fid, '%s: %.6e\n', localize_output_label('pressure_closure_linearized_eos_balance_residual_max'), ...
                summary.pressure_closure_audit.linearized_eos_balance_residual_max);
        end
        local_write_table_block(fid, 'Operator ablation table', summary.operator_ablation_table);
        local_write_named_fields(fid, 'Post-BC ablation audit', summary.post_bc_ablation_audit, { ...
            'num_boundary_rows', 'num_overwritten_rows', 'pressure_row_outside_shock_points'});
    end
end

function display_path = local_display_baseflow_path(baseflow_file, project_root)
%LOCAL_DISPLAY_BASEFLOW_PATH Prefer a stable repo-relative label in summaries.

    benchmark_file = fullfile(project_root, 'double_wedge_baseflow.dat');
    if strcmpi(char(string(baseflow_file)), benchmark_file)
        display_path = '[project_root]\\double_wedge_baseflow.dat';
    else
        display_path = baseflow_file;
    end
end

function solve_config = local_pick_solve_config(primary_struct, part1)
%LOCAL_PICK_SOLVE_CONFIG Prefer the actual solve config over the Part1 setup config.

    if isstruct(primary_struct) && isfield(primary_struct, 'Config') && isstruct(primary_struct.Config)
        solve_config = primary_struct.Config;
    else
        solve_config = part1.Config;
    end
end

function part4 = local_backfill_part4_fields(part4)
%LOCAL_BACKFILL_PART4_FIELDS Keep the summary runner compatible with older Part4 files.

    n_modes = numel(part4.EigVals_s);
    part4 = local_ensure_vector_field(part4, 'bubble_overlap_s', n_modes, 0.0);
    part4 = local_ensure_vector_field(part4, 'wall_energy_frac_s', n_modes, 0.0);
    part4 = local_ensure_vector_field(part4, 'near_wall_energy_frac_s', n_modes, 0.0);
    part4 = local_ensure_vector_field(part4, 'free_stream_energy_frac_s', n_modes, 0.0);
    part4 = local_ensure_vector_field(part4, 'sponge_energy_frac_s', n_modes, 0.0);
    part4 = local_ensure_vector_field(part4, 'shock_energy_frac_s', n_modes, 0.0);
    part4 = local_ensure_vector_field(part4, 'outlet_energy_frac_s', n_modes, 0.0);
    part4 = local_ensure_vector_field(part4, 'outlet_wall_energy_frac_s', n_modes, 0.0);
    part4 = local_ensure_vector_field(part4, 'checker_ratio_s', n_modes, 0.0);
    part4 = local_ensure_vector_field(part4, 'farfield_ratio_s', n_modes, 0.0);
    part4 = local_ensure_vector_field(part4, 'highfreq_ratio_s', n_modes, 0.0);
    part4 = local_ensure_vector_field(part4, 'physical_candidate_score_s', n_modes, NaN);
    part4 = local_ensure_vector_field(part4, 'bubble_shock_phase_deg_s', n_modes, NaN);
    part4 = local_ensure_vector_field(part4, 'bubble_shock_sync_s', n_modes, NaN);
    part4 = local_ensure_cell_field(part4, 'ModeFamily_s', n_modes, '');
    if ~isfield(part4, 'ranking_table') || ~istable(part4.ranking_table)
        part4.ranking_table = table(false(n_modes, 1), false(n_modes, 1), ...
            'VariableNames', {'selected_for_plots', 'selected_for_publication'});
    end
    if ~ismember('selected_for_plots', part4.ranking_table.Properties.VariableNames)
        part4.ranking_table.selected_for_plots = false(n_modes, 1);
    end
    if ~ismember('selected_for_publication', part4.ranking_table.Properties.VariableNames)
        part4.ranking_table.selected_for_publication = false(n_modes, 1);
    end
    if ~isfield(part4, 'MatrixHealth')
        part4.MatrixHealth = struct('row_norm_ratio_before', NaN, 'row_norm_ratio_after', NaN);
    end
    if ~isfield(part4, 'mode_validity_report')
        part4.mode_validity_report = struct('publication_allowed', false, 'primary_reason', 'legacy_part4_missing_report');
    end
    if ~isfield(part4, 'selection_summary')
        part4.selection_summary = struct('status', 'legacy_part4_missing_summary');
    end
    if ~isfield(part4, 'ModeSelectionAudit')
        part4.ModeSelectionAudit = struct([]);
    end
    if ~isfield(part4, 'ModeCouplingAudit')
        part4.ModeCouplingAudit = struct([]);
    end
    if ~isfield(part4, 'AdjointLeadAudit')
        part4.AdjointLeadAudit = struct('enabled', false, 'reason', 'legacy_part4_missing_adjoint');
    end
    if ~isfield(part4, 'WavemakerLeadMap')
        part4.WavemakerLeadMap = [];
    end
    if ~isfield(part4, 'freq_label')
        part4.freq_label = 'f_nd';
    end
    config_struct = local_get_optional_field(part4, 'Config', struct());
    if ~isfield(part4, 'ModeReferenceTable') || ~istable(part4.ModeReferenceTable)
        part4.ModeReferenceTable = table();
    end
    if ~isfield(part4, 'EigenReferenceTable') || ~istable(part4.EigenReferenceTable)
        part4.EigenReferenceTable = table();
    end
    if ~isfield(part4, 'FigureCriteriaTable') || ~istable(part4.FigureCriteriaTable)
        part4.FigureCriteriaTable = table();
    end
    if ~isfield(part4, 'ComponentModeAudit')
        part4.ComponentModeAudit = struct([]);
    end
    if ~isfield(part4, 'PlotProvenanceAudit')
        part4.PlotProvenanceAudit = struct( ...
            'has_plot_lead', false, ...
            'plot_mode_position', NaN, ...
            'reference_component', '', ...
            'normalization', 'energy_total_l2', ...
            'normalization_scale', NaN, ...
            'phase_anchor_type', 'none', ...
            'phase_anchor_x', NaN, ...
            'phase_anchor_y', NaN, ...
            'target_benchmark', '');
    end
    if ~isfield(part4, 'PlotContractAudit')
        part4.PlotContractAudit = struct( ...
            'primary_plot_contract', local_get_optional_field(config_struct, 'plot_contract', ''), ...
            'secondary_plot_contract', local_get_optional_field(config_struct, 'secondary_plot_contract', ''), ...
            'target_benchmark', local_get_optional_field(config_struct, 'target_benchmark', ''), ...
            'selection_status', local_get_optional_field(part4.selection_summary, 'status', ''), ...
            'plot_status', local_get_optional_field(part4.selection_summary, 'plot_status', ''), ...
            'has_plot_lead', false);
    end
    if ~isfield(part4, 'FigureAudit')
        part4.FigureAudit = struct();
    end
    if ~isfield(part4, 'publication_leading_mode_index')
        part4.publication_leading_mode_index = NaN;
    end
    if ~isfield(part4, 'publication_leading_mode_position')
        part4.publication_leading_mode_position = NaN;
    end
    if ~ismember('mode_index', part4.ranking_table.Properties.VariableNames)
        part4.ranking_table.mode_index = (1:n_modes).';
        part4.ranking_table = movevars(part4.ranking_table, 'mode_index', 'Before', 1);
    end
end

function S = local_ensure_vector_field(S, field_name, n_modes, default_value)
%LOCAL_ENSURE_VECTOR_FIELD Backfill one missing vector field in a loaded MAT struct.

    if ~isfield(S, field_name) || isempty(S.(field_name))
        S.(field_name) = repmat(default_value, n_modes, 1);
    end
end

function S = local_ensure_cell_field(S, field_name, n_modes, default_value)
%LOCAL_ENSURE_CELL_FIELD Backfill one missing cell-vector field in a loaded MAT struct.

    if ~isfield(S, field_name) || isempty(S.(field_name))
        S.(field_name) = repmat({default_value}, n_modes, 1);
    end
end

function value = local_pick_vector_entry(values, index, default_value)
%LOCAL_PICK_VECTOR_ENTRY Read one vector-like entry with fallback.

    value = default_value;
    if isempty(values)
        return;
    end
    if iscell(values)
        if numel(values) >= index
            value = values{index};
        end
    elseif isstring(values)
        if numel(values) >= index
            value = char(values(index));
        end
    elseif isnumeric(values) || islogical(values)
        if numel(values) >= index
            value = values(index);
        end
    end
end

function value = local_pick_coupling_field(audit, index, field_name, default_value)
%LOCAL_PICK_COUPLING_FIELD Read one field from one coupling-audit entry with fallback.

    value = default_value;
    if isstruct(audit) && numel(audit) >= index && isfield(audit, field_name)
        candidate = audit(index).(field_name);
        if isstring(candidate)
            value = char(candidate);
        else
            value = candidate;
        end
    end
end

function Config = local_normalize_runner_config(Config)
%LOCAL_NORMALIZE_RUNNER_CONFIG Ensure runner-facing Config fields exist.

    benchmark = local_default_benchmark_contract();

    if isfield(Config, 'flow') && isstruct(Config.flow)
        if ~isfield(Config, 'Ma_inf') && isfield(Config.flow, 'Ma_inf'), Config.Ma_inf = Config.flow.Ma_inf; end
        if ~isfield(Config, 'Re_inf') && isfield(Config.flow, 'Re_inf'), Config.Re_inf = Config.flow.Re_inf; end
        if ~isfield(Config, 'T_inf') && isfield(Config.flow, 'T_inf'), Config.T_inf = Config.flow.T_inf; end
        if ~isfield(Config, 'gamma') && isfield(Config.flow, 'gamma'), Config.gamma = Config.flow.gamma; end
        if ~isfield(Config, 'Pr') && isfield(Config.flow, 'Pr'), Config.Pr = Config.flow.Pr; end
        if ~isfield(Config, 'Cv_nd') && isfield(Config.flow, 'Cv'), Config.Cv_nd = Config.flow.Cv; end
        if ~isfield(Config, 'S_nd') && isfield(Config.flow, 'Sutherland_nd'), Config.S_nd = Config.flow.Sutherland_nd; end
        if ~isfield(Config, 'wall_model') && isfield(Config.flow, 'wall_model'), Config.wall_model = Config.flow.wall_model; end
        if ~isfield(Config, 'T_wall') && isfield(Config.flow, 'T_wall'), Config.T_wall = Config.flow.T_wall; end
        if ~isfield(Config, 'T_wall_nd') && isfield(Config.flow, 'T_wall_nd'), Config.T_wall_nd = Config.flow.T_wall_nd; end
    end

    if ~isfield(Config, 'Ma_inf'), Config.Ma_inf = 7.0; end
    if ~isfield(Config, 'Re_inf'), Config.Re_inf = 1.0e5; end
    if ~isfield(Config, 'T_inf'), Config.T_inf = 191.0; end
    if ~isfield(Config, 'gamma'), Config.gamma = 1.4; end
    if ~isfield(Config, 'Pr'), Config.Pr = 0.71; end
    if ~isfield(Config, 'Cv_nd')
        Config.Cv_nd = 1.0 / (Config.gamma * (Config.gamma - 1.0) * Config.Ma_inf^2);
    end
    if ~isfield(Config, 'S_nd')
        Config.S_nd = 110.4 / Config.T_inf;
    end

    if ~isfield(Config, 'use_sponge'), Config.use_sponge = false; end
    if ~isfield(Config, 'wall_model') || isempty(Config.wall_model)
        Config.wall_model = 'adiabatic';
    end
    Config.wall_model = normalize_wall_model(Config.wall_model, ...
        'ErrorIdentifier', 'run_user_test_baseflow_fullres_v6:WallModel');
    if ~isfield(Config, 'T_wall') && isfield(Config, 'T_wall_nd')
        Config.T_wall = Config.T_wall_nd * Config.T_inf;
    elseif ~isfield(Config, 'T_wall')
        Config.T_wall = 298.0;
    end
    Config.T_wall_nd = Config.T_wall / Config.T_inf;
    if ~isfield(Config, 'use_semi_artificial_viscosity'), Config.use_semi_artificial_viscosity = true; end
    if ~isfield(Config, 'semi_artificial_viscosity') || ~isstruct(Config.semi_artificial_viscosity)
        Config.semi_artificial_viscosity = struct();
    end
    if ~isfield(Config.semi_artificial_viscosity, 'epsilon'), Config.semi_artificial_viscosity.epsilon = 5.0e-2; end
    if ~isfield(Config.semi_artificial_viscosity, 'shock_percentile'), Config.semi_artificial_viscosity.shock_percentile = 85.0; end
    if ~isfield(Config.semi_artificial_viscosity, 'dilation_steps'), Config.semi_artificial_viscosity.dilation_steps = 5; end
    if ~isfield(Config.semi_artificial_viscosity, 'near_wall_fraction'), Config.semi_artificial_viscosity.near_wall_fraction = 0.10; end
    if ~isfield(Config, 'use_shock_source_regularization'), Config.use_shock_source_regularization = false; end
    if ~isfield(Config, 'shock_source_regularization') || ~isstruct(Config.shock_source_regularization)
        Config.shock_source_regularization = struct();
    end
    if ~isfield(Config.shock_source_regularization, 'clip_percentile'), Config.shock_source_regularization.clip_percentile = 95.0; end
    if ~isfield(Config.shock_source_regularization, 'dmu_clip_percentile'), Config.shock_source_regularization.dmu_clip_percentile = 95.0; end
    if ~isfield(Config.shock_source_regularization, 'zero_second_derivatives_in_shock')
        Config.shock_source_regularization.zero_second_derivatives_in_shock = true;
    end
    if ~isfield(Config.shock_source_regularization, 'suppress_viscosity_gradient_terms_in_shock')
        Config.shock_source_regularization.suppress_viscosity_gradient_terms_in_shock = true;
    end
    if ~isfield(Config, 'pressure_row_regularization') || ~isstruct(Config.pressure_row_regularization)
        Config.pressure_row_regularization = struct();
    end
    if ~isfield(Config.pressure_row_regularization, 'enabled'), Config.pressure_row_regularization.enabled = false; end
    if ~isfield(Config.pressure_row_regularization, 'gradient_clip_percentile')
        Config.pressure_row_regularization.gradient_clip_percentile = 95.0;
    end
    if ~isfield(Config.pressure_row_regularization, 'divergence_clip_percentile')
        Config.pressure_row_regularization.divergence_clip_percentile = 95.0;
    end
    if ~isfield(Config.pressure_row_regularization, 'suppress_pressure_gradients_in_shock')
        Config.pressure_row_regularization.suppress_pressure_gradients_in_shock = false;
    end
    if ~isfield(Config.pressure_row_regularization, 'suppress_divergence_in_shock')
        Config.pressure_row_regularization.suppress_divergence_in_shock = false;
    end
    if ~isfield(Config, 'analysis') || ~isstruct(Config.analysis)
        Config.analysis = struct();
    end
    if ~isfield(Config.analysis, 'compute_adjoint_lead')
        Config.analysis.compute_adjoint_lead = false;
    end
    if ~isfield(Config, 'benchmark_profile') || isempty(Config.benchmark_profile)
        Config.benchmark_profile = benchmark.name;
    end
    if ~isfield(Config, 'target_benchmark') || isempty(Config.target_benchmark)
        Config.target_benchmark = benchmark.target_benchmark;
    end
    if ~isfield(Config, 'plot_contract') || isempty(Config.plot_contract)
        Config.plot_contract = benchmark.primary_plot_contract;
    end
    if ~isfield(Config, 'secondary_plot_contract') || isempty(Config.secondary_plot_contract)
        Config.secondary_plot_contract = benchmark.secondary_plot_contract;
    end
    if ~isfield(Config, 'reference_scales') || ~isstruct(Config.reference_scales)
        Config.reference_scales = benchmark.reference_scales;
    end
    if ~isfield(Config.reference_scales, 'defined')
        Config.reference_scales.defined = false;
    end
    if ~isfield(Config, 'structural_only')
        Config.structural_only = benchmark.current_stage.structural_only;
    end
end

function [value_out, changed] = local_optional_override(value_in, override_value)
%LOCAL_OPTIONAL_OVERRIDE Apply one optional override when it is supplied.

    if isempty(override_value)
        value_out = value_in;
        changed = false;
    else
        value_out = override_value;
        changed = true;
    end
end

function value = local_get_optional_field(S, name, default_value)
%LOCAL_GET_OPTIONAL_FIELD Return a struct field when it exists.

    if isstruct(S) && isfield(S, name)
        value = S.(name);
    else
        value = default_value;
    end
end

function S = local_ensure_struct_field(S, field_name, default_value)
%LOCAL_ENSURE_STRUCT_FIELD Fill one missing struct field with a default value.

    if ~isfield(S, field_name)
        S.(field_name) = default_value;
    end
end

function benchmark = local_default_benchmark_contract()
%LOCAL_DEFAULT_BENCHMARK_CONTRACT Return the runner-default benchmark contract.

    benchmark = struct( ...
        'name', 'sidharth2018_code_correction_v1', ...
        'target_benchmark', 'Sidharth2018', ...
        'reference_scales', struct('defined', false), ...
        'current_stage', struct('structural_only', true), ...
        'primary_plot_contract', 'paperA_reference_mainset_v1', ...
        'secondary_plot_contract', 'sidharth2018_reproduction_v1');
    try
        benchmark = get_double_wedge_benchmark_profile('sidharth2018_code_correction_v1');
    catch
        % Keep the hard-coded fallback when the helper is unavailable.
    end
end

function tf = local_reference_scales_defined(reference_scales)
%LOCAL_REFERENCE_SCALES_DEFINED True when one reference-scale contract is marked usable.

    tf = isstruct(reference_scales) && isfield(reference_scales, 'defined') && ...
        logical(reference_scales.defined);
end

function local_write_named_fields(fid, title_text, S, field_names)
%LOCAL_WRITE_NAMED_FIELDS Print one compact named-field block from a struct.

    fprintf(fid, '\n%s:\n', localize_output_label(title_text));
    if ~isstruct(S) || isempty(fieldnames(S))
        fprintf(fid, '  <empty>\n');
        return;
    end
    if ~isstruct(S) || isempty(fieldnames(S))
        fprintf(fid, '  <空>\n');
        return;
    end
    for k = 1:numel(field_names)
        name = field_names{k};
        if isfield(S, name)
            fprintf(fid, '  %s: %s\n', localize_output_label(name), local_format_summary_value(S.(name)));
        end
    end
end

function local_write_table_block(fid, title_text, table_value)
%LOCAL_WRITE_TABLE_BLOCK Print one table-valued section into the text summary.

    fprintf(fid, '\n%s:\n', localize_output_label(title_text));
    if ~istable(table_value) || isempty(table_value) || height(table_value) == 0
        fprintf(fid, '  <empty>\n');
        return;
    end
    if ~istable(table_value) || isempty(table_value) || height(table_value) == 0
        fprintf(fid, '  <空>\n');
        return;
    end
    display_table = localize_output_table_for_text(table_value);
    table_text = strtrim(evalc('disp(display_table)'));
    fprintf(fid, '%s\n', table_text);
end

function local_write_component_audit_block(fid, audit_entries, lead_position)
%LOCAL_WRITE_COMPONENT_AUDIT_BLOCK Print one compact lead-mode component summary.

    fprintf(fid, '\n%s:\n', localize_output_label('Lead component audit'));
    if ~isstruct(audit_entries) || isempty(audit_entries) || ~isfinite(lead_position) || ...
            lead_position < 1 || lead_position > numel(audit_entries) || ...
            ~isfield(audit_entries(lead_position), 'components')
        fprintf(fid, '  <unavailable>\n');
        return;
    end
    if ~isstruct(audit_entries) || isempty(audit_entries) || ~isfinite(lead_position) || ...
            lead_position < 1 || lead_position > numel(audit_entries) || ...
            ~isfield(audit_entries(lead_position), 'components')
        fprintf(fid, '  <不可用>\n');
        return;
    end

    components = audit_entries(lead_position).components;
    names = {'w'; 'u'; 'v'; 'T'; 'p'};
    bubble_support = nan(numel(names), 1);
    bubble_core = nan(numel(names), 1);
    shock_core = nan(numel(names), 1);
    outlet_wall = nan(numel(names), 1);
    free_stream = nan(numel(names), 1);
    peak_in_bubble = false(numel(names), 1);
    peak_in_shock = false(numel(names), 1);
    for k = 1:numel(names)
        name = names{k};
        if isfield(components, name)
            component = components.(name);
            bubble_support(k) = local_get_optional_field(component, 'bubble_support_overlap', NaN);
            bubble_core(k) = local_get_optional_field(component, 'bubble_core_overlap', NaN);
            shock_core(k) = local_get_optional_field(component, 'shock_core_overlap', NaN);
            outlet_wall(k) = local_get_optional_field(component, 'outlet_wall_overlap', NaN);
            free_stream(k) = local_get_optional_field(component, 'free_stream_overlap', NaN);
            peak_in_bubble(k) = logical(local_get_optional_field(component, 'peak_in_bubble_support', false));
            peak_in_shock(k) = logical(local_get_optional_field(component, 'peak_in_shock_core', false));
        end
    end

    tbl = table(string(names), bubble_support, bubble_core, shock_core, outlet_wall, ...
        free_stream, peak_in_bubble, peak_in_shock, ...
        'VariableNames', {'component', 'bubble_support', 'bubble_core', 'shock_core', ...
        'outlet_wall', 'free_stream', 'peak_in_bubble', 'peak_in_shock'});
    display_table = localize_output_table_for_text(tbl);
    table_text = strtrim(evalc('disp(display_table)'));
    fprintf(fid, '%s\n', table_text);
end

function text = local_format_summary_value(value)
%LOCAL_FORMAT_SUMMARY_VALUE Convert summary values into readable one-line text.

    if ischar(value)
        text = local_translate_summary_token(value);
    elseif isstring(value)
        if isscalar(value)
            text = local_translate_summary_token(char(value));
        else
            text = char(join(value, ', '));
        end
    elseif isnumeric(value)
        if isempty(value)
            text = '[]';
        elseif isscalar(value)
            if isnan(value)
                text = 'NaN';
            else
                text = sprintf('%.6g', value);
            end
        else
            text = mat2str(value);
        end
    elseif islogical(value)
        if isscalar(value)
            text = sprintf('%d', value);
        else
            text = mat2str(value);
        end
    elseif iscell(value)
        if isempty(value)
            text = '{}';
        else
            pieces = cellfun(@local_format_summary_value, value, 'UniformOutput', false);
            text = ['{' strjoin(pieces, ', ') '}'];
        end
    elseif isstruct(value)
        names = fieldnames(value);
        if isempty(names)
            text = 'struct()';
        else
            text = sprintf('struct(%d fields)', numel(names));
        end
    else
        text = '<unprintable>';
    end
end

function text_out = local_translate_summary_token(text_in)
%LOCAL_TRANSLATE_SUMMARY_TOKEN Localize one compact status string when helpful.

    text_out = char(string(text_in));
    switch lower(strtrim(text_out))
        case 'resolved'
            text_out = '已解析';
        case 'plot_leading_mode_position'
            text_out = '绘图主模态位置';
        case 'bubble_centred'
            text_out = '分离泡主导';
        case 'boundary_supported'
            text_out = '边界支撑';
        case 'compact_interior_candidate'
            text_out = '紧凑内域候选';
        case 'physical_plot_candidates_available'
            text_out = '存在物理绘图候选';
        case {'no_physical_plot_candidate', 'no_physical_plot_candidates'}
            text_out = '无物理绘图候选';
        case 'papera_physical_mode'
            text_out = 'PaperA物理模态';
        case 'disabled_by_config'
            text_out = '配置关闭';
        case 'structural_benchmark_not_physical_reproduction'
            text_out = '结构基准，非物理复现';
    end
end

function tf = local_is_part3_variant(value)
%LOCAL_IS_PART3_VARIANT Validate supported Part3 implementation labels.

    try
        local_canonical_part3_variant(value);
        tf = true;
    catch
        tf = false;
    end
end

function variant = local_canonical_part3_variant(value)
%LOCAL_CANONICAL_PART3_VARIANT Map accepted aliases to one canonical Part3 label.

    key = lower(strrep(char(string(value)), '-', '_'));
    switch key
        case {'current_v6', 'v6', 'main_v6'}
            variant = 'current_v6';
        case {'pre_pressure_fix_20260414', 'pre_pressure_fix', 'old_pressure_fix'}
            variant = 'pre_pressure_fix_20260414';
        otherwise
            error('run_user_test_baseflow_fullres_v6:Part3Variant', ...
                'Unsupported Part3Variant: %s', char(string(value)));
    end
end

function variant_used = local_run_part3_variant(value)
%LOCAL_RUN_PART3_VARIANT Run the selected Part3 implementation.

    variant_used = local_canonical_part3_variant(value);
    switch variant_used
        case 'current_v6'
            Main_DoubleWedge_Part3_v6();
        case 'pre_pressure_fix_20260414'
            Main_DoubleWedge_Part3_v6_pre_pressure_fix_20260414();
        otherwise
            error('run_user_test_baseflow_fullres_v6:InternalPart3Variant', ...
                'Unexpected canonical Part3 variant: %s', variant_used);
    end
end
