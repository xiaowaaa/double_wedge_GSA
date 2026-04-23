function test_plot_lead_selection()
%TEST_PLOT_LEAD_SELECTION Ensure debug-only modes are not silently promoted for plotting.

    setup_double_wedge_paths('IncludeTests', true);

    ranking = local_minimal_ranking();
    [lead_idx, audit] = select_paperA_plot_lead_index(ranking);
    assert(isnan(lead_idx), ...
        'No plotted lead should be chosen when selected_for_plots is empty.');
    assert(strcmp(audit.status, 'no_physical_plot_candidate'), ...
        'The selector should report the absence of physical plot candidates explicitly.');

    ranking.selected_for_plots = [true; true];
    ranking.metrics.u_peak_in_bubble = [true; false];
    ranking.metrics.bubble_core_overlap = [0.25; 0.05];
    ranking.metrics.bubble_support_overlap = [0.40; 0.10];
    ranking.metrics.near_wall_energy_frac = [0.30; 0.12];
    ranking.metrics.shock_energy_frac = [0.05; 0.15];
    ranking.metrics.shock_core_energy_frac = [0.01; 0.08];
    ranking.metrics.outlet_energy_frac = [0.02; 0.10];
    ranking.metrics.outlet_wall_energy_frac = [0.01; 0.12];
    ranking.metrics.free_stream_energy_frac = [0.05; 0.10];
    ranking.metrics.checker_ratio = [0.5; 0.8];
    ranking.EigVals = [0.02 + 0.01i; 0.01 + 0.01i];
    ranking.residuals = [1.0e-8; 1.0e-7];
    [lead_idx, audit] = select_paperA_plot_lead_index(ranking);
    assert(lead_idx == 1, 'The stronger physical candidate should be selected for plotting.');
    assert(strcmp(audit.status, 'physical_plot_candidate'), ...
        'The selector should confirm a physical plot candidate when one exists.');

    ranking = local_minimal_ranking();
    ranking.selected_for_plots = [true; true];
    ranking.plot_lead_candidate_mask = [true; true];
    ranking.metrics.u_peak_in_bubble = [true; false];
    ranking.metrics.bubble_core_overlap = [0.20; 0.20];
    ranking.metrics.bubble_support_overlap = [0.25; 0.25];
    ranking.metrics.near_wall_energy_frac = [0.20; 0.20];
    [lead_idx, ~] = select_paperA_plot_lead_index(ranking);
    assert(lead_idx == 1, ...
        'A u'' bubble peak should be rewarded, not penalized, during plot-lead selection.');

    ranking = local_rank_with_gallery_truncated_lead();
    [lead_idx, audit] = select_paperA_plot_lead_index(ranking);
    assert(lead_idx == 5, ...
        'The plotted lead should be selected from all plot-lead candidates, not only the gallery subset.');
    assert(strcmp(audit.candidate_source, 'plot_lead_candidate_mask'), ...
        'The selector audit should record that it used the full plot-lead candidate pool.');

    ranking = local_rank_with_no_physical_candidates();
    assert(~any(ranking.selected_for_plots), ...
        'Ranking should no longer fall back to debug-only modes for plotting.');
    assert(strcmp(ranking.selection_summary.plot_status, 'no_physical_plot_candidates'), ...
        'Ranking summary should record that no physical plot candidates were found.');
    assert(strcmp(ranking.selection_summary.status, 'no_physical_plot_candidates'), ...
        'The top-level selection status should match the no-plot outcome.');

    ranking = local_rank_with_high_residual_bubble_mode();
    assert(strcmp(ranking.selection_summary.ranking_status, 'debug_all_modes_fallback'), ...
        'High-residual modes may still be ranked for debugging, but only in debug mode.');
    assert(ranking.selection_summary.num_residual_modes == 0, ...
        'This regression case requires every mode to fail the residual threshold.');
    assert(ranking.selection_summary.num_plot_candidates == 0, ...
        'No residual-clean mode should remain eligible for plotting.');
    assert(ranking.selection_summary.num_selected_modes == 0, ...
        'Debug ranking fallback must not silently repopulate selected_for_plots.');
    assert(strcmp(ranking.selection_summary.status, 'no_physical_plot_candidates'), ...
        'Selection summary should keep the explicit no-plot status when residuals all fail.');
    assert(~any(ranking.plot_candidate_mask), ...
        'plot_candidate_mask should stay empty when no residual-qualified mode exists.');
    [lead_idx, audit] = select_paperA_plot_lead_index(ranking);
    assert(isnan(lead_idx), ...
        'No plotted lead should be selected when only high-residual debug modes remain.');
    assert(strcmp(audit.status, 'no_physical_plot_candidate'), ...
        'The plot-lead selector should preserve the explicit no-physical-candidate status.');

    ranking = local_rank_with_checker_failed_bubble_mode();
    assert(strcmp(ranking.selection_summary.ranking_status, 'residual_only_fallback'), ...
        'Residual-clean checker-failed modes may still be ranked for diagnostics.');
    assert(ranking.selection_summary.num_residual_modes == 1 && ranking.selection_summary.num_checker_modes == 0, ...
        'This regression case requires a residual-clean mode that fails checker gating.');
    assert(ranking.selection_summary.num_plot_candidates == 0, ...
        'Residual-only fallback modes must not remain eligible for plotting.');
    assert(~any(ranking.selected_for_plots), ...
        'Residual-only fallback must not silently promote checker-failed modes to plotted leads.');

    ranking = local_rank_with_pressure_checker_tail();
    assert(~any(ranking.selected_for_plots), ...
        'A Sidharth-like bubble mode with a p'' checker tail must not be selected for plotting.');
    assert(ranking.selection_summary.num_pressure_quality_candidates == 0, ...
        'Pressure-quality gating should reject the p'' checker-tail regression mode.');
    assert(ranking.metrics.p_checker_ratio(1) >= ranking.selection_summary.pressure_checker_threshold_used, ...
        'The regression mode should fail by the pressure checker threshold.');

    fprintf('[test_plot_lead_selection] PASS\n');
