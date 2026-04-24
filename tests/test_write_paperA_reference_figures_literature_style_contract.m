function test_write_paperA_reference_figures_literature_style_contract()
%TEST_WRITE_PAPERA_REFERENCE_FIGURES_LITERATURE_STYLE_CONTRACT
% Ensure beta=0 figures still use one literature-style component layout without a retired dedicated special output.

    paths = setup_double_wedge_paths('IncludeTests', true);
    project_root = paths.project_root;

    fig_dir = fullfile(project_root, 'outputs', 'mat', 'test_write_paperA_reference_figures_literature_style_contract');
    if exist(fig_dir, 'dir') == 7
        rmdir(fig_dir, 's');
    end
    mkdir(fig_dir);

    Ny = 14;
    Nx = 16;
    [X, Y] = meshgrid(linspace(0.0, 3.0, Nx), linspace(0.0, 1.2, Ny));
    layout = get_state_layout_info('primitive5_u_v_w_T_p');
    bubble_mask = X >= 0.8 & X <= 2.1 & Y >= 0.25 & Y <= 0.9;

    u = exp(-((X - 1.45).^2 + (Y - 0.55).^2) / 0.10);
    v = 0.35 * exp(-((X - 1.55).^2 + (Y - 0.50).^2) / 0.12);
    w = zeros(Ny, Nx);
    T = 0.6 * exp(-((X - 1.50).^2 + (Y - 0.60).^2) / 0.15);
    p = 0.2 * exp(-((X - 1.35).^2 + (Y - 0.45).^2) / 0.10);
    q = zeros(layout.nvar * Ny * Nx, 1);
    q(1:layout.nvar:end) = u(:);
    q(2:layout.nvar:end) = v(:);
    q(3:layout.nvar:end) = w(:);
    q(4:layout.nvar:end) = T(:);
    q(5:layout.nvar:end) = p(:);

    ranking = local_make_single_mode_ranking(q);
    data = struct();
    data.Nx = Nx;
    data.Ny = Ny;
    data.X = X;
    data.Y = Y;
    data.U = ones(Ny, Nx);
    data.V = zeros(Ny, Nx);
    data.RHO = ones(Ny, Nx);
    data.GeometryAudit = struct('bubble_window', [0.7, 2.2, 0.2, 0.95]);
    data.BaseflowMasks = struct( ...
        'bubble_mask', bubble_mask, ...
        'bubble_core_mask', bubble_mask, ...
        'bubble_support_mask', bubble_mask, ...
        'shock_mask', false(Ny, Nx), ...
        'shock_core_mask', false(Ny, Nx));

    Config = struct();
    Config.Cv_nd = 0.12;
    Config.beta = 0.0;
    Config.state_layout = layout.name;
    Config.target_benchmark = 'Sidharth2018';
    Config.plot_contract = 'paperA_reference_mainset_v1';
    Config.secondary_plot_contract = 'sidharth2018_reproduction_v1';
    Config.plot_debug_mode_diagnosis = false;

    phase_audit = struct('type', 'bubble', 'row', 1, 'col', 1, 'x', X(1), 'y', Y(1));
    FigureAudit = write_paperA_reference_figures(fig_dir, ranking, data, Config, 1, phase_audit);

    assert(exist(fullfile(fig_dir, 'Fig20_LeadingMode2DDisturbance_uvTp.png'), 'file') ~= 2, ...
        'A beta=0 case should not emit the retired dedicated disturbance figure any more.');
    assert(exist(fullfile(fig_dir, 'Sidharth_Fig14_主模态分离泡分量图.png'), 'file') == 2, ...
        'The literature-style component figure should still be emitted.');
    assert(exist(fullfile(fig_dir, 'Sidharth_Fig15_候选模态分量图_第01页.png'), 'file') == 2, ...
        'The literature-style candidate gallery should still be emitted.');
    assert(strcmp(FigureAudit.sidharth_component_contract, 'literature_style_bubble_components'), ...
        'FigureAudit should record one unified literature-style component contract.');
    assert(isequal(FigureAudit.sidharth_displayed_components, {'u', 'v', 'T', 'p'}), ...
        'Inactive w'' cases should display the informative literature-style component subset.');
    assert(strcmp(FigureAudit.sidharth_gallery_component, 'u'), ...
        'Inactive w'' cases should fall back to a meaningful gallery component.');
    assert(isnumeric(FigureAudit.sidharth_common_plot_window) && ...
            numel(FigureAudit.sidharth_common_plot_window) == 4 && ...
            all(isfinite(FigureAudit.sidharth_common_plot_window)) && ...
            FigureAudit.sidharth_common_plot_window(2) > FigureAudit.sidharth_common_plot_window(1) && ...
            FigureAudit.sidharth_common_plot_window(4) > FigureAudit.sidharth_common_plot_window(3), ...
        'Sidharth component panels should record one finite common bubble-window crop.');

    fprintf('[test_write_paperA_reference_figures_literature_style_contract] PASS\n');
end

function ranking = local_make_single_mode_ranking(q)
%LOCAL_MAKE_SINGLE_MODE_RANKING Build the minimal one-mode ranking payload.

    ranking = struct();
    ranking.EigVals = 0.01 + 0.02i;
    ranking.EigVecs = q;
    ranking.residuals = 1.0e-8;
    ranking.selected_for_plots = true;
    ranking.plot_lead_candidate_mask = true;
    ranking.order = 1;
    ranking.freq_info = struct('freq_nd_signed', -0.02);
    ranking.metrics = struct();
    ranking.metrics.family_priority = 0;
    ranking.metrics.physical_candidate_score = 10;
    ranking.metrics.bubble_core_overlap = 0.6;
    ranking.metrics.bubble_support_overlap = 0.7;
    ranking.metrics.near_wall_energy_frac = 0.8;
    ranking.metrics.shock_energy_frac = 0.0;
    ranking.metrics.shock_core_energy_frac = 0.0;
    ranking.metrics.outlet_energy_frac = 0.0;
    ranking.metrics.outlet_wall_energy_frac = 0.0;
    ranking.metrics.free_stream_energy_frac = 0.0;
    ranking.metrics.checker_ratio = 0.0;
    ranking.metrics.u_peak_in_bubble = true;
    ranking.metrics.u_peak_in_shock_core = false;
    ranking.metrics.u_peak_in_outlet_wall = false;
    ranking.metrics.p_checker_ratio = 0.0;
    ranking.metrics.p_free_stream_overlap = 0.0;
    ranking.metrics.p_outlet_overlap = 0.0;
    ranking.metrics.p_outlet_wall_overlap = 0.0;
    ranking.metrics.p_shock_core_overlap = 0.0;
    ranking.metrics.component_support = struct();
    ranking.metrics.component_support.w = struct( ...
        'bubble_support_overlap', 0.0, ...
        'bubble_core_overlap', 0.0, ...
        'shock_core_overlap', 0.0, ...
        'peak_in_bubble_support', false, ...
        'peak_in_shock_core', false);
    ranking.metrics.component_support.p = struct( ...
        'checker_ratio', 0.0, ...
        'free_stream_overlap', 0.0, ...
        'outlet_overlap', 0.0, ...
        'outlet_wall_overlap', 0.0, ...
        'shock_core_overlap', 0.0, ...
        'peak_in_free_stream', false, ...
        'peak_in_outlet_wall', false, ...
        'peak_in_shock_core', false);
end
