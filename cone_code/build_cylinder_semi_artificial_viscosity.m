function [Kav, info] = build_cylinder_semi_artificial_viscosity(Nx, Ny, BF, Par, Config, calc_dx, calc_dy)
%BUILD_CYLINDER_SEMI_ARTIFICIAL_VISCOSITY Build a 4th-order SAV matrix.
%   The filter is assembled in computational coordinates and matches the
%   interleaved grid-point storage used by the cylinder scripts:
%   q = [rho', u', v', T'] at each (i,j).

    if nargin < 7
        error('build_cylinder_semi_artificial_viscosity:NotEnoughInputs', ...
            'Expected Nx, Ny, BF, Par, Config, calc_dx, and calc_dy.');
    end

    info = local_normalize_sav_config(Config);
    Ndof = 4 * Nx * Ny;
    Kav = sparse(Ndof, Ndof);

    info.grid_size = [Nx, Ny];
    info.state_layout = 'interleaved4_rho_u_v_T';
    info.active_mask = false(Nx, Ny);
    info.sensor_raw = zeros(Nx, Ny);
    info.sensor_weight = zeros(Nx, Ny);
    info.coefficient = zeros(Nx, Ny);
    info.active_points = 0;
    info.active_rows = 0;
    info.max_coefficient = 0.0;
    info.min_nonzero_coefficient = 0.0;
    info.nnz = 0;

    if ~info.enabled || info.epsilon <= 0
        return;
    end

    if Nx < 5 || Ny < 5
        error('build_cylinder_semi_artificial_viscosity:GridTooSmall', ...
            'Need at least 5 points in each direction for the 4th-order SAV stencil.');
    end

    active_mask = false(Nx, Ny);
    i_lo = 1 + info.radial_guard_cells;
    i_hi = Nx - info.radial_guard_cells;
    if i_lo > i_hi
        error('build_cylinder_semi_artificial_viscosity:GuardTooLarge', ...
            'radial_guard_cells=%d leaves no interior rows for Nx=%d.', ...
            info.radial_guard_cells, Nx);
    end
    active_mask(i_lo:i_hi, :) = true;

    [sensor_raw, sensor_weight] = local_build_sensor_weight( ...
        BF, Par, Nx, Ny, info, calc_dx, calc_dy);
    coeff = info.epsilon * sensor_weight;
    coeff(~active_mask) = 0.0;

    Kxi = local_build_fourth_difference_matrix(Nx, 'nonperiodic');
    Keta = local_build_fourth_difference_matrix(Ny, 'periodic');
    Kscalar_base = kron(speye(Ny), Kxi) + kron(Keta, speye(Nx));
    W = spdiags(coeff(:), 0, Nx * Ny, Nx * Ny);
    Kscalar = W * Kscalar_base;
    Kav = kron(Kscalar, speye(4));

    info.active_mask = active_mask;
    info.sensor_raw = sensor_raw;
    info.sensor_weight = sensor_weight;
    info.coefficient = coeff;
    info.active_points = nnz(coeff > 0);
    info.active_rows = 4 * info.active_points;
    info.max_coefficient = max(coeff(:));
    nonzero_coeff = coeff(coeff > 0);
    if isempty(nonzero_coeff)
        info.min_nonzero_coefficient = 0.0;
    else
        info.min_nonzero_coefficient = min(nonzero_coeff(:));
    end
    info.nnz = nnz(Kav);
end

function info = local_normalize_sav_config(Config)
%LOCAL_NORMALIZE_SAV_CONFIG Apply safe defaults for the cylinder SAV block.

    info = struct();
    info.enabled = false;
    info.mode = 'uniform';
    info.sensor_field = 'pressure';
    info.epsilon = 0.0;
    info.sensor_threshold = 0.02;
    info.sensor_power = 2.0;
    info.radial_guard_cells = 2;

    if ~isfield(Config, 'use_semi_artificial_viscosity')
        return;
    end

    info.enabled = logical(Config.use_semi_artificial_viscosity);
    if ~isfield(Config, 'semi_artificial_viscosity') || ~isstruct(Config.semi_artificial_viscosity)
        return;
    end

    sav = Config.semi_artificial_viscosity;
    if isfield(sav, 'epsilon') && ~isempty(sav.epsilon)
        info.epsilon = sav.epsilon;
    end
    if isfield(sav, 'use_sensor') && logical(sav.use_sensor)
        info.mode = 'sensor';
    end
    if isfield(sav, 'sensor_field') && ~isempty(sav.sensor_field)
        info.sensor_field = lower(char(sav.sensor_field));
    end
    if isfield(sav, 'sensor_threshold') && ~isempty(sav.sensor_threshold)
        info.sensor_threshold = sav.sensor_threshold;
    end
    if isfield(sav, 'sensor_power') && ~isempty(sav.sensor_power)
        info.sensor_power = sav.sensor_power;
    end
    if isfield(sav, 'radial_guard_cells') && ~isempty(sav.radial_guard_cells)
        info.radial_guard_cells = max(2, round(sav.radial_guard_cells));
    end
end

function [sensor_raw, sensor_weight] = local_build_sensor_weight(BF, Par, Nx, Ny, info, calc_dx, calc_dy)
%LOCAL_BUILD_SENSOR_WEIGHT Build either a uniform or gradient-based weight.

    if strcmp(info.mode, 'uniform')
        sensor_raw = ones(Nx, Ny);
        sensor_weight = ones(Nx, Ny);
        return;
    end

    switch info.sensor_field
        case 'pressure'
            proxy = (BF.rho .* BF.T) / (Par.gamma * Par.Ma^2);
        case 'density'
            proxy = BF.rho;
        case 'temperature'
            proxy = BF.T;
        otherwise
            error('build_cylinder_semi_artificial_viscosity:UnsupportedSensorField', ...
                'Unsupported sensor_field "%s".', info.sensor_field);
    end

    grad_x = reshape(calc_dx(proxy(:)), Nx, Ny);
    grad_y = reshape(calc_dy(proxy(:)), Nx, Ny);
    sensor_raw = hypot(grad_x, grad_y);

    max_sensor = max(sensor_raw(:));
    if max_sensor > 0
        sensor_raw = sensor_raw / max_sensor;
    end

    sensor_weight = max(sensor_raw - info.sensor_threshold, 0.0);
    sensor_weight = sensor_weight .^ info.sensor_power;
end

function K = local_build_fourth_difference_matrix(N, type_name)
%LOCAL_BUILD_FOURTH_DIFFERENCE_MATRIX Build the negative 4th-difference row operator.

    if N < 5
        error('build_cylinder_semi_artificial_viscosity:GridTooSmall1D', ...
            'Need at least 5 points for a 4th-difference stencil.');
    end

    K = spalloc(N, N, 5 * N);
    stencil = [-1, 4, -6, 4, -1];

    switch lower(type_name)
        case 'periodic'
            for row = 1:N
                cols = mod((row - 2:row + 2) - 1, N) + 1;
                K(row, cols) = K(row, cols) + stencil;
            end
        case 'nonperiodic'
            for row = 3:N-2
                K(row, row-2:row+2) = stencil;
            end
        otherwise
            error('build_cylinder_semi_artificial_viscosity:UnsupportedType', ...
                'Unknown stencil type "%s".', type_name);
    end
end
