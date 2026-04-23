function refresh_result = refresh_saved_paperA_outputs(case_dir, varargin)
%REFRESH_SAVED_PAPERA_OUTPUTS Re-rank and redraw one saved Paper-A case without re-solving eigs.

    p = inputParser;
    p.FunctionName = 'refresh_saved_paperA_outputs';
    addParameter(p, 'FigureDirectory', '', @(x) ischar(x) || (isstring(x) && isscalar(x)));
    addParameter(p, 'AppendAudit', true, @(x) islogical(x) || isnumeric(x));
    parse(p, varargin{:});

    case_dir = char(string(case_dir));
    part3_file = fullfile(case_dir, 'Part3_Results.mat');
    part4_file = fullfile(case_dir, 'Part4_Results.mat');
    if exist(part3_file, 'file') ~= 2 || exist(part4_file, 'file') ~= 2
        error('refresh_saved_paperA_outputs:MissingCaseFiles', ...
            'Expected Part3_Results.mat and Part4_Results.mat in %s.', case_dir);
    end

    if strlength(string(p.Results.FigureDirectory)) > 0
        fig_dir = char(string(p.Results.FigureDirectory));
    else
        fig_dir = fullfile(case_dir, 'figs');
    end

    data = load(part3_file);
    part4 = load(part4_file);
    data.Config = local_upgrade_config(data.Config);
    data = local_upgrade_baseflow_masks(data);
    masks = build_paperA_mode_masks(data, data.Config, data.Ny, data.Nx);

    ranking = rank_paperA_modes( ...
        part4.EigVals_s, part4.EigVecs_s, ...
        part4.res_s, part4.res_active_s, part4.res_algebraic_s, part4.res_scaled_s, ...
        data, data.Config, masks);
    [plot_phase_factor_s, PhaseAudit_s] = local_phase_align_modes( ...
        ranking.EigVecs, data.Ny, data.Nx, data.Config.state_layout, ...
        masks.bubble, masks.near_wall, data.X, data.Y);
    FigureAudit = write_paperA_reference_figures(fig_dir, ranking, data, data.Config, plot_phase_factor_s, PhaseAudit_s);

    refresh_result = struct();
    refresh_result.case_dir = case_dir;
    refresh_result.figure_directory = fig_dir;
    refresh_result.ranking = ranking;
    refresh_result.plot_phase_factor_s = plot_phase_factor_s;
    refresh_result.PhaseAudit_s = PhaseAudit_s;
    refresh_result.FigureAudit = FigureAudit;

    if logical(p.Results.AppendAudit)
        RefreshAudit = struct(); %#ok<NASGU>
        RefreshAudit.timestamp = datetime('now');
        RefreshAudit.figure_directory = fig_dir;
        RefreshAudit.selection_summary = ranking.selection_summary;
        RefreshAudit.lead_plot_index = FigureAudit.lead_plot_index;
        RefreshAudit.output_files = FigureAudit.output_files;
        save(part4_file, 'RefreshAudit', '-append');
    end
end

function data = local_upgrade_baseflow_masks(data)
%LOCAL_UPGRADE_BASEFLOW_MASKS Fill in bubble-support and shock-outer masks for older saved cases.

    if ~isfield(data, 'BaseflowMasks') || ~isstruct(data.BaseflowMasks)
        data.BaseflowMasks = struct();
    end
    if ~isfield(data.BaseflowMasks, 'bubble_core_mask')
        if isfield(data.BaseflowMasks, 'bubble_mask')
            data.BaseflowMasks.bubble_core_mask = logical(data.BaseflowMasks.bubble_mask);
        else
            data.BaseflowMasks.bubble_core_mask = data.U < 0;
        end
    end

    if ~isfield(data.BaseflowMasks, 'bubble_support_mask')
        bubble_core = logical(data.BaseflowMasks.bubble_core_mask);
        data.BaseflowMasks.bubble_support_mask = local_build_bubble_support(data.X, data.Y, bubble_core);
    end

    if ~isfield(data.BaseflowMasks, 'near_wall_mask')
        near_rows = min(data.Ny, max(3, round(data.Ny * data.Config.mode_filter.near_wall_fraction)));
        near_mask = false(data.Ny, data.Nx);
        near_mask(1:near_rows, :) = true;
        data.BaseflowMasks.near_wall_mask = near_mask;
    end

    if ~isfield(data.BaseflowMasks, 'shock_core_mask')
        if isfield(data.BaseflowMasks, 'shock_mask')
            data.BaseflowMasks.shock_core_mask = logical(data.BaseflowMasks.shock_mask);
        elseif isfield(data, 'ShockInfo') && isstruct(data.ShockInfo) && isfield(data.ShockInfo, 'shock_raw')
            data.BaseflowMasks.shock_core_mask = logical(data.ShockInfo.shock_raw);
        else
            data.BaseflowMasks.shock_core_mask = false(data.Ny, data.Nx);
        end
    end

    if ~isfield(data.BaseflowMasks, 'shock_outer_mask')
        data.BaseflowMasks.shock_outer_mask = logical(data.BaseflowMasks.shock_core_mask) & ...
            ~logical(data.BaseflowMasks.near_wall_mask);
    end
    if ~isfield(data.BaseflowMasks, 'outlet_mask')
        x_min = min(data.X(:));
        x_max = max(data.X(:));
        outlet_fraction = 0.12;
        if isfield(data.Config, 'mode_filter') && isfield(data.Config.mode_filter, 'outlet_fraction')
            outlet_fraction = data.Config.mode_filter.outlet_fraction;
        end
        data.BaseflowMasks.outlet_mask = data.X >= (x_max - outlet_fraction * max(x_max - x_min, eps));
    end
    if ~isfield(data.BaseflowMasks, 'outlet_wall_mask')
        data.BaseflowMasks.outlet_wall_mask = logical(data.BaseflowMasks.outlet_mask) & ...
            logical(data.BaseflowMasks.near_wall_mask);
    end
    data.BaseflowMasks.shock_mask = logical(data.BaseflowMasks.shock_outer_mask);
