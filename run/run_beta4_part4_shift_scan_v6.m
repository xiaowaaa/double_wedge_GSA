function scan = run_beta4_part4_shift_scan_v6(varargin)
%RUN_BETA4_PART4_SHIFT_SCAN_V6 Run a Part4-only local shift scan around the beta=4 pressure-fix case.

    p = inputParser;
    p.FunctionName = 'run_beta4_part4_shift_scan_v6';
    addParameter(p, 'SourceCaseName', 'paperA_validation_270x128_v6_beta4_pressure_fix_trial2', ...
        @(x) ischar(x) || (isstring(x) && isscalar(x)));
    addParameter(p, 'ScanCaseName', 'paperA_validation_270x128_v6_beta4_shift_scan_local', ...
        @(x) ischar(x) || (isstring(x) && isscalar(x)));
    addParameter(p, 'Shifts', [0.032 + 0.020i, 0.036 + 0.024i, 0.042 + 0.028i], @(x) isnumeric(x) && ~isempty(x));
    addParameter(p, 'NEigs', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && x >= 1));
    parse(p, varargin{:});

    paths = setup_double_wedge_paths();
    project_root = paths.project_root;

    source_case_name = char(string(p.Results.SourceCaseName));
    source_dir = fullfile(project_root, 'outputs', 'mat', source_case_name);
    if exist(source_dir, 'dir') ~= 7
        error('run_beta4_part4_shift_scan_v6:MissingSourceCase', ...
            'Source case directory not found: %s', source_dir);
    end

    required_files = {'Part1_Results.mat', 'Part2_Results.mat', 'Part3_Results.mat', 'Diagnose_MatrixHealth_Report.mat'};
    for k = 1:numel(required_files)
        if exist(fullfile(source_dir, required_files{k}), 'file') ~= 2
            error('run_beta4_part4_shift_scan_v6:MissingSourceFile', ...
                'Source case is missing %s', required_files{k});
        end
    end

    scan_root_name = char(string(p.Results.ScanCaseName));
    scan_root_dir = fullfile(project_root, 'outputs', 'mat', scan_root_name);
    if exist(scan_root_dir, 'dir') ~= 7
        mkdir(scan_root_dir);
    end

    shifts = p.Results.Shifts(:).';
    cases = repmat(struct( ...
        'shift', 0.0 + 0.0i, ...
        'case_name', '', ...
        'case_dir', '', ...
        'summary', struct()), numel(shifts), 1);

    for k = 1:numel(shifts)
        shift_value = shifts(k);
        case_leaf = local_case_leaf_name(k, shift_value);
        case_name = fullfile(scan_root_name, case_leaf);
        case_dir = fullfile(scan_root_dir, case_leaf);
        if exist(case_dir, 'dir') ~= 7
            mkdir(case_dir);
        end
        local_copy_case_inputs(source_dir, case_dir, required_files);
        local_update_part3_config(fullfile(case_dir, 'Part3_Results.mat'), shift_value, p.Results.NEigs);

        old_dir = pwd;
        cleanup_obj = onCleanup(@() cd(old_dir)); %#ok<NASGU>
        cd(case_dir);
        Main_DoubleWedge_Part4_v6('FigureDirectory', fullfile(case_dir, 'figs'));
        summary = run_user_test_baseflow_fullres_v6('CaseName', case_name, 'ReuseExistingCase', true);

        cases(k).shift = shift_value;
        cases(k).case_name = case_name;
        cases(k).case_dir = case_dir;
        cases(k).summary = summary;
    end

    scan = struct();
    scan.source_case_name = source_case_name;
    scan.source_dir = source_dir;
    scan.scan_case_name = scan_root_name;
    scan.scan_root_dir = scan_root_dir;
    scan.shifts = shifts;
    scan.cases = cases;
    scan.summary_table = local_build_summary_table(cases);

    save(fullfile(scan_root_dir, 'beta4_shift_scan_summary.mat'), 'scan', '-v7.3');
    local_write_summary_text(fullfile(scan_root_dir, 'beta4_shift_scan_summary.txt'), scan);
end

function local_copy_case_inputs(source_dir, case_dir, required_files)
%LOCAL_COPY_CASE_INPUTS Copy the upstream Part1/2/3 inputs into one Part4-only scan case.

    for k = 1:numel(required_files)
        src = fullfile(source_dir, required_files{k});
        dst = fullfile(case_dir, required_files{k});
        copyfile(src, dst, 'f');
    end
end

