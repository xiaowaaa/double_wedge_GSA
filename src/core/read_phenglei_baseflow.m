function base = read_phenglei_baseflow(cfg)
%READ_PHENGLEI_BASEFLOW Read a Tecplot POINT-format PHengLEI baseflow file.

    required_num_vars = 11;
    standard_num_vars = 12;

    if ~isfield(cfg, 'io') || ~isfield(cfg.io, 'baseflow_file')
        error('read_phenglei_baseflow:Config', 'cfg.io.baseflow_file is required.');
    end

    text = fileread(cfg.io.baseflow_file);
    lines = regexp(text, '\r\n|\n|\r', 'split');
    lines = lines(:);

    first_data_idx = local_find_first_data_line(lines);
    header_lines = lines(1:first_data_idx - 1);
    data_lines = lines(first_data_idx:end);
    header_text = strjoin(header_lines, ' ');

    [I, J, using_fallback] = local_parse_dims(header_text, cfg);
    [num_vars_hint, has_explicit_var_count] = local_parse_num_vars(lines, cfg);
    data_vals = sscanf(strjoin(data_lines, sprintf('\n')), '%f');
    num_vars = local_resolve_num_vars(num_vars_hint, has_explicit_var_count, numel(data_vals), I * J);
    if mod(numel(data_vals), num_vars) ~= 0
        error('read_phenglei_baseflow:ColumnCount', ...
            ['The Tecplot data length is not divisible by %d columns. ' ...
             'Parsed %d scalars for %d grid points.'], ...
            num_vars, numel(data_vals), I * J);
    end

    data_mat = reshape(data_vals, num_vars, []).';
    if size(data_mat, 2) < required_num_vars
        error('read_phenglei_baseflow:MissingColumns', ...
            'At least %d columns are required, but only %d were found.', required_num_vars, size(data_mat, 2));
    end
    if size(data_mat, 1) ~= I * J
        error('read_phenglei_baseflow:Dimensions', ...
            'Expected %d points from the header, found %d.', I * J, size(data_mat, 1));
    end

    raw = struct();
    raw.x = reshape(data_mat(:, 1), [I, J]).';
    raw.y = reshape(data_mat(:, 2), [I, J]).';
    raw.z = reshape(data_mat(:, 3), [I, J]).';
    raw.rho = reshape(data_mat(:, 4), [I, J]).';
    raw.u = reshape(data_mat(:, 5), [I, J]).';
    raw.v = reshape(data_mat(:, 6), [I, J]).';
    raw.w = reshape(data_mat(:, 7), [I, J]).';
    raw.p = reshape(data_mat(:, 8), [I, J]).';
    raw.T = reshape(data_mat(:, 9), [I, J]).';
    raw.mach = reshape(data_mat(:, 10), [I, J]).';
    raw.cp = reshape(data_mat(:, 11), [I, J]).';
    if size(data_mat, 2) >= 12
        raw.gama = reshape(data_mat(:, 12), [I, J]).';
        raw.gamma_local = raw.gama;
    end

    sx = cfg.reader.stride_x;
    sy = cfg.reader.stride_y;
    pick_x = 1:sx:size(raw.x, 2);
    pick_y = 1:sy:size(raw.x, 1);

    base = struct();
    base.raw = raw;
    base.x = raw.x(pick_y, pick_x);
    base.y = raw.y(pick_y, pick_x);
    base.z = raw.z(pick_y, pick_x);
    base.rho = raw.rho(pick_y, pick_x);
    base.u = raw.u(pick_y, pick_x);
    base.v = raw.v(pick_y, pick_x);
    base.w = raw.w(pick_y, pick_x);
    base.p = raw.p(pick_y, pick_x);
    base.T = raw.T(pick_y, pick_x);
    base.mach = raw.mach(pick_y, pick_x);
    base.cp = raw.cp(pick_y, pick_x);
    if isfield(raw, 'gama')
        base.gama = raw.gama(pick_y, pick_x);
        base.gamma_local = raw.gamma_local(pick_y, pick_x);
    end
    base.Nx = size(base.x, 2);
    base.Ny = size(base.x, 1);
    base.ds_x = sx;
    base.ds_y = sy;

    base.metadata = struct();
    base.metadata.original_dims = [I, J];
    base.metadata.using_headerless_fallback = using_fallback;
    base.metadata.num_vars_read = num_vars;
    base.metadata.required_num_vars = required_num_vars;
    base.metadata.standard_num_vars = standard_num_vars;
    base.metadata.num_optional_standard_vars = max(0, min(num_vars, standard_num_vars) - required_num_vars);
    base.metadata.gamma_column_present = num_vars >= 12;
    base.metadata.num_extra_vars = max(0, num_vars - standard_num_vars);
    base.metadata.num_vars_inferred = ~has_explicit_var_count;

    legacy_cfg = local_make_legacy_boundary_config(cfg);
    [boundary_masks, boundary_info] = build_boundary_masks(base.x, base.y, legacy_cfg, 'Verbose', false);
    base.boundary = struct();
    base.boundary.masks = boundary_masks;
    base.boundary.counts = boundary_info.counts;
    base.boundary.top_type = cfg.bc.top_type;

    if isfield(cfg, 'io') && isfield(cfg.io, 'figure_dir') && isfield(cfg, 'plot')
        if exist(cfg.io.figure_dir, 'dir') ~= 7
            mkdir(cfg.io.figure_dir);
        end
        plot_boundary_map(base.x, base.y, legacy_cfg, ...
            'OutputFile', fullfile(cfg.io.figure_dir, cfg.plot.boundary_audit_name), ...
            'Visible', cfg.plot.visible, ...
            'Verbose', false);
    end
