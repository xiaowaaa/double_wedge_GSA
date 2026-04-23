function scan = compute_descriptor_resolvent_scan(LNS_L, LNS_Gam, data, Config, sigma_list)
%COMPUTE_DESCRIPTOR_RESOLVENT_SCAN Compute a leading resolvent-gain scan on one descriptor pencil.

    sigma_list = sigma_list(:).';
    if isempty(sigma_list)
        sigma_list = 0.00 + 0.020i;
    end

    [A_scaled, B_scaled, ~, Dc, ~, MatrixHealth] = build_scaled_descriptor_pencil_v6(LNS_L, LNS_Gam); %#ok<ASGLU>
    masks = build_paperA_mode_masks(data, Config, data.Ny, data.Nx);
    if isfield(data, 'RHO') && ~isempty(data.RHO)
        rho_ref = data.RHO;
    else
        rho_ref = ones(data.Ny, data.Nx);
    end
    Cv_nd = local_get_numeric_field(Config, 'Cv_nd', 0.0);

    entries = repmat(struct( ...
        'sigma', 0.0 + 0.0i, ...
        'gain', NaN, ...
        'sigma_min', NaN, ...
        'solver', 'not_run', ...
        'bubble_overlap', NaN, ...
        'near_wall_energy_frac', NaN, ...
        'shock_energy_frac', NaN, ...
        'free_stream_energy_frac', NaN, ...
        'outlet_wall_energy_frac', NaN, ...
        'peak_row', NaN, ...
        'peak_col', NaN), numel(sigma_list), 1);

    for k = 1:numel(sigma_list)
        sigma_value = sigma_list(k);
        shifted = A_scaled - sigma_value * B_scaled;
        [sigma_min, forcing_scaled, response_scaled, solver_name] = local_smallest_singular_triplet(shifted); %#ok<ASGLU>
        response = Dc * response_scaled;
        response_support = compute_mode_support_field(response, data.Ny, data.Nx, Config.state_layout, rho_ref, Cv_nd, ...
            'Weighting', 'component_energy');
        total_response = max(sum(response_support(:)), 1.0e-30);
        [~, peak_idx] = max(response_support(:));
        [peak_row, peak_col] = ind2sub([data.Ny, data.Nx], peak_idx);

        entries(k).sigma = sigma_value;
        entries(k).sigma_min = sigma_min;
        entries(k).gain = 1.0 / max(sigma_min, 1.0e-30);
        entries(k).solver = solver_name;
        entries(k).bubble_overlap = sum(response_support(masks.bubble_support), 'all') / total_response;
        entries(k).near_wall_energy_frac = sum(response_support(masks.near_wall), 'all') / total_response;
        entries(k).shock_energy_frac = sum(response_support(masks.shock), 'all') / total_response;
        entries(k).free_stream_energy_frac = sum(response_support(masks.free_stream), 'all') / total_response;
        entries(k).outlet_wall_energy_frac = sum(response_support(masks.outlet_wall), 'all') / total_response;
        entries(k).peak_row = peak_row;
        entries(k).peak_col = peak_col;
        entries(k).response_vector = response; %#ok<STRNU>
        entries(k).forcing_vector = forcing_scaled; %#ok<STRNU>
        entries(k).response_support = response_support / total_response; %#ok<STRNU>
    end

    scan = struct();
    scan.sigma_list = sigma_list(:).';
    scan.entries = entries;
    scan.matrix_health = MatrixHealth;
    scan.summary_table = local_build_summary_table(entries);
end

function [sigma_min, forcing_vec, response_vec, solver_name] = local_smallest_singular_triplet(M)
%LOCAL_SMALLEST_SINGULAR_TRIPLET Robust smallest-singular-value helper.

    n_sys = size(M, 1);
    forcing_vec = [];
    response_vec = [];
    solver_name = 'svds';

    if n_sys <= 220
        [U, S, V] = svd(full(M), 'econ');
        sigma_min = S(end, end);
        forcing_vec = U(:, end);
        response_vec = V(:, end);
        solver_name = 'full_svd';
        return;
    end

    try
        opts = struct();
        opts.tol = 1.0e-10;
        opts.maxit = 800;
        [U, S, V] = svds(M, 1, 'smallest', opts);
        sigma_min = S(1, 1);
        forcing_vec = U(:, 1);
        response_vec = V(:, 1);
        solver_name = 'svds_smallest';
        return;
    catch
    end

    normal_matrix = M' * M;
    try
        opts = struct();
        opts.tol = 1.0e-10;
        opts.maxit = 800;
        opts.disp = 0;
        [V, D] = eigs(normal_matrix, 1, 'smallestabs', opts);
        sigma_min = sqrt(max(real(D(1, 1)), 0.0));
        response_vec = V(:, 1);
        forcing_vec = M * response_vec;
        forcing_vec = forcing_vec / max(norm(forcing_vec), 1.0e-30);
        solver_name = 'eigs_normal_matrix';
        return;
    catch ME
        error('compute_descriptor_resolvent_scan:SmallestSingularValue', ...
            'Unable to compute the leading resolvent gain: %s', ME.message);
    end
end

function summary_table = local_build_summary_table(entries)
%LOCAL_BUILD_SUMMARY_TABLE Convert one resolvent scan to a compact table.

    n = numel(entries);
    sigma_r = nan(n, 1);
    sigma_i = nan(n, 1);
    gain = nan(n, 1);
    sigma_min = nan(n, 1);
    bubble = nan(n, 1);
    near_wall = nan(n, 1);
    shock = nan(n, 1);
    free_stream = nan(n, 1);
    outlet_wall = nan(n, 1);
    solver = strings(n, 1);

    for k = 1:n
        sigma_r(k) = real(entries(k).sigma);
        sigma_i(k) = imag(entries(k).sigma);
        gain(k) = entries(k).gain;
        sigma_min(k) = entries(k).sigma_min;
        bubble(k) = entries(k).bubble_overlap;
        near_wall(k) = entries(k).near_wall_energy_frac;
        shock(k) = entries(k).shock_energy_frac;
        free_stream(k) = entries(k).free_stream_energy_frac;
        outlet_wall(k) = entries(k).outlet_wall_energy_frac;
        solver(k) = string(entries(k).solver);
    end

    summary_table = table(sigma_r, sigma_i, gain, sigma_min, bubble, near_wall, shock, free_stream, outlet_wall, solver);
end

function value = local_get_numeric_field(S, field_name, default_value)
%LOCAL_GET_NUMERIC_FIELD Read one optional scalar config field.

    if isstruct(S) && isfield(S, field_name) && ~isempty(S.(field_name))
        value = S.(field_name);
    else
        value = default_value;
    end
end
