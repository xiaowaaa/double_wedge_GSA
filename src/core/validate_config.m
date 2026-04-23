function [config_out, report] = validate_config(config_in, varargin)
%VALIDATE_CONFIG Normalize the Paper-A Config struct and enforce key rules.

    p = inputParser;
    p.FunctionName = 'validate_config';
    addParameter(p, 'Verbose', true, @(x) islogical(x) && isscalar(x));
    addParameter(p, 'RequireReferenceScales', false, @(x) islogical(x) && isscalar(x));
    parse(p, varargin{:});

    required_fields = {'Ma_inf', 'Re_inf', 'T_inf', 'gamma', 'Pr', ...
        'x_hinge', 'n_eigs', 'datafile'};
    for k = 1:numel(required_fields)
        if ~isfield(config_in, required_fields{k})
            error('validate_config:MissingField', ...
                'Missing required Config field "%s".', required_fields{k});
        end
    end

    config_out = config_in;
    added_defaults = {};

    [config_out, added_defaults] = local_add_default(config_out, added_defaults, ...
        'Cv_nd', 1.0 / (config_out.gamma * (config_out.gamma - 1.0) * config_out.Ma_inf^2));
    [config_out, added_defaults] = local_add_default(config_out, added_defaults, ...
        'S_nd', 110.4 / config_out.T_inf);
    [config_out, added_defaults] = local_add_default(config_out, added_defaults, ...
        'T_wall_nd', 298.0 / config_out.T_inf);
    [config_out, added_defaults] = local_add_default(config_out, added_defaults, ...
        'boundary_map', struct( ...
            'south', 'mixed_symmetry_wall', ...
            'north', 'inlet', ...
            'west', 'inlet', ...
            'east', 'outlet'));
    [config_out, added_defaults] = local_add_default(config_out, added_defaults, ...
        'use_physical_filter', false);
    [config_out, added_defaults] = local_add_default(config_out, added_defaults, ...
        'plot_all_mode_u_bubble', false);
    [config_out, added_defaults] = local_add_default(config_out, added_defaults, ...
        'beta', 0.0);
    [config_out, added_defaults] = local_add_default(config_out, added_defaults, ...
        'state_layout', 'primitive5_u_v_w_T_p');
    [config_out, added_defaults] = local_add_default(config_out, added_defaults, ...
        'operator_model', 'paperA_primitive5_direct_v6');
    [config_out, added_defaults] = local_add_default(config_out, added_defaults, ...
        'allow_placeholder_operator', false);
    [config_out, added_defaults] = local_add_default(config_out, added_defaults, ...
        'use_sponge', false);
    [config_out, added_defaults] = local_add_default(config_out, added_defaults, ...
        'sponge', struct( ...
            'sigma_max', 15.0, ...
            'power', 2.0, ...
            'outlet_fraction', 0.18, ...
            'top_fraction', 0.18, ...
            'inlet_fraction', 0.05, ...
            'bottom_fraction', 0.05, ...
            'apply_outlet', true, ...
            'apply_top', true, ...
            'apply_inlet', false, ...
            'apply_bottom', false));
    [config_out, added_defaults] = local_add_default(config_out, added_defaults, ...
        'use_semi_artificial_viscosity', true);
    [config_out, added_defaults] = local_add_default(config_out, added_defaults, ...
        'use_shock_source_regularization', false);
    [config_out, added_defaults] = local_add_default(config_out, added_defaults, ...
        'semi_artificial_viscosity', struct( ...
            'epsilon', 5.0e-2, ...
            'shock_percentile', 85.0, ...
            'dilation_steps', 5, ...
            'near_wall_fraction', 0.10));
    [config_out, added_defaults] = local_add_default(config_out, added_defaults, ...
        'shock_source_regularization', struct( ...
            'clip_percentile', 95.0, ...
            'dmu_clip_percentile', 95.0, ...
            'zero_second_derivatives_in_shock', true, ...
            'suppress_viscosity_gradient_terms_in_shock', true));
    [config_out, added_defaults] = local_add_default(config_out, added_defaults, ...
        'pressure_row_regularization', struct( ...
            'enabled', false, ...
            'gradient_clip_percentile', 95.0, ...
            'divergence_clip_percentile', 95.0, ...
            'suppress_pressure_gradients_in_shock', false, ...
            'suppress_divergence_in_shock', false));
    [config_out, added_defaults] = local_add_default(config_out, added_defaults, ...
        'sigma', 0.05 + 0.02i);
    [config_out, added_defaults] = local_add_default(config_out, added_defaults, ...
        'sigma_triplet', [0.00 + 0.005i, 0.00 + 0.010i, 0.00 + 0.020i, 0.02 + 0.020i, 0.05 + 0.020i]);
    [config_out, added_defaults] = local_add_default(config_out, added_defaults, ...
        'krylov_dimension_floor', 120);
    [config_out, added_defaults] = local_add_default(config_out, added_defaults, ...
        'krylov_dimension_cap', 180);
    [config_out, added_defaults] = local_add_default(config_out, added_defaults, ...
        'descriptor_solver', struct( ...
            'large_system_threshold', 4.0e5, ...
            'huge_system_threshold', 1.0e6, ...
            'max_total_modes_large', 18, ...
            'max_total_modes_huge', 8, ...
            'max_shifts_large', 3, ...
            'max_shifts_huge', 1, ...
            'max_modes_per_shift_large', 6, ...
            'max_modes_per_shift_huge', 3, ...
            'min_modes_per_shift', 2, ...
            'krylov_floor_large', 24, ...
            'krylov_cap_large', 48, ...
            'krylov_floor_huge', 10, ...
            'krylov_cap_huge', 20));
    [config_out, added_defaults] = local_add_default(config_out, added_defaults, ...
        'plot_contract', 'paperA_reference_mainset_v1');
    [config_out, added_defaults] = local_add_default(config_out, added_defaults, ...
        'analysis', struct( ...
            'compute_adjoint_lead', false));
    [config_out, added_defaults] = local_add_default(config_out, added_defaults, ...
        'debug', struct());

    if ~isfield(config_out.semi_artificial_viscosity, 'epsilon')
        config_out.semi_artificial_viscosity.epsilon = 5.0e-2;
        added_defaults{end + 1} = 'semi_artificial_viscosity.epsilon'; %#ok<AGROW>
    end
    if ~isfield(config_out.semi_artificial_viscosity, 'shock_percentile')
        config_out.semi_artificial_viscosity.shock_percentile = 85.0;
        added_defaults{end + 1} = 'semi_artificial_viscosity.shock_percentile'; %#ok<AGROW>
    end
    if ~isfield(config_out.semi_artificial_viscosity, 'dilation_steps')
        config_out.semi_artificial_viscosity.dilation_steps = 5;
        added_defaults{end + 1} = 'semi_artificial_viscosity.dilation_steps'; %#ok<AGROW>
    end
    if ~isfield(config_out.semi_artificial_viscosity, 'near_wall_fraction')
        config_out.semi_artificial_viscosity.near_wall_fraction = 0.10;
        added_defaults{end + 1} = 'semi_artificial_viscosity.near_wall_fraction'; %#ok<AGROW>
    end
    if ~isfield(config_out, 'shock_source_regularization') || ~isstruct(config_out.shock_source_regularization)
        config_out.shock_source_regularization = struct();
        added_defaults{end + 1} = 'shock_source_regularization'; %#ok<AGROW>
    end
    if ~isfield(config_out.shock_source_regularization, 'clip_percentile')
        config_out.shock_source_regularization.clip_percentile = 95.0;
        added_defaults{end + 1} = 'shock_source_regularization.clip_percentile'; %#ok<AGROW>
    end
    if ~isfield(config_out.shock_source_regularization, 'dmu_clip_percentile')
        config_out.shock_source_regularization.dmu_clip_percentile = 95.0;
        added_defaults{end + 1} = 'shock_source_regularization.dmu_clip_percentile'; %#ok<AGROW>
    end
    if ~isfield(config_out.shock_source_regularization, 'zero_second_derivatives_in_shock')
        config_out.shock_source_regularization.zero_second_derivatives_in_shock = true;
        added_defaults{end + 1} = 'shock_source_regularization.zero_second_derivatives_in_shock'; %#ok<AGROW>
    end
    if ~isfield(config_out.shock_source_regularization, 'suppress_viscosity_gradient_terms_in_shock')
        config_out.shock_source_regularization.suppress_viscosity_gradient_terms_in_shock = true;
        added_defaults{end + 1} = 'shock_source_regularization.suppress_viscosity_gradient_terms_in_shock'; %#ok<AGROW>
    end
    if ~isfield(config_out, 'pressure_row_regularization') || ~isstruct(config_out.pressure_row_regularization)
        config_out.pressure_row_regularization = struct();
        added_defaults{end + 1} = 'pressure_row_regularization'; %#ok<AGROW>
    end
    if ~isfield(config_out.pressure_row_regularization, 'enabled')
        config_out.pressure_row_regularization.enabled = false;
        added_defaults{end + 1} = 'pressure_row_regularization.enabled'; %#ok<AGROW>
    end
    if ~isfield(config_out.pressure_row_regularization, 'gradient_clip_percentile')
        config_out.pressure_row_regularization.gradient_clip_percentile = 95.0;
        added_defaults{end + 1} = 'pressure_row_regularization.gradient_clip_percentile'; %#ok<AGROW>
    end
    if ~isfield(config_out.pressure_row_regularization, 'divergence_clip_percentile')
        config_out.pressure_row_regularization.divergence_clip_percentile = 95.0;
        added_defaults{end + 1} = 'pressure_row_regularization.divergence_clip_percentile'; %#ok<AGROW>
    end
    if ~isfield(config_out.pressure_row_regularization, 'suppress_pressure_gradients_in_shock')
        config_out.pressure_row_regularization.suppress_pressure_gradients_in_shock = false;
        added_defaults{end + 1} = 'pressure_row_regularization.suppress_pressure_gradients_in_shock'; %#ok<AGROW>
    end
    if ~isfield(config_out.pressure_row_regularization, 'suppress_divergence_in_shock')
        config_out.pressure_row_regularization.suppress_divergence_in_shock = false;
        added_defaults{end + 1} = 'pressure_row_regularization.suppress_divergence_in_shock'; %#ok<AGROW>
    end
    if ~isfield(config_out, 'mode_filter') || ~isstruct(config_out.mode_filter)
        config_out.mode_filter = struct();
        added_defaults{end + 1} = 'mode_filter'; %#ok<AGROW>
    end
    if ~isfield(config_out.mode_filter, 'near_wall_fraction')
        config_out.mode_filter.near_wall_fraction = 0.15;
        added_defaults{end + 1} = 'mode_filter.near_wall_fraction'; %#ok<AGROW>
    end
    if ~isfield(config_out.mode_filter, 'bubble_fraction_threshold')
        config_out.mode_filter.bubble_fraction_threshold = 0.05;
        added_defaults{end + 1} = 'mode_filter.bubble_fraction_threshold'; %#ok<AGROW>
    end
    if ~isfield(config_out.mode_filter, 'bubble_core_fraction_threshold')
        config_out.mode_filter.bubble_core_fraction_threshold = 0.03;
        added_defaults{end + 1} = 'mode_filter.bubble_core_fraction_threshold'; %#ok<AGROW>
    end
    if ~isfield(config_out.mode_filter, 'bubble_support_fraction_threshold')
        config_out.mode_filter.bubble_support_fraction_threshold = 0.05;
        added_defaults{end + 1} = 'mode_filter.bubble_support_fraction_threshold'; %#ok<AGROW>
    end
    if ~isfield(config_out.mode_filter, 'shock_fraction_threshold')
        config_out.mode_filter.shock_fraction_threshold = 0.35;
        added_defaults{end + 1} = 'mode_filter.shock_fraction_threshold'; %#ok<AGROW>
    end
    if ~isfield(config_out.mode_filter, 'shock_core_fraction_threshold')
        config_out.mode_filter.shock_core_fraction_threshold = 0.15;
        added_defaults{end + 1} = 'mode_filter.shock_core_fraction_threshold'; %#ok<AGROW>
    end
    if ~isfield(config_out.mode_filter, 'free_stream_fraction_threshold')
        config_out.mode_filter.free_stream_fraction_threshold = 0.20;
        added_defaults{end + 1} = 'mode_filter.free_stream_fraction_threshold'; %#ok<AGROW>
    end
    if ~isfield(config_out.mode_filter, 'residual_threshold')
        config_out.mode_filter.residual_threshold = 1.0e-4;
        added_defaults{end + 1} = 'mode_filter.residual_threshold'; %#ok<AGROW>
    end
    if ~isfield(config_out.mode_filter, 'checker_threshold')
        config_out.mode_filter.checker_threshold = 5.0;
        added_defaults{end + 1} = 'mode_filter.checker_threshold'; %#ok<AGROW>
    end
    if ~isfield(config_out.mode_filter, 'checker_threshold_structural')
        config_out.mode_filter.checker_threshold_structural = 20.0;
        added_defaults{end + 1} = 'mode_filter.checker_threshold_structural'; %#ok<AGROW>
    end
    if ~isfield(config_out.mode_filter, 'pressure_checker_threshold')
        config_out.mode_filter.pressure_checker_threshold = 1.5;
        added_defaults{end + 1} = 'mode_filter.pressure_checker_threshold'; %#ok<AGROW>
    end
    if ~isfield(config_out.mode_filter, 'pressure_checker_threshold_structural')
        config_out.mode_filter.pressure_checker_threshold_structural = 1.5;
        added_defaults{end + 1} = 'mode_filter.pressure_checker_threshold_structural'; %#ok<AGROW>
    end
    if ~isfield(config_out.mode_filter, 'outlet_fraction')
        config_out.mode_filter.outlet_fraction = 0.12;
        added_defaults{end + 1} = 'mode_filter.outlet_fraction'; %#ok<AGROW>
    end
    if ~isfield(config_out.mode_filter, 'outlet_fraction_threshold')
        config_out.mode_filter.outlet_fraction_threshold = 0.35;
        added_defaults{end + 1} = 'mode_filter.outlet_fraction_threshold'; %#ok<AGROW>
    end
    if ~isfield(config_out.mode_filter, 'outlet_wall_fraction_threshold')
        config_out.mode_filter.outlet_wall_fraction_threshold = 0.20;
        added_defaults{end + 1} = 'mode_filter.outlet_wall_fraction_threshold'; %#ok<AGROW>
    end
    if ~isfield(config_out.mode_filter, 'pressure_free_stream_fraction_threshold')
        config_out.mode_filter.pressure_free_stream_fraction_threshold = 0.35;
        added_defaults{end + 1} = 'mode_filter.pressure_free_stream_fraction_threshold'; %#ok<AGROW>
    end
    if ~isfield(config_out.mode_filter, 'pressure_outlet_fraction_threshold')
        config_out.mode_filter.pressure_outlet_fraction_threshold = 0.40;
        added_defaults{end + 1} = 'mode_filter.pressure_outlet_fraction_threshold'; %#ok<AGROW>
    end
    if ~isfield(config_out.mode_filter, 'pressure_outlet_wall_fraction_threshold')
        config_out.mode_filter.pressure_outlet_wall_fraction_threshold = 0.20;
        added_defaults{end + 1} = 'mode_filter.pressure_outlet_wall_fraction_threshold'; %#ok<AGROW>
    end
    if ~isfield(config_out.mode_filter, 'pressure_shock_core_fraction_threshold')
        config_out.mode_filter.pressure_shock_core_fraction_threshold = 0.20;
        added_defaults{end + 1} = 'mode_filter.pressure_shock_core_fraction_threshold'; %#ok<AGROW>
    end
    if ~isfield(config_out.mode_filter, 'coupled_mode_shock_min_threshold')
        config_out.mode_filter.coupled_mode_shock_min_threshold = 0.08;
        added_defaults{end + 1} = 'mode_filter.coupled_mode_shock_min_threshold'; %#ok<AGROW>
    end
    if ~isfield(config_out.mode_filter, 'coupled_mode_shock_max_threshold')
        config_out.mode_filter.coupled_mode_shock_max_threshold = 0.65;
        added_defaults{end + 1} = 'mode_filter.coupled_mode_shock_max_threshold'; %#ok<AGROW>
    end
    if ~isfield(config_out.mode_filter, 'coupled_mode_phase_sync_threshold')
        config_out.mode_filter.coupled_mode_phase_sync_threshold = -0.10;
        added_defaults{end + 1} = 'mode_filter.coupled_mode_phase_sync_threshold'; %#ok<AGROW>
    end
    if ~isfield(config_out, 'analysis') || ~isstruct(config_out.analysis)
        config_out.analysis = struct();
        added_defaults{end + 1} = 'analysis'; %#ok<AGROW>
    end
    if ~isfield(config_out.analysis, 'compute_adjoint_lead')
        config_out.analysis.compute_adjoint_lead = false;
        added_defaults{end + 1} = 'analysis.compute_adjoint_lead'; %#ok<AGROW>
    end

    if config_out.use_physical_filter || p.Results.RequireReferenceScales
        if ~isfield(config_out, 'U_ref') || ~isfield(config_out, 'L_ref')
            error('validate_config:ReferenceScale', ...
                'U_ref and L_ref are required when physical filtering is enabled.');
        end
    end

    report = struct();
    report.added_defaults = added_defaults(:).';
    report.state_layout = config_out.state_layout;
    report.operator_model = config_out.operator_model;
    report.allow_placeholder_operator = config_out.allow_placeholder_operator;

    if p.Results.Verbose
        fprintf('[validate_config] state_layout=%s operator_model=%s beta=%g use_sponge=%d use_sav=%d use_shock_reg=%d allow_placeholder=%d\n', ...
            config_out.state_layout, config_out.operator_model, config_out.beta, ...
            config_out.use_sponge, ...
            config_out.use_semi_artificial_viscosity, ...
            config_out.use_shock_source_regularization, ...
            config_out.allow_placeholder_operator);
    end
end

function [config_out, added_defaults] = local_add_default(config_in, added_defaults, name, value)
%LOCAL_ADD_DEFAULT Set a missing field and record it in the report.

    config_out = config_in;
    if ~isfield(config_out, name)
        config_out.(name) = value;
        added_defaults{end + 1} = name; %#ok<AGROW>
    end
end
