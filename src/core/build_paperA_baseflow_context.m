function [BaseflowPhysicsAudit, GeometryAudit, BaseflowMasks] = ...
        build_paperA_baseflow_context(X, Y, U, V, RHO, dX, BoundaryMasks, Config, BaseValidation)
%BUILD_PAPERA_BASEFLOW_CONTEXT Build the shared Paper-A audit and plotting context.

    narginchk(8, 9);
    if nargin < 9 || isempty(BaseValidation)
        BaseValidation = struct();
    end

    [Ny, Nx] = size(X);
    x_min = min(X(:));
    x_max = max(X(:));
    Lx = max(x_max - x_min, eps);

    bubble_mask = U < 0;
    shock_percentile = local_get_nested(Config, {'semi_artificial_viscosity', 'shock_percentile'}, 85.0);
    near_wall_fraction = local_get_nested(Config, {'mode_filter', 'near_wall_fraction'}, 0.15);
    outlet_fraction = local_get_nested(Config, {'mode_filter', 'outlet_fraction'}, 0.12);
    free_stream_eta_threshold = local_get_nested(Config, {'mode_filter', 'free_stream_eta_threshold'}, 0.50);
    near_wall_rows = min(Ny, max(3, round(Ny * near_wall_fraction)));
    near_wall_mask = false(Ny, Nx);
    near_wall_mask(1:near_wall_rows, :) = true;
    outlet_mask = X >= (x_max - outlet_fraction * Lx);
    outlet_wall_mask = outlet_mask & near_wall_mask;
    free_stream_mask = local_build_free_stream_mask(Y, free_stream_eta_threshold);

    grad_rho = hypot(dX.rhox, dX.rhoy);
    shock_threshold = local_percentile(grad_rho(:), shock_percentile);
    shock_mask = grad_rho > shock_threshold;

    bubble_extent = local_mask_extent(X, Y, bubble_mask);
    shock_extent = local_mask_extent(X, Y, shock_mask);
    [bubble_window, streamline_window, streamline_seeds] = ...
        local_build_windows(X, Y, bubble_mask, near_wall_rows);
    bubble_support_mask = local_build_bubble_support_mask(X, Y, bubble_mask);
    bubble_support_extent = local_mask_extent(X, Y, bubble_support_mask);
    shock_core_mask = shock_mask;
    shock_outer_mask = shock_core_mask & ~near_wall_mask;
    [corner_mask, corner_anchor] = local_build_corner_mask(X, Y, Config);
    bubble_metrics = local_compute_bubble_metrics(X, Y, U, bubble_mask);

    divergence_proxy = dX.div;
    mass_continuity = U .* dX.rhox + V .* dX.rhoy + RHO .* divergence_proxy;
    mass_scale = abs(U) .* abs(dX.rhox) + abs(V) .* abs(dX.rhoy) + ...
        abs(RHO) .* (abs(dX.ux) + abs(dX.vy));
    mass_scale = max(mass_scale, eps);
    mass_continuity_rel = abs(mass_continuity) ./ mass_scale;

    BaseflowPhysicsAudit = struct();
    BaseflowPhysicsAudit.eos_relative_error = local_get_field(BaseValidation, 'eos_relative_error', NaN);
    BaseflowPhysicsAudit.divergence_proxy_label = 'ux + vy';
    BaseflowPhysicsAudit.divergence_proxy_max = max(abs(divergence_proxy(:)));
    BaseflowPhysicsAudit.divergence_proxy_stats = local_stats(abs(divergence_proxy));
    BaseflowPhysicsAudit.mass_continuity_label = 'u*rhox + v*rhoy + rho*(ux + vy)';
    BaseflowPhysicsAudit.mass_continuity_residual_max = max(abs(mass_continuity(:)));
    BaseflowPhysicsAudit.mass_continuity_residual_stats = local_stats(abs(mass_continuity));
    BaseflowPhysicsAudit.mass_continuity_relative_label = ...
        '|u*rhox + v*rhoy + rho*(ux + vy)| / (|u*rhox| + |v*rhoy| + |rho*ux| + |rho*vy|)';
    BaseflowPhysicsAudit.mass_continuity_relative_max = max(mass_continuity_rel(:));
    BaseflowPhysicsAudit.mass_continuity_relative_stats = local_stats(mass_continuity_rel);
    BaseflowPhysicsAudit.continuity_residual_metric = 'mass_continuity_relative_max';
    BaseflowPhysicsAudit.continuity_residual_max = BaseflowPhysicsAudit.mass_continuity_relative_max;
    BaseflowPhysicsAudit.wall_temperature_relative_mismatch = ...
        local_get_field(BaseValidation, 'wall_temperature_relative_mismatch', NaN);
    BaseflowPhysicsAudit.bottom_split_ok = local_get_field(BaseValidation, 'bottom_split_ok', true);
    BaseflowPhysicsAudit.bubble_exists = any(bubble_mask(:));
    BaseflowPhysicsAudit.separation_x = bubble_metrics.separation_x;
    BaseflowPhysicsAudit.reattachment_x = bubble_metrics.reattachment_x;
    BaseflowPhysicsAudit.bubble_length = bubble_metrics.bubble_length;
    BaseflowPhysicsAudit.delta99_at_separation = bubble_metrics.delta99_at_separation;
    BaseflowPhysicsAudit.separation_col = bubble_metrics.separation_col;
    BaseflowPhysicsAudit.reattachment_col = bubble_metrics.reattachment_col;
    BaseflowPhysicsAudit.bubble_extent = bubble_extent;
    BaseflowPhysicsAudit.bubble_support_extent = bubble_support_extent;
    BaseflowPhysicsAudit.shock_extent = shock_extent;
    BaseflowPhysicsAudit.shock_outer_extent = local_mask_extent(X, Y, shock_outer_mask);
    BaseflowPhysicsAudit.outlet_extent = local_mask_extent(X, Y, outlet_mask);
    BaseflowPhysicsAudit.outlet_wall_extent = local_mask_extent(X, Y, outlet_wall_mask);
    BaseflowPhysicsAudit.corner_extent = local_mask_extent(X, Y, corner_mask);
    BaseflowPhysicsAudit.shock_threshold = shock_threshold;
    BaseflowPhysicsAudit.structural_only_warning = false;

    GeometryAudit = struct();
    GeometryAudit.boundary_contract = struct( ...
        'top', char(string(Config.boundary_map.north)), ...
        'south', char(string(Config.boundary_map.south)), ...
        'west', char(string(Config.boundary_map.west)), ...
        'east', char(string(Config.boundary_map.east)));
    GeometryAudit.bubble_window = bubble_window;
    GeometryAudit.bubble_support_window = bubble_support_extent;
    GeometryAudit.streamline_window = streamline_window;
    GeometryAudit.streamline_seed_set = streamline_seeds;
    GeometryAudit.x_hinge = Config.x_hinge;
    GeometryAudit.bubble_exists = BaseflowPhysicsAudit.bubble_exists;
    GeometryAudit.bubble_metrics = bubble_metrics;
    GeometryAudit.corner_anchor = corner_anchor;
    GeometryAudit.target_benchmark = local_get_field(Config, 'target_benchmark', '');
    GeometryAudit.benchmark_profile = local_get_field(Config, 'benchmark_profile', '');
    GeometryAudit.plot_contract = local_get_field(Config, 'plot_contract', '');

    BaseflowMasks = struct();
    BaseflowMasks.bubble_mask = bubble_mask;
    BaseflowMasks.bubble_core_mask = bubble_mask;
    BaseflowMasks.bubble_support_mask = bubble_support_mask;
    BaseflowMasks.shock_mask = shock_outer_mask;
    BaseflowMasks.shock_core_mask = shock_core_mask;
    BaseflowMasks.shock_outer_mask = shock_outer_mask;
    BaseflowMasks.near_wall_mask = near_wall_mask;
    BaseflowMasks.outlet_mask = outlet_mask;
    BaseflowMasks.outlet_wall_mask = outlet_wall_mask;
    BaseflowMasks.corner_mask = corner_mask;
    BaseflowMasks.free_stream_mask = free_stream_mask;
    BaseflowMasks.free_stream_eta_threshold = free_stream_eta_threshold;
    BaseflowMasks.boundary_masks = BoundaryMasks;