end

function ranking = local_rank_with_gallery_truncated_lead()
%LOCAL_RANK_WITH_GALLERY_TRUNCATED_LEAD Build five plot candidates with the best lead fifth.

    n = 5;
    ranking = struct();
    ranking.EigVals = (0.01:0.01:0.05).' + 0.01i;
    ranking.residuals = 1.0e-8 * ones(n, 1);
    ranking.selected_for_plots = [true; true; true; true; false];
    ranking.plot_lead_candidate_mask = true(n, 1);
    ranking.metrics = struct( ...
        'u_peak_in_bubble', false(n, 1), ...
        'bubble_core_overlap', 0.10 * ones(n, 1), ...
        'bubble_support_overlap', 0.15 * ones(n, 1), ...
        'near_wall_energy_frac', 0.20 * ones(n, 1), ...
        'shock_energy_frac', 0.02 * ones(n, 1), ...
        'shock_core_energy_frac', zeros(n, 1), ...
        'u_peak_in_shock_core', false(n, 1), ...
        'outlet_energy_frac', zeros(n, 1), ...
        'outlet_wall_energy_frac', zeros(n, 1), ...
        'u_peak_in_outlet_wall', false(n, 1), ...
        'free_stream_energy_frac', 0.02 * ones(n, 1), ...
        'checker_ratio', 0.1 * ones(n, 1), ...
        'physical_candidate_score', zeros(n, 1), ...
        'family_priority', zeros(n, 1));
    ranking.metrics.physical_candidate_score(5) = 10.0;
end

function ranking = local_minimal_ranking()
%LOCAL_MINIMAL_RANKING Build one selector-only ranking stub.

    ranking = struct();
    ranking.EigVals = [0.01 + 0.02i; 0.00 + 0.01i];
    ranking.residuals = [1.0e-8; 1.0e-8];
    ranking.selected_for_plots = [false; false];
    ranking.metrics = struct( ...
        'u_peak_in_bubble', false(2, 1), ...
        'bubble_core_overlap', zeros(2, 1), ...
        'bubble_support_overlap', zeros(2, 1), ...
        'near_wall_energy_frac', zeros(2, 1), ...
        'shock_energy_frac', zeros(2, 1), ...
        'shock_core_energy_frac', zeros(2, 1), ...
        'u_peak_in_shock_core', false(2, 1), ...
        'outlet_energy_frac', zeros(2, 1), ...
        'outlet_wall_energy_frac', zeros(2, 1), ...
        'u_peak_in_outlet_wall', false(2, 1), ...
        'free_stream_energy_frac', zeros(2, 1), ...
        'checker_ratio', zeros(2, 1));
