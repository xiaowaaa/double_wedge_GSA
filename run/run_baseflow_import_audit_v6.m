function summary = run_baseflow_import_audit_v6(varargin)
%RUN_BASEFLOW_IMPORT_AUDIT_V6 Inspect headerless or real-case baseflow imports.

    p = inputParser;
    p.FunctionName = 'run_baseflow_import_audit_v6';
    addParameter(p, 'BaseflowFile', '', @(x) ischar(x) || (isstring(x) && isscalar(x)));
    addParameter(p, 'ExpectedDims', [], @(x) isempty(x) || (isnumeric(x) && numel(x) == 2));
    addParameter(p, 'StrideX', 1, @(x) isnumeric(x) && isscalar(x) && x >= 1);
    addParameter(p, 'StrideY', 1, @(x) isnumeric(x) && isscalar(x) && x >= 1);
    addParameter(p, 'TopType', 'inlet', @(x) ischar(x) || (isstring(x) && isscalar(x)));
    addParameter(p, 'CaseName', 'baseflow_import_audit_v6', ...
        @(x) ischar(x) || (isstring(x) && isscalar(x)));
    parse(p, varargin{:});

    paths = setup_double_wedge_paths();
    project_root = paths.project_root;

    cfg = config_case();
    baseflow_file = char(string(p.Results.BaseflowFile));
    if strlength(string(baseflow_file)) == 0
        baseflow_file = cfg.io.baseflow_file;
    else
        cfg.io.baseflow_file = baseflow_file;
    end
    if ~isempty(p.Results.ExpectedDims)
        cfg.reader.expected_dims = double(p.Results.ExpectedDims(:)).';
    end
    cfg.reader.stride_x = round(p.Results.StrideX);
    cfg.reader.stride_y = round(p.Results.StrideY);
    cfg.bc.top_type = char(string(p.Results.TopType));

    case_dir = fullfile(project_root, 'outputs', 'mat', char(string(p.Results.CaseName)));
    if exist(case_dir, 'dir') ~= 7
        mkdir(case_dir);
    end

    old_figure_dir = cfg.io.figure_dir;
    cfg.io.figure_dir = fullfile(case_dir, 'figs');
    if exist(cfg.io.figure_dir, 'dir') ~= 7
        mkdir(cfg.io.figure_dir);
    end

    base = read_phenglei_baseflow(cfg);
    base = preprocess_baseflow(base, cfg);

    gamma = cfg.flow.gamma;
    Ma_inf = cfg.flow.Ma_inf;
    R_nd = 1.0 / (gamma * Ma_inf^2);
    eos_ref = R_nd * base.rho .* base.T;
    eos_rel = abs(base.p - eos_ref) ./ max(abs(base.p), eps);
    ratio = base.p ./ max(eos_ref, eps);

    summary = struct();
    summary.case_dir = case_dir;
    summary.baseflow_file = baseflow_file;
    summary.top_type = cfg.bc.top_type;
    summary.expected_dims = cfg.reader.expected_dims;
    summary.raw_dims = base.metadata.original_dims;
    summary.working_dims = [base.Nx, base.Ny];
    summary.stride = [cfg.reader.stride_x, cfg.reader.stride_y];
    summary.num_vars_read = base.metadata.num_vars_read;
    summary.standard_num_vars = base.metadata.standard_num_vars;
    summary.gamma_column_present = base.metadata.gamma_column_present;
    summary.num_optional_standard_vars = base.metadata.num_optional_standard_vars;
    summary.num_extra_vars = base.metadata.num_extra_vars;
    summary.num_vars_inferred = base.metadata.num_vars_inferred;
    summary.eos_relative_error = base.validation.eos_relative_error;
    summary.eos_relative_error_stats = local_stats(eos_rel);
    summary.wall_temperature_relative_mismatch = base.validation.wall_temperature_relative_mismatch;
    summary.required_eos_relation = 'p = rho*T/(gamma*Ma^2)';
    summary.pressure_ratio_label = 'p / (rho*T/(gamma*Ma^2))';
    summary.pressure_ratio_stats = local_stats(ratio);
    summary.pressure_stats = local_stats(base.p);
    summary.rho_stats = local_stats(base.rho);
    summary.temperature_stats = local_stats(base.T);
    summary.mach_stats = local_stats(base.mach);
    summary.w_stats = local_stats(base.w);
    summary.freestream_toprow = struct( ...
        'rho_mean', mean(base.rho(end, :)), ...
        'T_mean', mean(base.T(end, :)), ...
        'p_mean', mean(base.p(end, :)), ...
        'mach_mean', mean(base.mach(end, :)));
    summary.old_figure_dir = old_figure_dir; %#ok<STRNU>

    save(fullfile(case_dir, 'baseflow_import_audit.mat'), 'summary', '-v7.3');
    local_write_summary_text(fullfile(case_dir, 'baseflow_import_audit.txt'), summary);

    fprintf('\n[run_baseflow_import_audit_v6] Case directory: %s\n', case_dir);
    fprintf('[run_baseflow_import_audit_v6] Raw grid: %d x %d, working grid: %d x %d, columns=%d (standard=%d, optional=%d, extra=%d)\n', ...
        summary.raw_dims(1), summary.raw_dims(2), ...
        summary.working_dims(1), summary.working_dims(2), ...
        summary.num_vars_read, summary.standard_num_vars, ...
        summary.num_optional_standard_vars, summary.num_extra_vars);
    fprintf('[run_baseflow_import_audit_v6] EOS relative error: %.6e\n', summary.eos_relative_error);
    fprintf('[run_baseflow_import_audit_v6] EOS rel p95=%.6e, median=%.6e\n', ...
        summary.eos_relative_error_stats.p95, ...
        summary.eos_relative_error_stats.median);
    fprintf('[run_baseflow_import_audit_v6] p/(R*rho*T) median=%.6f, p05=%.6f, p95=%.6f\n', ...
        summary.pressure_ratio_stats.median, ...
        summary.pressure_ratio_stats.p05, ...
        summary.pressure_ratio_stats.p95);