end

function [bubble_window, streamline_window, seeds] = local_build_windows(X, Y, bubble_mask, near_wall_rows)
%LOCAL_BUILD_WINDOWS Build plotting windows and streamline seed locations.

    x_all = X(:);
    y_all = Y(:);
    x_min = min(x_all);
    x_max = max(x_all);
    y_min = min(y_all);
    y_max = max(y_all);
    Lx = max(x_max - x_min, eps);
    Ly = max(y_max - y_min, eps);

    if any(bubble_mask(:))
        bubble_window = local_mask_extent(X, Y, bubble_mask);
        bubble_window = [ ...
            max(x_min, bubble_window(1) - 0.10 * Lx), ...
            min(x_max, bubble_window(2) + 0.30 * Lx), ...
            max(y_min, bubble_window(3) - 0.02 * Ly), ...
            min(y_max, bubble_window(4) + 0.18 * Ly)];
    else
        wall_y = Y(1, :);
        bubble_window = [ ...
            max(x_min, min(X(1, :)) + 0.15 * Lx), ...
            min(x_max, min(X(1, :)) + 0.70 * Lx), ...
            min(wall_y), ...
            min(y_max, max(wall_y) + 0.35 * Ly)];
    end

    streamline_window = bubble_window;
    y_seed_min = streamline_window(3);
    y_seed_max = streamline_window(4);
    x_seed = streamline_window(1) + 0.02 * max(streamline_window(2) - streamline_window(1), eps);
    y_seeds = linspace(y_seed_min, y_seed_max, max(8, near_wall_rows)).';
    seeds = struct('x', x_seed * ones(size(y_seeds)), 'y', y_seeds);
