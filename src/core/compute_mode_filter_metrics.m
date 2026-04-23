function metrics = compute_mode_filter_metrics(EigVecs, Ny, Nx, RHO, Cv_nd, varargin)
%COMPUTE_MODE_FILTER_METRICS Compute wall/support/checker diagnostics for candidate modes.

    p = inputParser;
    p.FunctionName = 'compute_mode_filter_metrics';
    addParameter(p, 'StateLayout', 'primitive5_u_v_w_T_p', @(x) ischar(x) || (isstring(x) && isscalar(x)));
    addParameter(p, 'NearWallFraction', 0.15, @(x) isnumeric(x) && isscalar(x) && x > 0 && x <= 1);
    addParameter(p, 'NearWallMask', [], @(x) isempty(x) || islogical(x) || isnumeric(x));
    addParameter(p, 'BubbleMask', [], @(x) isempty(x) || islogical(x) || isnumeric(x));
    addParameter(p, 'BubbleSupportMask', [], @(x) isempty(x) || islogical(x) || isnumeric(x));
    addParameter(p, 'FreeStreamMask', [], @(x) isempty(x) || islogical(x) || isnumeric(x));
    addParameter(p, 'SpongeSigma', [], @(x) isempty(x) || isnumeric(x));
    addParameter(p, 'ShockMask', [], @(x) isempty(x) || islogical(x) || isnumeric(x));
    addParameter(p, 'ShockCoreMask', [], @(x) isempty(x) || islogical(x) || isnumeric(x));
    addParameter(p, 'OutletMask', [], @(x) isempty(x) || islogical(x) || isnumeric(x));
    addParameter(p, 'OutletWallMask', [], @(x) isempty(x) || islogical(x) || isnumeric(x));
    addParameter(p, 'CornerMask', [], @(x) isempty(x) || islogical(x) || isnumeric(x));
    addParameter(p, 'BadPointMask', [], @(x) isempty(x) || islogical(x) || isnumeric(x));
    parse(p, varargin{:});

    num_modes = size(EigVecs, 2);
    layout = get_state_layout_info(p.Results.StateLayout);
    near_wall_rows = min(Ny, max(3, round(Ny * p.Results.NearWallFraction)));

    metrics = struct();
    metrics.wall_energy_frac = zeros(num_modes, 1);
    metrics.near_wall_energy_frac = zeros(num_modes, 1);
    metrics.bubble_overlap = zeros(num_modes, 1);
    metrics.bubble_core_overlap = zeros(num_modes, 1);
    metrics.bubble_support_overlap = zeros(num_modes, 1);
    metrics.free_stream_energy_frac = zeros(num_modes, 1);
    metrics.sponge_energy_frac = zeros(num_modes, 1);
    metrics.shock_energy_frac = zeros(num_modes, 1);
    metrics.shock_core_energy_frac = zeros(num_modes, 1);
    metrics.outlet_energy_frac = zeros(num_modes, 1);
    metrics.outlet_wall_energy_frac = zeros(num_modes, 1);
    metrics.corner_energy_frac = zeros(num_modes, 1);
    metrics.bad_point_energy_frac = zeros(num_modes, 1);
    metrics.checker_ratio = zeros(num_modes, 1);
    metrics.u_checker_ratio = zeros(num_modes, 1);
    metrics.p_checker_ratio = zeros(num_modes, 1);
    metrics.component_checker_ratio_max = zeros(num_modes, 1);
    metrics.p_free_stream_overlap = zeros(num_modes, 1);
    metrics.p_outlet_overlap = zeros(num_modes, 1);
    metrics.p_outlet_wall_overlap = zeros(num_modes, 1);
    metrics.p_shock_core_overlap = zeros(num_modes, 1);
    metrics.p_peak_in_free_stream = false(num_modes, 1);
    metrics.p_peak_in_outlet_wall = false(num_modes, 1);
    metrics.p_peak_in_shock_core = false(num_modes, 1);
    metrics.total_energy = zeros(num_modes, 1);
    metrics.u_peak_in_bubble = false(num_modes, 1);
    metrics.u_peak_in_bubble_support = false(num_modes, 1);
    metrics.u_peak_in_near_wall = false(num_modes, 1);
    metrics.u_peak_in_shock_core = false(num_modes, 1);
    metrics.u_peak_in_outlet = false(num_modes, 1);
    metrics.u_peak_in_outlet_wall = false(num_modes, 1);
    metrics.u_peak_in_corner = false(num_modes, 1);
    metrics.u_peak_in_bad_point = false(num_modes, 1);
    metrics.u_peak_row = nan(num_modes, 1);
    metrics.u_peak_col = nan(num_modes, 1);
    metrics.near_wall_rows = near_wall_rows;
    component_names = {'u', 'v', 'w', 'T', 'p'};
    metrics.component_support = local_init_component_metrics(component_names, num_modes);

    if isempty(p.Results.NearWallMask)
        near_wall_mask = false(Ny, Nx);
        near_wall_mask(1:near_wall_rows, :) = true;
    else
        near_wall_mask = logical(p.Results.NearWallMask);
    end
    if isempty(p.Results.BubbleMask)
        bubble_mask = false(Ny, Nx);
    else
        bubble_mask = logical(p.Results.BubbleMask);
    end
    if isempty(p.Results.BubbleSupportMask)
        bubble_support_mask = bubble_mask;
    else
        bubble_support_mask = logical(p.Results.BubbleSupportMask);
    end
    if isempty(p.Results.FreeStreamMask)
        free_stream_mask = false(Ny, Nx);
        free_stream_start = max(1, round(0.5 * Ny));
        free_stream_mask(free_stream_start:end, :) = true;
    else
        free_stream_mask = logical(p.Results.FreeStreamMask);
    end
    if isempty(p.Results.SpongeSigma)
        sponge_mask = false(Ny, Nx);
    else
        sponge_mask = p.Results.SpongeSigma > 0;
    end
    if isempty(p.Results.ShockMask)
        shock_mask = false(Ny, Nx);
    else
        shock_mask = logical(p.Results.ShockMask);
    end
    if isempty(p.Results.ShockCoreMask)
        shock_core_mask = shock_mask;
    else
        shock_core_mask = logical(p.Results.ShockCoreMask);
    end
    if isempty(p.Results.OutletMask)
        outlet_mask = false(Ny, Nx);
    else
        outlet_mask = logical(p.Results.OutletMask);
    end
    if isempty(p.Results.OutletWallMask)
        outlet_wall_mask = outlet_mask & near_wall_mask;
    else
        outlet_wall_mask = logical(p.Results.OutletWallMask);
    end
    if isempty(p.Results.CornerMask)
        corner_mask = false(Ny, Nx);
    else
        corner_mask = logical(p.Results.CornerMask);
    end
    if isempty(p.Results.BadPointMask)
        bad_point_mask = false(Ny, Nx);
    else
        bad_point_mask = logical(p.Results.BadPointMask);
    end

    for k = 1:num_modes
        q_mode = EigVecs(:, k);
        support_field = compute_mode_support_field(q_mode, Ny, Nx, layout.name, RHO, Cv_nd, ...
            'Weighting', 'u_dominant');
        total_energy = sum(support_field(:));
        if total_energy <= 1.0e-60
            total_energy = 1.0;
        end

        metrics.total_energy(k) = total_energy;
        metrics.wall_energy_frac(k) = sum(support_field(near_wall_mask), 'all') / total_energy;
        metrics.near_wall_energy_frac(k) = metrics.wall_energy_frac(k);
        metrics.bubble_core_overlap(k) = sum(support_field(bubble_mask), 'all') / total_energy;
        metrics.bubble_support_overlap(k) = sum(support_field(bubble_support_mask), 'all') / total_energy;
        metrics.bubble_overlap(k) = metrics.bubble_core_overlap(k);
        metrics.free_stream_energy_frac(k) = sum(support_field(free_stream_mask), 'all') / total_energy;
        metrics.sponge_energy_frac(k) = sum(support_field(sponge_mask)) / total_energy;
        metrics.shock_energy_frac(k) = sum(support_field(shock_mask)) / total_energy;
        metrics.shock_core_energy_frac(k) = sum(support_field(shock_core_mask), 'all') / total_energy;
        metrics.outlet_energy_frac(k) = sum(support_field(outlet_mask), 'all') / total_energy;
        metrics.outlet_wall_energy_frac(k) = sum(support_field(outlet_wall_mask), 'all') / total_energy;
        metrics.corner_energy_frac(k) = sum(support_field(corner_mask), 'all') / total_energy;
        metrics.bad_point_energy_frac(k) = sum(support_field(bad_point_mask), 'all') / total_energy;

        if isnan(layout.components.u)
            u_amp = sqrt(support_field);
        else
            u_amp = abs(extract_state_component(q_mode, Ny, Nx, layout.name, 'u'));
        end
        [~, peak_idx] = max(u_amp(:));
        if ~isempty(peak_idx) && isfinite(peak_idx)
            [peak_row, peak_col] = ind2sub([Ny, Nx], peak_idx);
            metrics.u_peak_row(k) = peak_row;
            metrics.u_peak_col(k) = peak_col;
            metrics.u_peak_in_bubble(k) = bubble_mask(peak_row, peak_col);
            metrics.u_peak_in_bubble_support(k) = bubble_support_mask(peak_row, peak_col);
            metrics.u_peak_in_near_wall(k) = near_wall_mask(peak_row, peak_col);
            metrics.u_peak_in_shock_core(k) = shock_core_mask(peak_row, peak_col);
            metrics.u_peak_in_outlet(k) = outlet_mask(peak_row, peak_col);
            metrics.u_peak_in_outlet_wall(k) = outlet_wall_mask(peak_row, peak_col);
            metrics.u_peak_in_corner(k) = corner_mask(peak_row, peak_col);
            metrics.u_peak_in_bad_point(k) = bad_point_mask(peak_row, peak_col);
        end
        metrics.u_checker_ratio(k) = local_checker_ratio(u_amp);
        metrics.checker_ratio(k) = metrics.u_checker_ratio(k);

        for c = 1:numel(component_names)
            comp_name = component_names{c};
            comp_field = extract_state_component(q_mode, Ny, Nx, layout.name, comp_name);
            comp_support = local_component_support(comp_name, comp_field, RHO, Cv_nd);
            comp_total = sum(comp_support(:));
            if comp_total <= 1.0e-60
                comp_total = 1.0;
            end

            comp_amp = abs(comp_field);
            comp_checker = local_checker_ratio(comp_amp);
            metrics.component_support.(comp_name).total_support(k) = comp_total;
            metrics.component_support.(comp_name).checker_ratio(k) = comp_checker;
            metrics.component_checker_ratio_max(k) = max(metrics.component_checker_ratio_max(k), comp_checker);
            metrics.component_support.(comp_name).bubble_core_overlap(k) = sum(comp_support(bubble_mask), 'all') / comp_total;
            metrics.component_support.(comp_name).bubble_support_overlap(k) = sum(comp_support(bubble_support_mask), 'all') / comp_total;
            metrics.component_support.(comp_name).shock_overlap(k) = sum(comp_support(shock_mask), 'all') / comp_total;
            metrics.component_support.(comp_name).shock_core_overlap(k) = sum(comp_support(shock_core_mask), 'all') / comp_total;
            metrics.component_support.(comp_name).outlet_overlap(k) = sum(comp_support(outlet_mask), 'all') / comp_total;
            metrics.component_support.(comp_name).outlet_wall_overlap(k) = sum(comp_support(outlet_wall_mask), 'all') / comp_total;
            metrics.component_support.(comp_name).free_stream_overlap(k) = sum(comp_support(free_stream_mask), 'all') / comp_total;
            metrics.component_support.(comp_name).near_wall_overlap(k) = sum(comp_support(near_wall_mask), 'all') / comp_total;

            [peak_value, peak_idx] = max(comp_amp(:));
            if ~isempty(peak_idx) && isfinite(peak_idx) && peak_value > 0
                [peak_row, peak_col] = ind2sub([Ny, Nx], peak_idx);
                metrics.component_support.(comp_name).peak_row(k) = peak_row;
                metrics.component_support.(comp_name).peak_col(k) = peak_col;
                metrics.component_support.(comp_name).peak_in_bubble(k) = bubble_mask(peak_row, peak_col);
                metrics.component_support.(comp_name).peak_in_bubble_support(k) = bubble_support_mask(peak_row, peak_col);
                metrics.component_support.(comp_name).peak_in_shock_core(k) = shock_core_mask(peak_row, peak_col);
                metrics.component_support.(comp_name).peak_in_outlet_wall(k) = outlet_wall_mask(peak_row, peak_col);
                metrics.component_support.(comp_name).peak_in_free_stream(k) = free_stream_mask(peak_row, peak_col);
            end

            if strcmp(comp_name, 'p')
                metrics.p_checker_ratio(k) = metrics.component_support.p.checker_ratio(k);
                metrics.p_free_stream_overlap(k) = metrics.component_support.p.free_stream_overlap(k);
                metrics.p_outlet_overlap(k) = metrics.component_support.p.outlet_overlap(k);
                metrics.p_outlet_wall_overlap(k) = metrics.component_support.p.outlet_wall_overlap(k);
                metrics.p_shock_core_overlap(k) = metrics.component_support.p.shock_core_overlap(k);
                metrics.p_peak_in_free_stream(k) = metrics.component_support.p.peak_in_free_stream(k);
                metrics.p_peak_in_outlet_wall(k) = metrics.component_support.p.peak_in_outlet_wall(k);
                metrics.p_peak_in_shock_core(k) = metrics.component_support.p.peak_in_shock_core(k);
            end
        end
        metrics.checker_ratio(k) = max(metrics.u_checker_ratio(k), metrics.component_checker_ratio_max(k));
    end
