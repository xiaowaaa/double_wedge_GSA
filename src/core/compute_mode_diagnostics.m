function diag_info = compute_mode_diagnostics(q_mode, Ny, Nx, varargin)
%COMPUTE_MODE_DIAGNOSTICS Compute quality diagnostics for one mode.

    p = inputParser;
    p.FunctionName = 'compute_mode_diagnostics';
    addParameter(p, 'BoundaryWidth', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && x >= 1));
    addParameter(p, 'BoundaryMask', [], @(x) isempty(x) || islogical(x));
    addParameter(p, 'FarfieldMask', [], @(x) isempty(x) || islogical(x));
    addParameter(p, 'BoundaryMasks', struct(), @isstruct);
    addParameter(p, 'X', [], @(x) isempty(x) || isnumeric(x));
    addParameter(p, 'Y', [], @(x) isempty(x) || isnumeric(x));
    addParameter(p, 'U', [], @(x) isempty(x) || isnumeric(x));
    addParameter(p, 'XHinge', [], @(x) isempty(x) || isnumeric(x));
    addParameter(p, 'StateLayout', 'primitive5_u_v_w_T_p', @(x) ischar(x) || (isstring(x) && isscalar(x)));
    parse(p, varargin{:});

    layout = get_state_layout_info(p.Results.StateLayout);
    boundary_mask = local_choose_mask(p.Results.BoundaryMask, p.Results.BoundaryMasks, Ny, Nx, 'outer', p.Results.BoundaryWidth);
    farfield_mask = local_choose_mask(p.Results.FarfieldMask, p.Results.BoundaryMasks, Ny, Nx, 'farfield', []);

    component_names = {'rho', 'u', 'v', 'w', 'T', 'p'};
    fields = struct();
    combined_energy = zeros(Ny, Nx);
    for k = 1:numel(component_names)
        comp = component_names{k};
        fields.(comp) = extract_state_component(q_mode, Ny, Nx, layout.name, comp);
        if ~all(isnan(fields.(comp)(:)))
            combined_energy = combined_energy + abs(fields.(comp)).^2;
        end
    end

    total_energy = sum(combined_energy(:));
    if total_energy <= 0
        total_energy = 1.0;
    end

    diag_info = struct();
    diag_info.total_energy = total_energy;
    diag_info.outer_energy = sum(combined_energy(boundary_mask));
    diag_info.inner_energy = total_energy - diag_info.outer_energy;
    diag_info.outer_energy_ratio = diag_info.outer_energy / total_energy;
    diag_info.inner_energy_ratio = diag_info.inner_energy / total_energy;
    diag_info.boundary_width = local_default_boundary_width(p.Results.BoundaryWidth);
    diag_info.farfield_energy = sum(combined_energy(farfield_mask));
    diag_info.farfield_energy_ratio = diag_info.farfield_energy / total_energy;
    diag_info.state_layout = layout.name;

    checker_pattern = (-1) .^ (local_row_grid(Ny, Nx) + local_col_grid(Ny, Nx));
    checker_values = [];
    highfreq_values = [];
    for k = 1:numel(component_names)
        comp = component_names{k};
        field = fields.(comp);
        if all(isnan(field(:)))
            diag_info.(sprintf('checker_%s', comp)) = NaN;
            diag_info.(sprintf('highfreq_%s', comp)) = NaN;
            diag_info.(sprintf('peak_%s', comp)) = NaN;
            continue;
        end
        amp = abs(field);
        diag_info.(sprintf('checker_%s', comp)) = ...
            abs(sum(field(:) .* checker_pattern(:))) / max(sum(abs(field(:))), eps);
        grad_x = fd4_uniform(field, 2, 1);
        grad_y = fd4_uniform(field, 1, 1);
        diag_info.(sprintf('highfreq_%s', comp)) = ...
            (norm(grad_x(:)) + norm(grad_y(:))) / max(norm(field(:)), eps);
        diag_info.(sprintf('peak_%s', comp)) = max(amp(:));
        checker_values(end + 1) = diag_info.(sprintf('checker_%s', comp)); %#ok<AGROW>
        highfreq_values(end + 1) = diag_info.(sprintf('highfreq_%s', comp)); %#ok<AGROW>
    end

    diag_info.checker_uv = local_mean_available([diag_info.checker_u, diag_info.checker_v]);
    diag_info.checker_all = local_mean_available(checker_values);
    diag_info.highfreq_uv = local_mean_available([diag_info.highfreq_u, diag_info.highfreq_v]);
    diag_info.highfreq_all = local_mean_available(highfreq_values);

    [X_ref, Y_ref] = local_reference_grid(Nx, Ny, p.Results.X, p.Results.Y);
    y_norm = local_wall_relative_eta(Y_ref);
    diag_info.y_centroid = sum(combined_energy(:) .* y_norm(:)) / total_energy;
    diag_info.y_spread = sqrt(sum(combined_energy(:) .* (y_norm(:) - diag_info.y_centroid).^2) / total_energy);

    support_amplitude = local_support_amplitude(fields, layout);
    support_threshold = 0.2 * max(support_amplitude(:));
    if support_threshold > 0
        diag_info.support_fraction = nnz(support_amplitude >= support_threshold) / numel(support_amplitude);
    else
        diag_info.support_fraction = 0.0;
    end
    diag_info.compact_support_penalty = max(0.0, 0.02 - diag_info.support_fraction);

    ref_masks = build_mode_reference_masks(X_ref, Y_ref, p.Results.U, 'BoundaryMasks', p.Results.BoundaryMasks);
    diag_info.bubble_overlap = sum(combined_energy(ref_masks.bubble)) / total_energy;
    diag_info.upper_layer_penalty = sum(combined_energy(ref_masks.upper_layer)) / total_energy;

    [peak_row, peak_col] = local_peak_location(support_amplitude);
    diag_info.peak_distance_to_wall = y_norm(peak_row, peak_col);
    diag_info.peak_distance_to_farfield = 1.0 - y_norm(peak_row, peak_col);
