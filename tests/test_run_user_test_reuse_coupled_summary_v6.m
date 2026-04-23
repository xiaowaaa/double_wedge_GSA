function test_run_user_test_reuse_coupled_summary_v6()
%TEST_RUN_USER_TEST_REUSE_COUPLED_SUMMARY_V6 Reuse a synthetic Part4 case with coupled-mode metadata.

    paths = setup_double_wedge_paths('IncludeTests', true);
    project_root = paths.project_root;

    case_name = 'test_run_user_test_reuse_coupled_summary_v6';
    case_dir = fullfile(project_root, 'outputs', 'mat', case_name);
    if exist(case_dir, 'dir') == 7
        rmdir(case_dir, 's');
    end
    mkdir(case_dir);

    old_dir = pwd;
    cleanup_obj = onCleanup(@() cd(old_dir)); %#ok<NASGU>
    cd(case_dir);

    Config = local_make_reuse_config(project_root);
    BaseValidation = struct('eos_relative_error', 0.0, 'wall_temperature_relative_mismatch', 0.0); %#ok<NASGU>
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

    part4 = local_make_coupled_part4(Config);
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
    assert(summary.leading_mode_available, ...
        'The synthetic coupled case should preserve one available plotted lead.');
    assert(istable(summary.baseflow_reference_table), ...
        'Legacy Part2 reuse should be backfilled with a baseflow reference table.');
    assert(istable(summary.mode_reference_table), ...
        'Legacy Part4 reuse should expose a mode reference table field.');
    assert(isstruct(summary.plot_provenance_audit), ...
        'Legacy Part4 reuse should expose one plot provenance audit struct.');
    assert(strcmp(summary.leading_mode_family, 'shock_bubble_coupled'), ...
        'The runner summary should surface the coupled-mode family label.');
    assert(abs(summary.leading_physical_candidate_score - 4.5) < 1.0e-12, ...
        'The runner summary should keep the physical-candidate score.');
    assert(strcmp(summary.leading_reference_component, 'w'), ...
        'The runner summary should expose the saved reference component.');
    assert(summary.adjoint_lead_audit.enabled, ...
        'The runner summary should carry the saved adjoint/wavemaker audit.');
    assert(summary.has_wavemaker_map, ...
        'The runner summary should detect that a wavemaker map is present.');

    fprintf('[test_run_user_test_reuse_coupled_summary_v6] PASS\n');
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
    Config.analysis = struct('compute_adjoint_lead', true);
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

function part4 = local_make_coupled_part4(Config)
%LOCAL_MAKE_COUPLED_PART4 Build one tiny Part4 payload with a coupled plotted lead.

    n_modes = 2;
    part4 = struct();
    part4.Config = Config;
    part4.EigVals_s = [0.02 + 0.01i; -0.01 + 0.02i];
    part4.St_s = [0.015; 0.020];
    part4.freq_signed_s = [0.015; 0.020];
    part4.OmegaVals_s = 2 * pi * part4.freq_signed_s;
    part4.res_s = [1.0e-8; 3.0e-8];
    part4.res_active_s = part4.res_s;
    part4.res_algebraic_s = [1.0e-10; 1.0e-10];
    part4.res_scaled_s = part4.res_s;
    part4.bubble_overlap_s = [0.26; 0.04];
    part4.wall_energy_frac_s = [0.32; 0.10];
    part4.near_wall_energy_frac_s = [0.28; 0.12];
    part4.free_stream_energy_frac_s = [0.05; 0.28];
    part4.sponge_energy_frac_s = zeros(n_modes, 1);
    part4.shock_energy_frac_s = [0.18; 0.42];
    part4.outlet_energy_frac_s = [0.03; 0.10];
    part4.outlet_wall_energy_frac_s = [0.02; 0.08];
    part4.checker_ratio_s = [0.40; 0.55];
    part4.farfield_ratio_s = [0.05; 0.30];
    part4.highfreq_ratio_s = [0.08; 0.22];
    part4.ModeFamily_s = {'shock_bubble_coupled'; 'boundary_supported'}; %#ok<STRNU>
    part4.physical_candidate_score_s = [4.5; -1.0];
    part4.bubble_shock_phase_deg_s = [5.0; 170.0];
    part4.bubble_shock_sync_s = [0.996; -0.985];
    part4.ranking_table = table( ...
        [21; 22], ...
        true(n_modes, 1), ...
        [true; false], ...
        [true; false], ...
        'VariableNames', {'mode_index', 'plot_candidate', 'selected_for_publication', 'selected_for_plots'});
    part4.MatrixHealth = struct('row_norm_ratio_before', 10.0, 'row_norm_ratio_after', 2.0);
    part4.selection_summary = struct( ...
        'status', 'physical_plot_candidates_available', ...
        'plot_status', 'physical_plot_candidates_available', ...
        'plot_lead_status', 'physical_plot_candidate', ...
        'plot_leading_mode_position', 1, ...
        'plot_leading_mode_index', 21, ...
        'plot_leading_mode_original_index', 21, ...
        'leading_mode_family', 'shock_bubble_coupled', ...
        'leading_physical_candidate_score', 4.5);
    part4.mode_validity_report = struct( ...
        'publication_allowed', true, ...
        'primary_reason', 'paperA_coupled_physical_mode');
    part4.ModeSelectionAudit = struct([]);
    part4.ModeCouplingAudit = repmat(struct( ...
        'original_mode_index', 0, ...
        'reference_component', '', ...
        'mode_family', '', ...
        'physical_candidate_score', NaN), n_modes, 1);
    part4.ModeCouplingAudit(1).original_mode_index = 21;
    part4.ModeCouplingAudit(1).reference_component = 'w';
    part4.ModeCouplingAudit(1).mode_family = 'shock_bubble_coupled';
    part4.ModeCouplingAudit(1).physical_candidate_score = 4.5;
    part4.ModeCouplingAudit(2).original_mode_index = 22;
    part4.ModeCouplingAudit(2).reference_component = 'u';
    part4.ModeCouplingAudit(2).mode_family = 'boundary_supported';
    part4.ModeCouplingAudit(2).physical_candidate_score = -1.0;
    part4.AdjointLeadAudit = struct( ...
        'enabled', true, ...
        'wavemaker_bubble_frac', 0.78, ...
        'wavemaker_shock_frac', 0.12, ...
        'reason', '');
    part4.WavemakerLeadMap = ones(2, 2);
    part4.freq_label = 'f_nd';
    part4.plot_leading_mode_position = 1;
    part4.plot_leading_mode_index = 21;
    part4.plot_leading_mode_original_index = 21;
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