end

function ranking = local_rank_with_no_physical_candidates()
%LOCAL_RANK_WITH_NO_PHYSICAL_CANDIDATES Run the real ranking path on one free-stream mode.

    Ny = 18;
    Nx = 20;
    [X, Y] = meshgrid(linspace(0.0, 1.0, Nx), linspace(0.0, 1.0, Ny));
    layout = get_state_layout_info('primitive5_u_v_w_T_p');

    q_mode = zeros(layout.nvar * Ny * Nx, 1);
    u_field = double(Y > 0.80);
    q_mode(1:layout.nvar:end) = u_field(:);

    data = struct();
    data.Ny = Ny;
    data.Nx = Nx;
    data.X = X;
    data.Y = Y;
    data.U = ones(Ny, Nx);
    data.RHO = ones(Ny, Nx);
    data.sigma_sp = zeros(Ny, Nx);
    data.BoundaryMasks = struct();
    data.BaseflowPhysicsAudit = struct('structural_only_warning', false);

    Config = struct();
    Config.Cv_nd = 0.12;
    Config.n_eigs = 4;
    Config.state_layout = layout.name;
    Config.mode_filter = struct( ...
        'near_wall_fraction', 0.15, ...
        'bubble_fraction_threshold', 0.05, ...
        'bubble_core_fraction_threshold', 0.03, ...
        'bubble_support_fraction_threshold', 0.05, ...
        'shock_fraction_threshold', 0.35, ...
        'shock_core_fraction_threshold', 0.15, ...
        'free_stream_fraction_threshold', 0.20, ...
        'outlet_fraction_threshold', 0.35, ...
        'outlet_wall_fraction_threshold', 0.20, ...
        'residual_threshold', 1.0e-4, ...
        'checker_threshold', 5.0, ...
        'checker_threshold_structural', 20.0);

    masks = struct();
    masks.bubble = false(Ny, Nx);
    masks.bubble_core = false(Ny, Nx);
    masks.bubble_support = false(Ny, Nx);
    masks.near_wall = false(Ny, Nx);
    masks.near_wall(1:3, :) = true;
    masks.free_stream = Y >= 0.50;
    masks.shock = false(Ny, Nx);
    masks.shock_core = false(Ny, Nx);
    masks.outlet = X >= 0.88;
    masks.outlet_wall = masks.outlet & masks.near_wall;
    masks.corner = false(Ny, Nx);
    masks.bad_point = false(Ny, Nx);

    ranking = rank_paperA_modes( ...
        0.01 + 0.02i, q_mode, 1.0e-8, 1.0e-8, 1.0e-10, 1.0e-8, ...
        data, Config, masks);
end