end

function stats = local_stats(data_value)
%LOCAL_STATS Basic scalar-field summary statistics.

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

function value = local_percentile(data_value, pct)
%LOCAL_PERCENTILE Toolbox-free percentile helper.

    data_value = sort(data_value(:));
    if isempty(data_value)
        value = NaN;
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

function local_write_summary_text(output_file, summary)
%LOCAL_WRITE_SUMMARY_TEXT Save a concise human-readable audit summary.

    fid = open_output_text_file(output_file);
    if fid == -1
        warning('run_baseflow_import_audit_v6:SummaryWrite', ...
            'Unable to write summary text file: %s', output_file);
        return;
    end
    cleanup_obj = onCleanup(@() fclose(fid)); %#ok<NASGU>

    fprintf(fid, '%s\n', localize_output_label('Baseflow import audit v6'));
    fprintf(fid, '%s: %s\n', localize_output_label('baseflow_file'), summary.baseflow_file);
    fprintf(fid, '%s: [%s]\n', localize_output_label('expected_dims'), local_format_dims(summary.expected_dims));
    fprintf(fid, '%s: %d x %d\n', localize_output_label('raw_dims'), summary.raw_dims(1), summary.raw_dims(2));
    fprintf(fid, '%s: %d x %d\n', localize_output_label('working_dims'), summary.working_dims(1), summary.working_dims(2));
    fprintf(fid, '%s: %d x %d\n', localize_output_label('stride'), summary.stride(1), summary.stride(2));
    fprintf(fid, '%s: %s\n', localize_output_label('top_type'), summary.top_type);
    fprintf(fid, '%s: %d\n', localize_output_label('num_vars_read'), summary.num_vars_read);
    fprintf(fid, '%s: %d\n', localize_output_label('standard_num_vars'), summary.standard_num_vars);
    fprintf(fid, '%s: %d\n', localize_output_label('gamma_column_present'), summary.gamma_column_present);
    fprintf(fid, '%s: %d\n', localize_output_label('num_optional_standard_vars'), summary.num_optional_standard_vars);
    fprintf(fid, '%s: %d\n', localize_output_label('num_extra_vars'), summary.num_extra_vars);
    fprintf(fid, '%s: %d\n', localize_output_label('num_vars_inferred'), summary.num_vars_inferred);
    fprintf(fid, '%s: %.6e\n', localize_output_label('eos_relative_error'), summary.eos_relative_error);
    fprintf(fid, '%s: min=%.6e p05=%.6e median=%.6e mean=%.6e p95=%.6e max=%.6e\n', ...
        localize_output_label('eos_relative_error_stats'), ...
        summary.eos_relative_error_stats.min, summary.eos_relative_error_stats.p05, ...
        summary.eos_relative_error_stats.median, summary.eos_relative_error_stats.mean, ...
        summary.eos_relative_error_stats.p95, summary.eos_relative_error_stats.max);
    fprintf(fid, '%s: %.6e\n', localize_output_label('wall_temperature_relative_mismatch'), summary.wall_temperature_relative_mismatch);
    fprintf(fid, '%s: %s\n', localize_output_label('required_eos_relation'), summary.required_eos_relation);
    fprintf(fid, '%s 统计:\n', summary.pressure_ratio_label);
    fprintf(fid, '  min=%.6e p05=%.6e median=%.6e mean=%.6e p95=%.6e max=%.6e\n', ...
        summary.pressure_ratio_stats.min, summary.pressure_ratio_stats.p05, ...
        summary.pressure_ratio_stats.median, summary.pressure_ratio_stats.mean, ...
        summary.pressure_ratio_stats.p95, summary.pressure_ratio_stats.max);
    fprintf(fid, '%s: min=%.6e median=%.6e max=%.6e\n', localize_output_label('pressure stats'), ...
        summary.pressure_stats.min, summary.pressure_stats.median, summary.pressure_stats.max);
    fprintf(fid, '%s: min=%.6e median=%.6e max=%.6e\n', localize_output_label('rho stats'), ...
        summary.rho_stats.min, summary.rho_stats.median, summary.rho_stats.max);
    fprintf(fid, '%s: min=%.6e median=%.6e max=%.6e\n', localize_output_label('temperature stats'), ...
        summary.temperature_stats.min, summary.temperature_stats.median, summary.temperature_stats.max);
    fprintf(fid, '%s: min=%.6e median=%.6e max=%.6e\n', localize_output_label('mach stats'), ...
        summary.mach_stats.min, summary.mach_stats.median, summary.mach_stats.max);
    fprintf(fid, '%s: min=%.6e median=%.6e max=%.6e\n', localize_output_label('w stats'), ...
        summary.w_stats.min, summary.w_stats.median, summary.w_stats.max);
    fprintf(fid, '%s: rho=%.6e T=%.6e p=%.6e Mach=%.6e\n', localize_output_label('top-row means'), ...
        summary.freestream_toprow.rho_mean, summary.freestream_toprow.T_mean, ...
        summary.freestream_toprow.p_mean, summary.freestream_toprow.mach_mean);
end

function text_value = local_format_dims(dims_value)
%LOCAL_FORMAT_DIMS Format one optional dimension pair.

    if isempty(dims_value)
        text_value = '';
    else
        text_value = sprintf('%d %d', dims_value(1), dims_value(2));
    end
end
