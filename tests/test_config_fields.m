function test_config_fields()
%TEST_CONFIG_FIELDS Validate required Paper-A Config defaults and guardrails.

    project_root = fileparts(fileparts(mfilename('fullpath')));
    addpath(project_root);
    addpath(fullfile(project_root, 'src', 'core'));

    config = local_base_config();

    [config_out, report] = validate_config(config, 'Verbose', false);
    assert(isfield(config_out, 'boundary_map'), 'boundary_map should exist after validation.');
    assert(isfield(config_out, 'use_physical_filter'), 'use_physical_filter should exist after validation.');
    assert(isfield(config_out, 'plot_all_mode_u_bubble'), ...
        'plot_all_mode_u_bubble should exist after validation.');
    assert(isfield(config_out, 'beta'), 'beta should exist after validation.');
    assert(isfield(config_out, 'state_layout'), 'state_layout should exist after validation.');
    assert(isfield(config_out, 'operator_model'), 'operator_model should exist after validation.');
    assert(isfield(config_out, 'allow_placeholder_operator'), ...
        'allow_placeholder_operator should exist after validation.');
    assert(isfield(config_out, 'use_sponge'), 'use_sponge should exist after validation.');
    assert(isfield(config_out, 'sponge'), 'sponge should exist after validation.');
    assert(isfield(config_out, 'use_semi_artificial_viscosity'), ...
        'use_semi_artificial_viscosity should exist after validation.');
    assert(isfield(config_out, 'use_shock_source_regularization'), ...
        'use_shock_source_regularization should exist after validation.');
    assert(isfield(config_out, 'semi_artificial_viscosity'), ...
        'semi_artificial_viscosity should exist after validation.');
    assert(isfield(config_out, 'pressure_row_regularization'), ...
        'pressure_row_regularization should exist after validation.');
    assert(isequal(config_out.use_physical_filter, false), ...
        'Default use_physical_filter should be false.');
    assert(isequal(config_out.plot_all_mode_u_bubble, false), ...
        'Default plot_all_mode_u_bubble should be false.');
    assert(isequal(config_out.beta, 0.0), 'Default beta should be zero.');
    assert(strcmp(config_out.boundary_map.north, 'inlet'), ...
        'Default top boundary should follow the inlet contract.');
    assert(strcmp(config_out.state_layout, 'primitive5_u_v_w_T_p'), ...
        'Default state_layout should follow the Paper-A primitive-five path.');
    assert(strcmp(config_out.operator_model, 'paperA_primitive5_direct_v6'), ...
        'Default operator_model should identify the Paper-A v6 assembly.');
    assert(isequal(config_out.allow_placeholder_operator, false), ...
        'Placeholder operator must be disabled by default.');
    assert(isequal(config_out.use_sponge, false), ...
        'Default use_sponge should now be false for the Paper-A path.');
    assert(isequal(config_out.use_shock_source_regularization, false), ...
        'Default use_shock_source_regularization should be false.');
    assert(isfield(config_out.semi_artificial_viscosity, 'epsilon'), ...
        'semi_artificial_viscosity.epsilon should exist after validation.');
    assert(isequal(config_out.semi_artificial_viscosity.epsilon, 5.0e-2), ...
        'Default semi-artificial-viscosity epsilon should be 5e-2.');
    assert(isequal(config_out.pressure_row_regularization.enabled, false), ...
        'pressure_row_regularization.enabled should default to false.');
    assert(isequal(config_out.pressure_row_regularization.gradient_clip_percentile, 95.0), ...
        'pressure_row_regularization.gradient_clip_percentile should default to 95.');
    assert(isequal(config_out.pressure_row_regularization.suppress_pressure_gradients_in_shock, false), ...
        'Pressure-gradient suppression should default to false.');
assert(isfield(config_out, 'sigma_triplet') && numel(config_out.sigma_triplet) == 5, ...
    'sigma_triplet should be present after validation.');
    assert(strcmp(config_out.plot_contract, 'paperA_reference_mainset_v1'), ...
        'plot_contract should default to the reference Paper-A figure set.');
    assert(isfield(config_out.mode_filter, 'outlet_fraction'), ...
        'mode_filter.outlet_fraction should exist after validation.');
    assert(isfield(config_out.mode_filter, 'outlet_wall_fraction_threshold'), ...
        'mode_filter.outlet_wall_fraction_threshold should exist after validation.');
    assert(isfield(config_out.mode_filter, 'support_weighting') && ...
            strcmp(config_out.mode_filter.support_weighting, 'component_energy'), ...
        'mode_filter.support_weighting should default to component_energy.');
    assert(isfield(config_out.mode_filter, 'free_stream_eta_threshold'), ...
        'mode_filter.free_stream_eta_threshold should exist after validation.');
    assert(isfield(config_out.mode_filter, 'near_wall_support_threshold'), ...
        'mode_filter.near_wall_support_threshold should exist after validation.');
    assert(isfield(config_out.mode_filter, 'plot_gallery_limit'), ...
        'mode_filter.plot_gallery_limit should exist after validation.');
    assert(isfield(config_out.mode_filter, 'pressure_checker_threshold'), ...
        'mode_filter.pressure_checker_threshold should exist after validation.');
    assert(isfield(config_out.mode_filter, 'pressure_free_stream_fraction_threshold'), ...
        'mode_filter.pressure_free_stream_fraction_threshold should exist after validation.');
    assert(isfield(config_out, 'descriptor_solver') && isstruct(config_out.descriptor_solver), ...
        'descriptor_solver should exist after validation.');
    assert(config_out.descriptor_solver.huge_system_threshold == 1.0e6, ...
        'descriptor_solver.huge_system_threshold should default to 1e6.');
    assert(config_out.descriptor_solver.max_shifts_huge == 1, ...
        'descriptor_solver.max_shifts_huge should default to 1.');
    assert(any(strcmp(report.added_defaults, 'Cv_nd')) || isfield(config, 'Cv_nd'), ...
        'Cv_nd should be present after validation.');

    config_bad = rmfield(config, 'x_hinge');
    did_error = false;
    try
        validate_config(config_bad, 'Verbose', false);
    catch ME
        did_error = strcmp(ME.identifier, 'validate_config:MissingField');
    end
    assert(did_error, 'Missing required fields must raise validate_config:MissingField.');

    config_filter = config;
    config_filter.use_physical_filter = true;
    did_error = false;
    try
        validate_config(config_filter, 'Verbose', false);
    catch ME
        did_error = strcmp(ME.identifier, 'validate_config:ReferenceScale');
    end
    assert(did_error, ...
        'Physical filtering without U_ref/L_ref must raise validate_config:ReferenceScale.');

    config_filter.U_ref = 1.0;
    config_filter.L_ref = 1.0;
    validate_config(config_filter, 'Verbose', false, 'RequireReferenceScales', true);

    fprintf('[test_config_fields] PASS\n');
end

function config = local_base_config()
%LOCAL_BASE_CONFIG Return a minimal valid Config for unit tests.

    config = struct();
    config.Ma_inf = 7.0;
    config.Re_inf = 1.0e5;
    config.T_inf = 191.0;
    config.gamma = 1.4;
    config.Pr = 0.71;
    config.x_hinge = 0.0;
    config.n_eigs = 10;
    config.datafile = 'double_wedge_baseflow.dat';
end