function ranking = local_rank_with_high_residual_bubble_mode()
%LOCAL_RANK_WITH_HIGH_RESIDUAL_BUBBLE_MODE Keep bubble-looking debug modes out of the plot pool.

    Ny = 24;
    Nx = 28;
    [X, Y] = meshgrid(linspace(0.0, 1.0, Nx), linspace(0.0, 1.0, Ny));
    layout = get_state_layout_info('primitive5_u_v_w_T_p');

    bubble = exp(-((X - 0.35).^2 / 0.012 + (Y - 0.08).^2 / 0.003));
    q_mode = zeros(layout.nvar * Ny * Nx, 1);
    q_mode(1:layout.nvar:end) = bubble(:);
    q_mode(2:layout.nvar:end) = 0.25 * bubble(:);

    data = struct();
    data.Ny = Ny;
    data.Nx = Nx;
    data.X = X;
    data.Y = Y;
    data.U = ones(Ny, Nx);
    data.RHO = ones(Ny, Nx);
    data.sigma_sp = zeros(Ny, Nx);
    data.BoundaryMasks = struct();
    data.BaseflowPhysicsAudit = struct('structural_only_warning', false);

    Config = struct();
    Config.Cv_nd = 0.12;
    Config.n_eigs = 4;
    Config.state_layout = layout.name;
    Config.mode_filter = struct( ...
        'near_wall_fraction', 0.15, ...
        'bubble_fraction_threshold', 0.05, ...
        'bubble_core_fraction_threshold', 0.03, ...
        'bubble_support_fraction_threshold', 0.05, ...
        'shock_fraction_threshold', 0.35, ...
        'shock_core_fraction_threshold', 0.15, ...
        'free_stream_fraction_threshold', 0.20, ...
        'outlet_fraction_threshold', 0.35, ...
        'outlet_wall_fraction_threshold', 0.20, ...
        'residual_threshold', 1.0e-4, ...
        'checker_threshold', 5.0, ...
        'checker_threshold_structural', 20.0);

    masks = struct();
    masks.bubble = bubble > 0.20;
    masks.bubble_core = bubble > 0.35;
    masks.bubble_support = bubble > 0.15;
    masks.near_wall = false(Ny, Nx);
    masks.near_wall(1:4, :) = true;
    masks.free_stream = Y >= 0.50;
    masks.shock = false(Ny, Nx);
    masks.shock_core = false(Ny, Nx);
    masks.outlet = X >= 0.88;
    masks.outlet_wall = masks.outlet & masks.near_wall;
    masks.corner = false(Ny, Nx);
    masks.bad_point = false(Ny, Nx);

    ranking = rank_paperA_modes( ...
        0.02 + 0.01i, q_mode, 1.0e-2, 1.0e-2, 1.0e-3, 1.0e-2, ...
        data, Config, masks);
end

function ranking = local_rank_with_checker_failed_bubble_mode()
%LOCAL_RANK_WITH_CHECKER_FAILED_BUBBLE_MODE Keep checker-failed residual modes out of plots.

    Ny = 24;
    Nx = 28;
    [X, Y] = meshgrid(linspace(0.0, 1.0, Nx), linspace(0.0, 1.0, Ny));
    layout = get_state_layout_info('primitive5_u_v_w_T_p');

    bubble = exp(-((X - 0.35).^2 / 0.012 + (Y - 0.08).^2 / 0.003));
    q_mode = zeros(layout.nvar * Ny * Nx, 1);
    q_mode(1:layout.nvar:end) = bubble(:);
    q_mode(2:layout.nvar:end) = 0.25 * bubble(:);

    data = struct();
    data.Ny = Ny;
    data.Nx = Nx;
    data.X = X;
    data.Y = Y;
    data.U = ones(Ny, Nx);
    data.RHO = ones(Ny, Nx);
    data.sigma_sp = zeros(Ny, Nx);
    data.BoundaryMasks = struct();
    data.BaseflowPhysicsAudit = struct('structural_only_warning', false);

    Config = struct();
    Config.Cv_nd = 0.12;
    Config.n_eigs = 4;
    Config.state_layout = layout.name;
    Config.mode_filter = struct( ...
        'near_wall_fraction', 0.15, ...
        'bubble_fraction_threshold', 0.05, ...
        'bubble_core_fraction_threshold', 0.03, ...
        'bubble_support_fraction_threshold', 0.05, ...
        'shock_fraction_threshold', 0.35, ...
        'shock_core_fraction_threshold', 0.15, ...
        'free_stream_fraction_threshold', 0.20, ...
        'outlet_fraction_threshold', 0.35, ...
        'outlet_wall_fraction_threshold', 0.20, ...
        'residual_threshold', 1.0e-4, ...
        'checker_threshold', 1.0e-6, ...
        'checker_threshold_structural', 1.0e-6, ...
        'pressure_checker_threshold', 1.0, ...
        'pressure_checker_threshold_structural', 1.0);

    masks = struct();
    masks.bubble = bubble > 0.20;
    masks.bubble_core = bubble > 0.35;
    masks.bubble_support = bubble > 0.15;
    masks.near_wall = false(Ny, Nx);
    masks.near_wall(1:4, :) = true;
    masks.free_stream = Y >= 0.50;
    masks.shock = false(Ny, Nx);
    masks.shock_core = false(Ny, Nx);
    masks.outlet = X >= 0.88;
    masks.outlet_wall = masks.outlet & masks.near_wall;
    masks.corner = false(Ny, Nx);
    masks.bad_point = false(Ny, Nx);

    ranking = rank_paperA_modes( ...
        0.02 + 0.01i, q_mode, 1.0e-8, 1.0e-8, 1.0e-10, 1.0e-8, ...
        data, Config, masks);
