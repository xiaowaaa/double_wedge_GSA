function masks = build_paperA_mode_masks(data, Config, Ny, Nx)
%BUILD_PAPERA_MODE_MASKS Resolve the shared bubble/shock/support masks.

    narginchk(4, 4);

    if isfield(data, 'BaseflowMasks') && isstruct(data.BaseflowMasks) && ...
            isfield(data.BaseflowMasks, 'bubble_core_mask')
        masks.bubble_core = logical(data.BaseflowMasks.bubble_core_mask);
    elseif isfield(data, 'BaseflowMasks') && isstruct(data.BaseflowMasks) && ...
            isfield(data.BaseflowMasks, 'bubble_mask')
        masks.bubble_core = logical(data.BaseflowMasks.bubble_mask);
    else
        masks.bubble_core = data.U < 0;
    end
    masks.bubble = masks.bubble_core;
    if isfield(data, 'BaseflowMasks') && isstruct(data.BaseflowMasks) && ...
            isfield(data.BaseflowMasks, 'bubble_support_mask')
        masks.bubble_support = logical(data.BaseflowMasks.bubble_support_mask);
    else
        masks.bubble_support = masks.bubble_core;
    end

    if isfield(data, 'BaseflowMasks') && isstruct(data.BaseflowMasks) && ...
            isfield(data.BaseflowMasks, 'near_wall_mask')
        masks.near_wall = logical(data.BaseflowMasks.near_wall_mask);
    else
        near_wall_rows = min(Ny, max(3, round(Ny * Config.mode_filter.near_wall_fraction)));
        masks.near_wall = false(Ny, Nx);
        masks.near_wall(1:near_wall_rows, :) = true;
    end

    if isfield(data, 'ShockInfo') && isstruct(data.ShockInfo) && isfield(data.ShockInfo, 'shock_mask')
        masks.shock = logical(data.ShockInfo.shock_mask);
    elseif isfield(data, 'BaseflowMasks') && isstruct(data.BaseflowMasks) && ...
            isfield(data.BaseflowMasks, 'shock_outer_mask')
        masks.shock = logical(data.BaseflowMasks.shock_outer_mask);
    elseif isfield(data, 'BaseflowMasks') && isstruct(data.BaseflowMasks) && ...
            isfield(data.BaseflowMasks, 'shock_core_mask')
        masks.shock = logical(data.BaseflowMasks.shock_core_mask) & ~masks.near_wall & ~masks.bubble;
    elseif isfield(data, 'BaseflowMasks') && isstruct(data.BaseflowMasks) && ...
            isfield(data.BaseflowMasks, 'shock_mask')
        masks.shock = logical(data.BaseflowMasks.shock_mask);
    elseif isfield(data, 'ShockInfo') && isstruct(data.ShockInfo) && isfield(data.ShockInfo, 'shock_mask')
        masks.shock = logical(data.ShockInfo.shock_mask);
    else
        masks.shock = false(Ny, Nx);
    end
    if isfield(data, 'ShockInfo') && isstruct(data.ShockInfo) && isfield(data.ShockInfo, 'shock_raw')
        masks.shock_core = logical(data.ShockInfo.shock_raw);
    elseif isfield(data, 'BaseflowMasks') && isstruct(data.BaseflowMasks) && ...
            isfield(data.BaseflowMasks, 'shock_core_mask')
        masks.shock_core = logical(data.BaseflowMasks.shock_core_mask);
    else
        masks.shock_core = masks.shock;
    end
    % Keep the shock-core audit consistent with the protected shock band that Part3 actually uses.
    masks.shock_core = masks.shock_core & masks.shock;

    if isfield(data, 'BaseflowMasks') && isstruct(data.BaseflowMasks) && ...
            isfield(data.BaseflowMasks, 'outlet_mask')
        masks.outlet = logical(data.BaseflowMasks.outlet_mask);
    else
        outlet_fraction = 0.12;
        if isfield(Config, 'mode_filter') && isfield(Config.mode_filter, 'outlet_fraction')
            outlet_fraction = Config.mode_filter.outlet_fraction;
        end
        if isfield(data, 'X') && ~isempty(data.X)
            x_min = min(data.X(:));
            x_max = max(data.X(:));
            masks.outlet = data.X >= (x_max - outlet_fraction * max(x_max - x_min, eps));
        else
            outlet_cols = max(1, round(outlet_fraction * Nx));
            masks.outlet = false(Ny, Nx);
            masks.outlet(:, max(1, Nx - outlet_cols + 1):Nx) = true;
        end
    end
    if isfield(data, 'BaseflowMasks') && isstruct(data.BaseflowMasks) && ...
            isfield(data.BaseflowMasks, 'outlet_wall_mask')
        masks.outlet_wall = logical(data.BaseflowMasks.outlet_wall_mask);
    else
        masks.outlet_wall = masks.outlet & masks.near_wall;
    end

    if isfield(data, 'BaseflowMasks') && isstruct(data.BaseflowMasks) && ...
            isfield(data.BaseflowMasks, 'corner_mask')
        masks.corner = logical(data.BaseflowMasks.corner_mask);
    else
        masks.corner = false(Ny, Nx);
    end

    if isfield(data, 'BaseflowMasks') && isstruct(data.BaseflowMasks) && ...
            isfield(data.BaseflowMasks, 'eos_bad_point_mask')
        masks.bad_point = logical(data.BaseflowMasks.eos_bad_point_mask);
    else
        masks.bad_point = false(Ny, Nx);
    end

    eta = local_wall_relative_eta(data.Y);
    masks.free_stream = eta >= 0.50;
end

function eta = local_wall_relative_eta(Y)
%LOCAL_WALL_RELATIVE_ETA Normalize wall distance column by column.

    [Ny, Nx] = size(Y);
    eta = zeros(Ny, Nx);
    wall_y = Y(1, :);
    top_y = Y(end, :);
    height = max(top_y - wall_y, eps);
    for i = 1:Nx
        eta(:, i) = (Y(:, i) - wall_y(i)) / height(i);
    end
end
