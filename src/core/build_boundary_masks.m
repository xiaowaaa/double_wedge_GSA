function [mask, info] = build_boundary_masks(X, Y, config, varargin)
%BUILD_BOUNDARY_MASKS Build explicit edge masks with deterministic corners.

    p = inputParser;
    p.FunctionName = 'build_boundary_masks';
    addParameter(p, 'Verbose', true, @(x) islogical(x) && isscalar(x));
    parse(p, varargin{:});

    if ~isfield(config, 'boundary_map')
        error('build_boundary_masks:BoundaryMap', ...
            'config.boundary_map is required.');
    end
    if ~isfield(config, 'x_hinge')
        error('build_boundary_masks:XHinge', 'config.x_hinge is required.');
    end

    [Ny, Nx] = size(X);

    mask = struct();
    mask.inlet = false(Ny, Nx);
    mask.outlet = false(Ny, Nx);
    mask.farfield = false(Ny, Nx);
    mask.wall = false(Ny, Nx);
    mask.symmetry = false(Ny, Nx);

    mask.bottom = false(Ny, Nx);
    mask.top = false(Ny, Nx);
    mask.left = false(Ny, Nx);
    mask.right = false(Ny, Nx);

    % South edge owns both bottom corners.
    for i = 1:Nx
        if strcmp(config.boundary_map.south, 'mixed_symmetry_wall')
            if X(1, i) < config.x_hinge
                mask.symmetry(1, i) = true;
            else
                mask.wall(1, i) = true;
            end
        else
            mask = local_assign_edge_label(mask, 1, i, config.boundary_map.south);
        end
    end
    mask.bottom(1, :) = true;

    % West/east own the top corners.
    for j = 2:Ny
        mask = local_assign_edge_label(mask, j, 1, config.boundary_map.west);
        mask.left(j, 1) = true;
        mask = local_assign_edge_label(mask, j, Nx, config.boundary_map.east);
        mask.right(j, Nx) = true;
    end

    % North excludes corners because west/east already own them.
    for i = 2:Nx-1
        mask = local_assign_edge_label(mask, Ny, i, config.boundary_map.north);
        mask.top(Ny, i) = true;
    end

    mask.top(Ny, 1) = true;
    mask.top(Ny, Nx) = true;
    mask.outer = mask.inlet | mask.outlet | mask.farfield | mask.wall | mask.symmetry;

    info = struct();
    info.counts = struct( ...
        'inlet', nnz(mask.inlet), ...
        'outlet', nnz(mask.outlet), ...
        'farfield', nnz(mask.farfield), ...
        'wall', nnz(mask.wall), ...
        'symmetry', nnz(mask.symmetry));
    info.top_type = char(string(config.boundary_map.north));

    if p.Results.Verbose
        fprintf('[build_boundary_masks] inlet=%d outlet=%d farfield=%d wall=%d symmetry=%d\n', ...
            info.counts.inlet, info.counts.outlet, info.counts.farfield, ...
            info.counts.wall, info.counts.symmetry);
    end
end

function mask = local_assign_edge_label(mask, j, i, label)
%LOCAL_ASSIGN_EDGE_LABEL Set exactly one physical label on one edge node.

    label = char(string(label));
    switch label
        case 'inlet'
            mask.inlet(j, i) = true;
        case 'outlet'
            mask.outlet(j, i) = true;
        case 'farfield'
            mask.farfield(j, i) = true;
        case 'wall'
            mask.wall(j, i) = true;
        case 'symmetry'
            mask.symmetry(j, i) = true;
        case 'none'
            % Leave unlabeled.
        otherwise
            error('build_boundary_masks:Label', ...
                'Unsupported boundary label "%s".', label);
    end
end