end

function component_metrics = local_init_component_metrics(component_names, num_modes)
%LOCAL_INIT_COMPONENT_METRICS Initialize one nested component-audit payload.

    component_metrics = struct();
    for k = 1:numel(component_names)
        name = component_names{k};
        component_metrics.(name) = struct( ...
            'total_support', zeros(num_modes, 1), ...
            'checker_ratio', zeros(num_modes, 1), ...
            'bubble_core_overlap', zeros(num_modes, 1), ...
            'bubble_support_overlap', zeros(num_modes, 1), ...
            'shock_overlap', zeros(num_modes, 1), ...
            'shock_core_overlap', zeros(num_modes, 1), ...
            'outlet_overlap', zeros(num_modes, 1), ...
            'outlet_wall_overlap', zeros(num_modes, 1), ...
            'free_stream_overlap', zeros(num_modes, 1), ...
            'near_wall_overlap', zeros(num_modes, 1), ...
            'peak_row', nan(num_modes, 1), ...
            'peak_col', nan(num_modes, 1), ...
            'peak_in_bubble', false(num_modes, 1), ...
            'peak_in_bubble_support', false(num_modes, 1), ...
            'peak_in_shock_core', false(num_modes, 1), ...
            'peak_in_outlet_wall', false(num_modes, 1), ...
            'peak_in_free_stream', false(num_modes, 1));
    end
end

function comp_support = local_component_support(component_name, component_field, RHO, Cv_nd)
%LOCAL_COMPONENT_SUPPORT Build one component-specific support field.

    if all(isnan(component_field(:)))
        comp_support = zeros(size(RHO));
        return;
    end

    switch component_name
        case {'u', 'v', 'w'}
            weight = RHO;
        case 'T'
            weight = RHO * Cv_nd;
        otherwise
            weight = ones(size(RHO));
    end
    comp_support = weight .* abs(component_field).^2;
end

function ratio = local_checker_ratio(component_amp)
%LOCAL_CHECKER_RATIO Estimate grid-scale oscillation energy for one component.

    amp = abs(component_amp);
    amp(~isfinite(amp)) = 0.0;
    if isempty(amp)
        ratio = 0.0;
        return;
    end

    diff_x = diff(amp, 1, 2);
    diff_y = diff(amp, 1, 1);
    denom = sum(amp(:).^2) + 1.0e-60;
    ratio = (sum(diff_x(:).^2) + sum(diff_y(:).^2)) / max(2.0 * denom, eps);
end
