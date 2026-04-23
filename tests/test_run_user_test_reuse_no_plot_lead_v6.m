function test_run_user_test_reuse_no_plot_lead_v6()
%TEST_RUN_USER_TEST_REUSE_NO_PLOT_LEAD_V6 Reuse a saved Part4 case with no physical plot lead.

    paths = setup_double_wedge_paths('IncludeTests', true);
    project_root = paths.project_root;

    case_name = 'test_run_user_test_reuse_no_plot_lead_v6';
    case_dir = fullfile(project_root, 'outputs', 'mat', case_name);
    if exist(case_dir, 'dir') == 7
        rmdir(case_dir, 's');
    end
    mkdir(case_dir);

    old_dir = pwd;
    cleanup_obj = onCleanup(@() cd(old_dir)); %#ok<NASGU>
    cd(case_dir);

    Config = local_make_reuse_config(project_root);
    BaseValidation = struct('eos_relative_error', 0.0, 'wall_temperature_relative_mismatch', 0.0);
    Nx = 9; %#ok<NASGU>
    Ny = 7; %#ok<NASGU>
    save('Part1_Results.mat', 'Config', 'BaseValidation', 'Nx', 'Ny', '-v7.3');

    Part2Diagnostics = struct('continuity_residual_max', 0.0); %#ok<NASGU>
    BaseflowPhysicsAudit = struct( ... %#ok<NASGU>
        'eos_relative_error', 0.0, ...
        'wall_temperature_relative_mismatch', 0.0, ...
        'continuity_residual_max', 0.0, ...
        'bubble_exists', true);
    GeometryAudit = struct('boundary_contract', struct('top', 'inlet')); %#ok<NASGU>
    save('Part2_Results.mat', 'Part2Diagnostics', 'BaseflowPhysicsAudit', 'GeometryAudit', '-v7.3');

    part4 = local_make_no_plot_part4(Config);
    save('Part4_Results.mat', '-struct', 'part4', '-v7.3');

    matrix_report = struct('zero_rows', [], 'zero_cols', []); %#ok<NASGU>
    save('Diagnose_MatrixHealth_Report.mat', 'matrix_report', '-v7.3');

    RunnerCaseMetadata = struct(); %#ok<NASGU>
    RunnerCaseMetadata.schema_version = 1;
    RunnerCaseMetadata.created_at = datestr(now, 'yyyy-mm-ddTHH:MM:SS');
    RunnerCaseMetadata.case_identity = local_make_case_identity(project_root);
    save('RunnerCaseMetadata.mat', 'RunnerCaseMetadata', '-v7.3');

    summary = run_user_test_baseflow_fullres_v6( ...
        'ReuseExistingCase', true, ...
        'RunPart4', true, ...
        'CaseName', case_name);

    assert(strcmp(summary.stage_completed, 'Part4'), ...
        'Reuse path should still report a Part4-stage summary.');
    assert(~summary.leading_mode_available, ...
        'No-plot cases should not fabricate a plotted leading mode.');
    assert(istable(summary.baseflow_reference_table), ...
        'Legacy Part2 reuse should be backfilled with a baseflow reference table.');
    assert(istable(summary.figure_criteria_table), ...
        'Legacy Part4 reuse should expose one empty-but-valid figure criteria table.');
    assert(isstruct(summary.plot_contract_audit), ...
        'Legacy Part4 reuse should expose a plot contract audit struct.');
    assert(isnan(summary.leading_mode_position), ...
        'No-plot cases should preserve a NaN plotted-lead position.');
    assert(isnan(summary.leading_sigma_r), ...
        'No-plot cases should surface NaN leading-mode fields rather than crashing.');
    assert(strcmp(summary.leading_mode_resolution.status, 'no_physical_plot_candidate'), ...
        'The summary should keep the explicit no-plot audit status.');

    fprintf('[test_run_user_test_reuse_no_plot_lead_v6] PASS\n');
end