function local_update_part3_config(part3_file, shift_value, n_eigs_override)
%LOCAL_UPDATE_PART3_CONFIG Rewrite the Part3 config so the copied case solves around one local shift.

    S = load(part3_file, 'Config');
    Config = S.Config;
    Config.sigma = shift_value;
    Config.sigma_triplet = shift_value;
    if ~isempty(n_eigs_override)
        Config.n_eigs = round(n_eigs_override);
    end
    save(part3_file, 'Config', '-append');
end

function case_leaf = local_case_leaf_name(k, shift_value)
%LOCAL_CASE_LEAF_NAME Build one stable folder name for a complex shift.

    case_leaf = sprintf('shift_%02d_sr_%s_si_%s', ...
        k, local_fmt_num(real(shift_value)), local_fmt_num(imag(shift_value)));
end

function token = local_fmt_num(value)
%LOCAL_FMT_NUM Convert one scalar into a filesystem-safe token.

    token = sprintf('%.3f', value);
    token = strrep(token, '-', 'm');
    token = strrep(token, '.', 'p');
end

function summary_table = local_build_summary_table(cases)
%LOCAL_BUILD_SUMMARY_TABLE Convert scan cases into one compact comparison table.

    n = numel(cases);
    shift = zeros(n, 1);
    sigma_r = zeros(n, 1);
    sigma_i = zeros(n, 1);
    residual = zeros(n, 1);
    bubble = zeros(n, 1);
    near_wall = zeros(n, 1);
    free_stream = zeros(n, 1);
    outlet_wall = zeros(n, 1);
    shock = zeros(n, 1);
    checker = zeros(n, 1);
    publication = false(n, 1);

    for k = 1:n
        shift(k) = cases(k).shift;
        summary_k = cases(k).summary;
        sigma_r(k) = summary_k.leading_sigma_r;
        sigma_i(k) = summary_k.leading_sigma_i;
        residual(k) = summary_k.leading_residual;
        bubble(k) = summary_k.leading_bubble_overlap;
        near_wall(k) = summary_k.leading_near_wall_energy_frac;
        free_stream(k) = summary_k.leading_free_stream_energy_frac;
        outlet_wall(k) = summary_k.leading_outlet_wall_energy_frac;
        shock(k) = summary_k.leading_shock_energy_frac;
        checker(k) = summary_k.leading_checker_ratio;
        publication(k) = logical(summary_k.leading_selected_for_publication);
    end

    summary_table = table(shift, sigma_r, sigma_i, residual, bubble, near_wall, ...
        free_stream, outlet_wall, shock, checker, publication);
end

function local_write_summary_text(output_file, scan)
%LOCAL_WRITE_SUMMARY_TEXT Write a compact comparison text file next to the scan outputs.

    fid = fopen(output_file, 'w');
    if fid == -1
        warning('run_beta4_part4_shift_scan_v6:SummaryWrite', ...
            'Unable to write scan summary: %s', output_file);
        return;
    end

    cleanup_obj = onCleanup(@() fclose(fid)); %#ok<NASGU>

    fprintf(fid, 'beta=4 Part4-only local shift scan\n');
    fprintf(fid, 'source_case: %s\n', scan.source_case_name);
    fprintf(fid, '\n');
    for k = 1:numel(scan.cases)
        summary_k = scan.cases(k).summary;
        fprintf(fid, 'shift %d: %+.6f%+.6fi\n', k, real(scan.cases(k).shift), imag(scan.cases(k).shift));
        fprintf(fid, '  case_dir: %s\n', scan.cases(k).case_dir);
        fprintf(fid, '  leading_sigma: %+.6e%+.6ei\n', summary_k.leading_sigma_r, summary_k.leading_sigma_i);
        fprintf(fid, '  residual: %.6e\n', summary_k.leading_residual);
        fprintf(fid, '  bubble: %.6f\n', summary_k.leading_bubble_overlap);
        fprintf(fid, '  near_wall: %.6f\n', summary_k.leading_near_wall_energy_frac);
        fprintf(fid, '  free_stream: %.6f\n', summary_k.leading_free_stream_energy_frac);
        fprintf(fid, '  outlet_wall: %.6f\n', summary_k.leading_outlet_wall_energy_frac);
        fprintf(fid, '  shock: %.6f\n', summary_k.leading_shock_energy_frac);
        fprintf(fid, '  checker: %.6f\n', summary_k.leading_checker_ratio);
        fprintf(fid, '  publication: %d\n', summary_k.leading_selected_for_publication);
        fprintf(fid, '\n');
    end
end