end

function bubble_support = local_build_bubble_support(X, Y, bubble_core)
%LOCAL_BUILD_BUBBLE_SUPPORT Reconstruct the default bubble-support mask.

    bubble_support = bubble_core;
    if ~any(bubble_core(:))
        return;
    end
    x_vals = X(bubble_core);
    y_vals = Y(bubble_core);
    dx = max(max(x_vals) - min(x_vals), eps);
    dy = max(max(y_vals) - min(y_vals), eps);
    Ly = max(Y(:)) - min(Y(:));
    x_min = min(x_vals) - 0.05 * dx;
    x_max = max(x_vals) + 0.55 * dx;
    y_cap = max(y_vals) + max(0.75 * dy, 0.04 * Ly);
    wall_y = Y(1, :);
    for ii = 1:size(X, 2)
        bubble_support(:, ii) = bubble_support(:, ii) | ...
            (X(:, ii) >= x_min & X(:, ii) <= x_max & ...
             Y(:, ii) >= wall_y(ii) & Y(:, ii) <= y_cap);
    end
end

function [phase_factors, phase_audit] = local_phase_align_modes(EigVecs, Ny, Nx, state_layout, bubble_mask, near_wall_mask, X, Y)
%LOCAL_PHASE_ALIGN_MODES Phase-align each sorted mode for plotting.

    num_modes = size(EigVecs, 2);
    phase_factors = ones(num_modes, 1);
    phase_audit = repmat(struct('type', 'none', 'row', NaN, 'col', NaN, 'x', NaN, 'y', NaN), num_modes, 1);
    for k = 1:num_modes
        [phase_factors(k), phase_audit(k)] = choose_mode_phase_factor(EigVecs(:, k), Ny, Nx, state_layout, ...
            'BubbleMask', bubble_mask, 'NearWallMask', near_wall_mask, 'X', X, 'Y', Y);
    end
end

function Config = local_upgrade_config(Config)
%LOCAL_UPGRADE_CONFIG Backfill newer mode-filter fields for older saved cases.

    if ~isfield(Config, 'mode_filter') || ~isstruct(Config.mode_filter)
        Config.mode_filter = struct();
    end
    if ~isfield(Config.mode_filter, 'near_wall_fraction')
        Config.mode_filter.near_wall_fraction = 0.15;
    end
    if ~isfield(Config.mode_filter, 'bubble_fraction_threshold')
        Config.mode_filter.bubble_fraction_threshold = 0.05;
    end
    if ~isfield(Config.mode_filter, 'bubble_core_fraction_threshold')
        Config.mode_filter.bubble_core_fraction_threshold = 0.03;
    end
    if ~isfield(Config.mode_filter, 'bubble_support_fraction_threshold')
        Config.mode_filter.bubble_support_fraction_threshold = 0.05;
    end
    if ~isfield(Config.mode_filter, 'shock_fraction_threshold')
        Config.mode_filter.shock_fraction_threshold = 0.35;
    end
    if ~isfield(Config.mode_filter, 'shock_core_fraction_threshold')
        Config.mode_filter.shock_core_fraction_threshold = 0.15;
    end
    if ~isfield(Config.mode_filter, 'free_stream_fraction_threshold')
        Config.mode_filter.free_stream_fraction_threshold = 0.20;
    end
    if ~isfield(Config.mode_filter, 'residual_threshold')
        Config.mode_filter.residual_threshold = 1.0e-4;
    end
    if ~isfield(Config.mode_filter, 'checker_threshold')
        Config.mode_filter.checker_threshold = 5.0;
    end
    if ~isfield(Config.mode_filter, 'checker_threshold_structural')
        Config.mode_filter.checker_threshold_structural = 20.0;
    end
    if ~isfield(Config.mode_filter, 'pressure_checker_threshold')
        Config.mode_filter.pressure_checker_threshold = 1.5;
    end
    if ~isfield(Config.mode_filter, 'pressure_checker_threshold_structural')
        Config.mode_filter.pressure_checker_threshold_structural = 1.5;
    end
    if ~isfield(Config.mode_filter, 'outlet_fraction')
        Config.mode_filter.outlet_fraction = 0.12;
    end
    if ~isfield(Config.mode_filter, 'outlet_fraction_threshold')
        Config.mode_filter.outlet_fraction_threshold = 0.35;
    end
    if ~isfield(Config.mode_filter, 'outlet_wall_fraction_threshold')
        Config.mode_filter.outlet_wall_fraction_threshold = 0.20;
    end
    if ~isfield(Config.mode_filter, 'pressure_free_stream_fraction_threshold')
        Config.mode_filter.pressure_free_stream_fraction_threshold = 0.35;
    end
    if ~isfield(Config.mode_filter, 'pressure_outlet_fraction_threshold')
        Config.mode_filter.pressure_outlet_fraction_threshold = 0.40;
    end
    if ~isfield(Config.mode_filter, 'pressure_outlet_wall_fraction_threshold')
        Config.mode_filter.pressure_outlet_wall_fraction_threshold = 0.20;
    end
    if ~isfield(Config.mode_filter, 'pressure_shock_core_fraction_threshold')
        Config.mode_filter.pressure_shock_core_fraction_threshold = 0.20;
    end
end