function Config = local_make_reuse_config(project_root)
%LOCAL_MAKE_REUSE_CONFIG Build one minimal Config that matches the runner defaults.

    Config = struct();
    Config.Nx_raw = 270;
    Config.Ny_raw = 128;
    Config.ds_x = 1;
    Config.ds_y = 1;
    Config.boundary_map = struct('north', 'inlet');
    Config.beta = 0.0;
    Config.n_eigs = 80;
    Config.sigma = 0.05 + 0.02i;
    Config.sigma_triplet = [0.00 + 0.005i, 0.00 + 0.010i, 0.00 + 0.020i, 0.02 + 0.020i, 0.05 + 0.020i];
    Config.krylov_dimension_floor = 120;
    Config.krylov_dimension_cap = 180;
    Config.state_layout = 'primitive5_u_v_w_T_p';
    Config.operator_model = 'paperA_primitive5_direct_v6';
    Config.use_sponge = false;
    Config.use_semi_artificial_viscosity = true;
    Config.semi_artificial_viscosity = struct( ...
        'epsilon', 5.0e-2, ...
        'shock_percentile', 85.0, ...
        'dilation_steps', 5, ...
        'near_wall_fraction', 0.10);
    Config.use_shock_source_regularization = false;
    Config.shock_source_regularization = struct( ...
        'clip_percentile', 95.0, ...
        'dmu_clip_percentile', 95.0, ...
        'zero_second_derivatives_in_shock', true, ...
        'suppress_viscosity_gradient_terms_in_shock', true);
    Config.pressure_row_regularization = struct( ...
        'enabled', false, ...
        'gradient_clip_percentile', 95.0, ...
        'divergence_clip_percentile', 95.0, ...
        'suppress_pressure_gradients_in_shock', false, ...
        'suppress_divergence_in_shock', false);
    Config.benchmark_profile = 'sidharth2018_code_correction_v1';
    Config.target_benchmark = 'Sidharth2018';
    Config.plot_contract = 'paperA_reference_mainset_v1';
    Config.secondary_plot_contract = 'sidharth2018_reproduction_v1';
    Config.reference_scales = struct('defined', false);
    Config.structural_only = true;
    Config.datafile = fullfile(project_root, 'double_wedge_baseflow.dat');
end

function case_identity = local_make_case_identity(project_root)
%LOCAL_MAKE_CASE_IDENTITY Build one reuse-matching case identity payload.

    baseflow_file = fullfile(project_root, 'double_wedge_baseflow.dat');
    case_identity = struct();
    case_identity.baseflow_file = baseflow_file;
    case_identity.baseflow_file_token = local_normalize_path_token(baseflow_file);
    case_identity.baseflow_file_display = '[project_root]\double_wedge_baseflow.dat';
    case_identity.expected_dims = [270, 128];
    case_identity.stride = [1, 1];
    case_identity.top_type = 'inlet';
    case_identity.benchmark_profile = 'sidharth2018_code_correction_v1';
    case_identity.part3_variant_requested = 'current_v6';
    case_identity.part3_variant_used = 'current_v6';
end

function part4 = local_make_no_plot_part4(Config)
%LOCAL_MAKE_NO_PLOT_PART4 Build one tiny Part4 payload with no plotted lead.

    n_modes = 2;
    part4 = struct();
    part4.Config = Config;
    part4.EigVals_s = [0.01 + 0.02i; 0.00 + 0.01i];
    part4.St_s = [0.02; 0.01];
    part4.freq_signed_s = [0.02; 0.01];
    part4.OmegaVals_s = 2 * pi * part4.freq_signed_s;
    part4.res_s = [1.0e-8; 2.0e-8];
    part4.res_active_s = part4.res_s;
    part4.res_algebraic_s = [1.0e-10; 1.0e-10];
    part4.res_scaled_s = part4.res_s;
    part4.bubble_overlap_s = [0.01; 0.01];
    part4.wall_energy_frac_s = [0.08; 0.07];
    part4.near_wall_energy_frac_s = [0.08; 0.07];
    part4.free_stream_energy_frac_s = [0.60; 0.55];
    part4.sponge_energy_frac_s = zeros(n_modes, 1);
    part4.shock_energy_frac_s = [0.45; 0.40];
    part4.outlet_energy_frac_s = [0.10; 0.12];
    part4.outlet_wall_energy_frac_s = [0.03; 0.04];
    part4.checker_ratio_s = [0.4; 0.5];
    part4.farfield_ratio_s = [0.60; 0.55];
    part4.highfreq_ratio_s = [0.30; 0.35];
    part4.ranking_table = table( ...
        [11; 12], ...
        false(n_modes, 1), ...
        false(n_modes, 1), ...
        'VariableNames', {'mode_index', 'selected_for_plots', 'selected_for_publication'});
    part4.MatrixHealth = struct('row_norm_ratio_before', 10.0, 'row_norm_ratio_after', 2.0);
    part4.mode_validity_report = struct( ...
        'publication_allowed', false, ...
        'primary_reason', 'no_physical_plot_candidate');
    part4.selection_summary = struct( ...
        'status', 'no_physical_plot_candidates', ...
        'plot_status', 'no_physical_plot_candidates', ...
        'plot_lead_status', 'no_physical_plot_candidate');
    part4.ModeSelectionAudit = struct([]);
    part4.freq_label = 'f_nd';
end

function token = local_normalize_path_token(path_value)
%LOCAL_NORMALIZE_PATH_TOKEN Match the runner reuse token contract.

    token = char(string(path_value));
    try
        token = char(java.io.File(token).getCanonicalPath());
    catch
        % Keep the original token if canonicalization is unavailable.
    end
    token = lower(strrep(token, '/', filesep));
end
