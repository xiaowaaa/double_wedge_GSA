function test_refresh_saved_paperA_outputs_preserve_order()
%TEST_REFRESH_SAVED_PAPERA_OUTPUTS_PRESERVE_ORDER
% Redrawing saved figures must not change the saved Part4 plot-lead index.

    paths = setup_double_wedge_paths('IncludeTests', true);
    project_root = paths.project_root;

    case_dir = fullfile(project_root, 'outputs', 'mat', 'test_refresh_saved_paperA_outputs_preserve_order');
    if exist(case_dir, 'dir') == 7
        rmdir(case_dir, 's');
    end
    mkdir(case_dir);

    [data, part4] = local_make_saved_case();
    save(fullfile(case_dir, 'Part3_Results.mat'), '-struct', 'data', '-v7.3');
    save(fullfile(case_dir, 'Part4_Results.mat'), '-struct', 'part4', '-v7.3');

    result = refresh_saved_paperA_outputs(case_dir, 'PreserveSavedOrder', true);
    saved = load(fullfile(case_dir, 'Part4_Results.mat'), 'FigureAudit', 'PlotContractAudit');

    assert(result.FigureAudit.lead_plot_index == 2, ...
        'Refresh should preserve the saved plotted-lead position.');
    assert(saved.FigureAudit.lead_plot_index == 2, ...
        'The appended FigureAudit should remain consistent with saved Part4 arrays.');
    assert(strcmp(saved.PlotContractAudit.sidharth_component_contract, 'literature_style_bubble_components'), ...
        'Refresh should append the unified literature-style plotting contract.');
    assert(strcmp(saved.PlotContractAudit.sidharth_gallery_component, 'u'), ...
        'Refresh should retain a meaningful gallery component for inactive w'' cases.');
    assert(exist(fullfile(case_dir, 'figs', 'Fig20_LeadingMode2DDisturbance_uvTp.png'), 'file') ~= 2, ...
        'Refresh should not regenerate the retired dedicated disturbance figure.');
    assert(exist(fullfile(case_dir, 'figs', 'Sidharth_Fig14_主模态分离泡分量图.png'), 'file') == 2, ...
        'Refresh should regenerate the literature-style component figure.');

    fprintf('[test_refresh_saved_paperA_outputs_preserve_order] PASS\n');
end

function [data, part4] = local_make_saved_case()
%LOCAL_MAKE_SAVED_CASE Build a tiny saved-order Part3/Part4 pair.

    Ny = 9;
    Nx = 11;
    [X, Y] = meshgrid(linspace(0.0, 2.0, Nx), linspace(0.0, 0.8, Ny));
    layout = get_state_layout_info('primitive5_u_v_w_T_p');
    bubble = X > 0.55 & X < 1.55 & Y > 0.15 & Y < 0.65;

    Config = struct();
    Config.Cv_nd = 0.12;
    Config.beta = 0.0;
    Config.state_layout = layout.name;
    Config.target_benchmark = 'Sidharth2018';
    Config.plot_contract = 'paperA_reference_mainset_v1';
    Config.secondary_plot_contract = 'sidharth2018_reproduction_v1';
    Config.mode_filter = struct('near_wall_fraction', 0.20);

    data = struct();
    data.Config = Config;
    data.Nx = Nx;
    data.Ny = Ny;
    data.X = X;
    data.Y = Y;
    data.U = ones(Ny, Nx);
    data.V = zeros(Ny, Nx);
    data.RHO = ones(Ny, Nx);
    data.GeometryAudit = struct('bubble_window', [0.45, 1.65, 0.10, 0.70]);
    data.BaseflowMasks = struct( ...
        'bubble_mask', bubble, ...
        'bubble_core_mask', bubble, ...
        'bubble_support_mask', bubble, ...
        'near_wall_mask', repmat((1:Ny).' <= 3, 1, Nx), ...
        'shock_core_mask', false(Ny, Nx), ...
        'shock_outer_mask', false(Ny, Nx), ...
        'outlet_mask', X > 1.8, ...
        'outlet_wall_mask', X > 1.8 & repmat((1:Ny).' <= 3, 1, Nx), ...
        'free_stream_mask', Y > 0.65);

    q1 = local_mode_vector(layout, Ny, Nx, X, Y, 0.9, 0.4);
    q2 = local_mode_vector(layout, Ny, Nx, X, Y, 1.1, 0.45);
    part4 = struct();
    part4.Config = Config;
    part4.EigVals_s = [0.02 + 0.01i; 0.01 + 0.02i];
    part4.EigVecs_s = [q1, q2];
    part4.res_s = [1.0e-8; 2.0e-8];
    part4.res_active_s = part4.res_s;
    part4.res_algebraic_s = part4.res_s;
    part4.res_scaled_s = part4.res_s;
    part4.freq_signed_s = [-0.01; -0.02];
    part4.St_s = abs(part4.freq_signed_s);
    part4.physical_candidate_score_s = [3.0; 4.0];
    part4.bubble_overlap_s = [0.5; 0.6];
    part4.near_wall_energy_frac_s = [0.8; 0.8];
    part4.shock_energy_frac_s = [0.0; 0.0];
    part4.outlet_energy_frac_s = [0.0; 0.0];
    part4.outlet_wall_energy_frac_s = [0.0; 0.0];
    part4.free_stream_energy_frac_s = [0.0; 0.0];
    part4.checker_ratio_s = [0.0; 0.0];
    part4.ranking_table = table([101; 102], true(2, 1), true(2, 1), ...
        'VariableNames', {'mode_index', 'selected_for_plots', 'selected_for_publication'});
    part4.plot_leading_mode_position = 2;
    part4.selection_summary = struct( ...
        'status', 'physical_plot_candidates_available', ...
        'plot_status', 'physical_plot_candidates_available', ...
        'plot_leading_mode_position', 2);
end

function q = local_mode_vector(layout, Ny, Nx, X, Y, x0, y0)
%LOCAL_MODE_VECTOR Build one primitive-five mode with inactive w'.

    shape = exp(-((X - x0).^2 + (Y - y0).^2) / 0.08);
    q = zeros(layout.nvar * Ny * Nx, 1);
    q(1:layout.nvar:end) = shape(:);
    q(2:layout.nvar:end) = 0.4 * shape(:);
    q(3:layout.nvar:end) = 0.0;
    q(4:layout.nvar:end) = 0.8 * shape(:);
    q(5:layout.nvar:end) = 0.2 * shape(:);
end