end

function first_idx = local_find_first_data_line(lines)
%LOCAL_FIND_FIRST_DATA_LINE Find the first numeric line in the Tecplot file.

    first_idx = [];
    for k = 1:numel(lines)
        trimmed = strtrim(lines{k});
        if isempty(trimmed)
            continue;
        end
        if ~isempty(regexp(trimmed, '^[\+\-]?\d', 'once'))
            first_idx = k;
            return;
        end
    end
    error('read_phenglei_baseflow:Data', 'Unable to locate the first numeric data line.');
end

function [I, J, using_fallback] = local_parse_dims(header_text, cfg)
%LOCAL_PARSE_DIMS Extract I/J dimensions or fall back to cfg.reader.expected_dims.

    token_I = regexp(header_text, 'I\s*=\s*(\d+)', 'tokens', 'once');
    token_J = regexp(header_text, 'J\s*=\s*(\d+)', 'tokens', 'once');
    using_fallback = false;

    if ~isempty(token_I) && ~isempty(token_J)
        I = str2double(token_I{1});
        J = str2double(token_J{1});
        return;
    end

    if ~isempty(cfg.reader.expected_dims)
        I = cfg.reader.expected_dims(1);
        J = cfg.reader.expected_dims(2);
        using_fallback = true;
    else
        error('read_phenglei_baseflow:Header', ...
            'Unable to parse I/J from the Tecplot header and no expected_dims fallback is available.');
    end
end

function [num_vars, has_explicit_var_count] = local_parse_num_vars(lines, cfg)
%LOCAL_PARSE_NUM_VARS Count VARIABLES entries before the ZONE line.

    zone_idx = find(contains(lines, 'ZONE'), 1, 'first');
    if isempty(zone_idx)
        zone_idx = 1;
    end
    var_start = find(contains(lines, 'VARIABLES'), 1, 'first');
    if isempty(var_start)
        var_start = 1;
    end
    var_count = 0;
    for k = var_start:zone_idx-1
        if contains(lines{k}, '"')
            var_count = var_count + numel(regexp(lines{k}, '"[^"]*"', 'match'));
        end
    end
    has_explicit_var_count = var_count > 0;
    if ~has_explicit_var_count
        num_vars = cfg.reader.n_expected_vars;
    else
        num_vars = var_count;
    end
end

function num_vars = local_resolve_num_vars(num_vars_hint, has_explicit_var_count, num_scalars, point_count)
%LOCAL_RESOLVE_NUM_VARS Infer the true column count for headerless files.

    num_vars = num_vars_hint;
    if point_count <= 0
        return;
    end

    rows_with_hint = num_scalars / num_vars_hint;
    if abs(rows_with_hint - point_count) < 1.0e-12
        return;
    end

    if has_explicit_var_count
        return;
    end

    inferred = num_scalars / point_count;
    inferred_round = round(inferred);
    if abs(inferred - inferred_round) < 1.0e-12 && inferred_round >= 11
        num_vars = inferred_round;
    end
end

function legacy_cfg = local_make_legacy_boundary_config(cfg)
%LOCAL_MAKE_LEGACY_BOUNDARY_CONFIG Convert modular BC data to the legacy map.

    legacy_cfg = struct();
    legacy_cfg.Ma_inf = cfg.flow.Ma_inf;
    legacy_cfg.Re_inf = cfg.flow.Re_inf;
    legacy_cfg.T_inf = cfg.flow.T_inf;
    legacy_cfg.gamma = cfg.flow.gamma;
    legacy_cfg.Pr = cfg.flow.Pr;
    legacy_cfg.x_hinge = cfg.geometry.x_hinge;
    legacy_cfg.n_eigs = 10;
    legacy_cfg.datafile = cfg.io.baseflow_file;
    legacy_cfg.boundary_map = struct( ...
        'south', cfg.bc.bottom_type, ...
        'north', cfg.bc.top_type, ...
        'west', cfg.bc.left_type, ...
        'east', cfg.bc.right_type);
end