end

function extent = local_mask_extent(X, Y, mask)
%LOCAL_MASK_EXTENT Return [xmin xmax ymin ymax] for one logical mask.

    if ~any(mask(:))
        extent = [NaN, NaN, NaN, NaN];
        return;
    end

    x_vals = X(mask);
    y_vals = Y(mask);
    extent = [min(x_vals), max(x_vals), min(y_vals), max(y_vals)];
end

function support_mask = local_build_bubble_support_mask(X, Y, bubble_mask)
%LOCAL_BUILD_BUBBLE_SUPPORT_MASK Build a narrow bubble/shear-layer support region.

    [Ny, Nx] = size(X);
    support_mask = false(Ny, Nx);
    if any(bubble_mask(:))
        bubble_extent = local_mask_extent(X, Y, bubble_mask);
        bubble_len = max(bubble_extent(2) - bubble_extent(1), eps);
        bubble_h = max(bubble_extent(4) - bubble_extent(3), eps);
        Ly = max(Y(:)) - min(Y(:));
        x_min = bubble_extent(1) - 0.02 * bubble_len;
        x_max = bubble_extent(2) + 0.25 * bubble_len;
        y_cap_global = bubble_extent(4) + max(0.35 * bubble_h, 0.02 * Ly);
        wall_y = Y(1, :);
        for ii = 1:Nx
            col_mask = X(:, ii) >= x_min & X(:, ii) <= x_max & ...
                Y(:, ii) >= wall_y(ii) & Y(:, ii) <= y_cap_global;
            support_mask(:, ii) = col_mask;
        end
        support_mask = support_mask | bubble_mask;
    else
        support_mask = bubble_mask;
    end
end

function [corner_mask, anchor] = local_build_corner_mask(X, Y, Config)
%LOCAL_BUILD_CORNER_MASK Build a compact geometric neighborhood around the wall hinge.

    [Ny, Nx] = size(X);
    corner_mask = false(Ny, Nx);
    anchor = struct('x', NaN, 'y', NaN, 'col', NaN, 'radius', NaN);

    if ~isfield(Config, 'x_hinge') || ~isfinite(Config.x_hinge)
        return;
    end

    wall_x = X(1, :);
    wall_y = Y(1, :);
    [~, i_hinge] = min(abs(wall_x - Config.x_hinge));
    x_anchor = wall_x(i_hinge);
    y_anchor = wall_y(i_hinge);

    if Nx > 1
        wall_step = median(hypot(diff(wall_x), diff(wall_y)));
    else
        wall_step = 0.0;
    end
    if Ny > 1
        column_step = median(hypot(diff(X(:, i_hinge)), diff(Y(:, i_hinge))));
    else
        column_step = 0.0;
    end
    diag_len = hypot(max(X(:)) - min(X(:)), max(Y(:)) - min(Y(:)));
    radius = max([4.0 * wall_step, 4.0 * column_step, 0.03 * diag_len, eps]);

    corner_mask = hypot(X - x_anchor, Y - y_anchor) <= radius;
    anchor = struct('x', x_anchor, 'y', y_anchor, 'col', i_hinge, 'radius', radius);
end

function free_stream_mask = local_build_free_stream_mask(Y, eta_threshold)
%LOCAL_BUILD_FREE_STREAM_MASK Build one configurable wall-relative upper mask.

    [Ny, Nx] = size(Y);
    free_stream_mask = false(Ny, Nx);
    wall_y = Y(1, :);
    top_y = Y(end, :);
    height = max(top_y - wall_y, eps);
    for i = 1:Nx
        eta = (Y(:, i) - wall_y(i)) / height(i);
        free_stream_mask(:, i) = eta >= eta_threshold;
    end