end

function mask = local_choose_mask(mask_in, boundary_masks, Ny, Nx, field_name, boundary_width)
%LOCAL_CHOOSE_MASK Resolve a requested mask from direct input or structure.

    if ~isempty(mask_in)
        mask = logical(mask_in);
        return;
    end
    if ~isempty(boundary_masks) && isfield(boundary_masks, field_name)
        mask = logical(boundary_masks.(field_name));
        return;
    end

    mask = false(Ny, Nx);
    switch field_name
        case 'outer'
            bw = local_default_boundary_width(boundary_width);
            mask(1:bw, :) = true;
            mask(end-bw+1:end, :) = true;
            mask(:, 1:bw) = true;
            mask(:, end-bw+1:end) = true;
        case 'farfield'
            mask(end, :) = true;
    end
end

function bw = local_default_boundary_width(boundary_width)
%LOCAL_DEFAULT_BOUNDARY_WIDTH Choose the fallback boundary band width.

    if isempty(boundary_width)
        bw = 2;
    else
        bw = boundary_width;
    end
end

function [X_ref, Y_ref] = local_reference_grid(Nx, Ny, X_in, Y_in)
%LOCAL_REFERENCE_GRID Use provided coordinates or synthetic unit-square indices.

    if isempty(X_in) || isempty(Y_in)
        [X_ref, Y_ref] = meshgrid(linspace(0.0, 1.0, Nx), linspace(0.0, 1.0, Ny));
    else
        X_ref = X_in;
        Y_ref = Y_in;
    end
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

function mean_value = local_mean_available(values)
%LOCAL_MEAN_AVAILABLE Mean over finite values only.

    values = values(isfinite(values));
    if isempty(values)
        mean_value = NaN;
    else
        mean_value = mean(values);
    end
end

function amp = local_support_amplitude(fields, layout)
%LOCAL_SUPPORT_AMPLITUDE Use the strongest available physical field.

    if ~isnan(layout.components.u)
        amp = abs(fields.u);
        return;
    end
    if ~isnan(layout.components.rho)
        amp = abs(fields.rho);
        return;
    end

    amp = zeros(size(fields.T));
    names = fieldnames(fields);
    for k = 1:numel(names)
        field = fields.(names{k});
        if all(isnan(field(:)))
            continue;
        end
        amp = max(amp, abs(field));
    end
end

function [peak_row, peak_col] = local_peak_location(amp)
%LOCAL_PEAK_LOCATION Return the strongest-support grid point.

    [~, linear_idx] = max(amp(:));
    [peak_row, peak_col] = ind2sub(size(amp), linear_idx);
end

function rows = local_row_grid(Ny, Nx)
%LOCAL_ROW_GRID Helper grid for checkerboard diagnostics.

    rows = repmat((1:Ny).', 1, Nx);
end

function cols = local_col_grid(Ny, Nx)
%LOCAL_COL_GRID Helper grid for checkerboard diagnostics.

    cols = repmat(1:Nx, Ny, 1);
end