end

function ranking = local_rank_with_pressure_checker_tail()
%LOCAL_RANK_WITH_PRESSURE_CHECKER_TAIL Reject p-only acoustic/checker contamination.

    Ny = 24;
    Nx = 28;
    [X, Y] = meshgrid(linspace(0.0, 1.0, Nx), linspace(0.0, 1.0, Ny));
    layout = get_state_layout_info('primitive5_u_v_w_T_p');

    bubble = exp(-((X - 0.35).^2 / 0.012 + (Y - 0.08).^2 / 0.003));
    checker_amp = repmat(mod((1:Ny).', 2), 1, Nx) + repmat(mod(1:Nx, 2), Ny, 1);
    checker_amp = double(mod(checker_amp, 2) == 0);
    pressure_tail_mask = Y >= 0.50 | X >= 0.86;
    pressure_tail = checker_amp .* pressure_tail_mask;

    q_mode = zeros(layout.nvar * Ny * Nx, 1);
    q_mode(1:layout.nvar:end) = bubble(:);
    q_mode(3:layout.nvar:end) = 0.8 * bubble(:);
    q_mode(5:layout.nvar:end) = pressure_tail(:);

    data = struct();
    data.Ny = Ny;
    data.Nx = Nx;
    data.X = X;
    data.Y = Y;
    data.U = ones(Ny, Nx);
    data.RHO = ones(Ny, Nx);
    data.sigma_sp = zeros(Ny, Nx);
    data.BoundaryMasks = struct();
    data.BaseflowPhysicsAudit = struct('structural_only_warning', false);

    Config = struct();
    Config.Cv_nd = 0.12;
    Config.n_eigs = 4;
    Config.state_layout = layout.name;
    Config.target_benchmark = 'Sidharth2018';
    Config.mode_filter = struct( ...
        'near_wall_fraction', 0.15, ...
        'bubble_fraction_threshold', 0.05, ...
        'bubble_core_fraction_threshold', 0.03, ...
        'bubble_support_fraction_threshold', 0.05, ...
        'shock_fraction_threshold', 0.35, ...
        'shock_core_fraction_threshold', 0.15, ...
        'free_stream_fraction_threshold', 0.20, ...
        'outlet_fraction_threshold', 0.35, ...
        'outlet_wall_fraction_threshold', 0.20, ...
        'residual_threshold', 1.0e-4, ...
        'checker_threshold', 5.0, ...
        'checker_threshold_structural', 20.0, ...
        'pressure_checker_threshold', 1.0, ...
        'pressure_checker_threshold_structural', 1.0, ...
        'pressure_free_stream_fraction_threshold', 0.35, ...
        'pressure_outlet_fraction_threshold', 0.40, ...
        'pressure_outlet_wall_fraction_threshold', 0.20, ...
        'pressure_shock_core_fraction_threshold', 0.20, ...
        'stationary_frequency_threshold', 1.0e-2);

    masks = struct();
    masks.bubble = bubble > 0.20;
    masks.bubble_core = bubble > 0.35;
    masks.bubble_support = bubble > 0.15;
    masks.near_wall = false(Ny, Nx);
    masks.near_wall(1:4, :) = true;
    masks.free_stream = Y >= 0.50;
    masks.shock = false(Ny, Nx);
    masks.shock_core = false(Ny, Nx);
    masks.outlet = X >= 0.88;
    masks.outlet_wall = masks.outlet & masks.near_wall;
    masks.corner = false(Ny, Nx);
    masks.bad_point = false(Ny, Nx);

    ranking = rank_paperA_modes( ...
        0.0 + 0.0i, q_mode, 1.0e-8, 1.0e-8, 1.0e-10, 1.0e-8, ...
        data, Config, masks);
end