end

function bubble_metrics = local_compute_bubble_metrics(X, Y, U, bubble_mask)
%LOCAL_COMPUTE_BUBBLE_METRICS Build simple bubble-location diagnostics for reporting.

    bubble_metrics = struct( ...
        'exists', any(bubble_mask(:)), ...
        'separation_x', NaN, ...
        'reattachment_x', NaN, ...
        'bubble_length', NaN, ...
        'delta99_at_separation', NaN, ...
        'separation_col', NaN, ...
        'reattachment_col', NaN);
    if ~bubble_metrics.exists
        return;
    end

    bubble_cols = any(bubble_mask, 1);
    i_sep = find(bubble_cols, 1, 'first');
    i_reattach = find(bubble_cols, 1, 'last');
    if isempty(i_sep) || isempty(i_reattach)
        return;
    end

    bubble_metrics.separation_col = i_sep;
    bubble_metrics.reattachment_col = i_reattach;
    bubble_metrics.separation_x = X(1, i_sep);
    bubble_metrics.reattachment_x = X(1, i_reattach);
    bubble_metrics.bubble_length = max(bubble_metrics.reattachment_x - bubble_metrics.separation_x, 0.0);
    bubble_metrics.delta99_at_separation = local_delta99_at_column(U(:, i_sep), Y(:, i_sep));
end

function delta99 = local_delta99_at_column(u_col, y_col)
%LOCAL_DELTA99_AT_COLUMN Approximate delta_99 from one wall-normal profile.

    delta99 = NaN;
    if isempty(u_col) || isempty(y_col)
        return;
    end

    wall_y = y_col(1);
    edge_u = max(u_col);
    if ~(isfinite(edge_u) && edge_u > 0)
        return;
    end
    target_u = 0.99 * edge_u;
    idx = find(u_col >= target_u, 1, 'first');
    if isempty(idx)
        return;
    end
    if idx <= 1
        delta99 = max(y_col(idx) - wall_y, 0.0);
        return;
    end

    u0 = u_col(idx - 1);
    u1 = u_col(idx);
    y0 = y_col(idx - 1);
    y1 = y_col(idx);
    if abs(u1 - u0) <= eps
        y_star = y1;
    else
        alpha = (target_u - u0) / (u1 - u0);
        alpha = min(max(alpha, 0.0), 1.0);
        y_star = y0 + alpha * (y1 - y0);
    end
    delta99 = max(y_star - wall_y, 0.0);
end

function value = local_get_field(S, field_name, default_value)
%LOCAL_GET_FIELD Return a struct field when present, otherwise a default.

    if isstruct(S) && isfield(S, field_name)
        value = S.(field_name);
    else
        value = default_value;
    end
end

function value = local_get_nested(S, name_chain, default_value)
%LOCAL_GET_NESTED Follow one nested field chain or return a default.

    value = S;
    for k = 1:numel(name_chain)
        name = name_chain{k};
        if ~isstruct(value) || ~isfield(value, name)
            value = default_value;
            return;
        end
        value = value.(name);
    end
end

function value = local_percentile(data_value, pct)
%LOCAL_PERCENTILE Toolbox-free percentile helper.

    data_value = sort(data_value(:));
    if isempty(data_value)
        value = 0.0;
        return;
    end

    pct = min(max(pct, 0.0), 100.0);
    idx = 1 + (numel(data_value) - 1) * pct / 100.0;
    i_lo = floor(idx);
    i_hi = ceil(idx);
    if i_lo == i_hi
        value = data_value(i_lo);
    else
        w_hi = idx - i_lo;
        w_lo = 1.0 - w_hi;
        value = w_lo * data_value(i_lo) + w_hi * data_value(i_hi);
    end
end

function stats = local_stats(data_value)
%LOCAL_STATS Basic finite-value summary statistics.

    data_value = data_value(:);
    data_value = data_value(isfinite(data_value));
    if isempty(data_value)
        stats = struct('min', NaN, 'max', NaN, 'mean', NaN, 'median', NaN, ...
            'p05', NaN, 'p95', NaN);
        return;
    end

    stats = struct();
    stats.min = min(data_value);
    stats.max = max(data_value);
    stats.mean = mean(data_value);
    stats.median = median(data_value);
    stats.p05 = local_percentile(data_value, 5.0);
    stats.p95 = local_percentile(data_value, 95.0);
end
