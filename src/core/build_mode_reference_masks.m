function masks = build_mode_reference_masks(X, Y, U, varargin)
%BUILD_MODE_REFERENCE_MASKS Construct bubble/upper-layer reference regions.

    p = inputParser;
    p.FunctionName = 'build_mode_reference_masks';
    addParameter(p, 'BoundaryMasks', struct(), @isstruct);
    parse(p, varargin{:});

    masks = struct();
    if isempty(U)
        masks.bubble = false(size(X));
    else
        masks.bubble = U < 0;
    end

    eta = local_wall_relative_eta(Y);
    masks.upper_layer = eta >= 0.65;
    masks.lower_layer = eta <= 0.35;

    if isfield(p.Results.BoundaryMasks, 'farfield')
        masks.farfield = p.Results.BoundaryMasks.farfield;
    else
        masks.farfield = false(size(X));
        masks.farfield(end, :) = true;
    end

    if isfield(p.Results.BoundaryMasks, 'wall')
        masks.wall = p.Results.BoundaryMasks.wall;
    else
        masks.wall = false(size(X));
        masks.wall(1, :) = true;
    end
end

function eta = local_wall_relative_eta(Y)
%LOCAL_WALL_RELATIVE_ETA Normalize distance from the south edge column by column.

    [Ny, Nx] = size(Y);
    eta = zeros(Ny, Nx);
    wall_y = Y(1, :);
    top_y = Y(end, :);
    height = max(top_y - wall_y, eps);
    for i = 1:Nx
        eta(:, i) = (Y(:, i) - wall_y(i)) / height(i);
    end
end
