function scan = run_beta_scan_v6(varargin)
%RUN_BETA_SCAN_V6 Run a reusable beta scan on the v6 chain.

    p = inputParser;
    p.FunctionName = 'run_beta_scan_v6';
    addParameter(p, 'ScanCaseName', 'beta_scan_v6', @(x) ischar(x) || (isstring(x) && isscalar(x)));
    addParameter(p, 'Betas', 0.0, @(x) isnumeric(x) && ~isempty(x));
    addParameter(p, 'BaseflowFile', '', @(x) ischar(x) || (isstring(x) && isscalar(x)));
    addParameter(p, 'ExpectedDims', [270, 128], @(x) isnumeric(x) && numel(x) == 2);
    addParameter(p, 'StrideX', 1, @(x) isnumeric(x) && isscalar(x) && x >= 1);
    addParameter(p, 'StrideY', 1, @(x) isnumeric(x) && isscalar(x) && x >= 1);
    addParameter(p, 'TopType', 'inlet', @(x) ischar(x) || (isstring(x) && isscalar(x)));
    addParameter(p, 'BenchmarkProfile', 'sidharth2018_code_correction_v1', ...
        @(x) ischar(x) || (isstring(x) && isscalar(x)));
    addParameter(p, 'UseSponge', false, @(x) islogical(x) || isnumeric(x));
    addParameter(p, 'NEigs', 80, @(x) isnumeric(x) && isscalar(x) && x >= 1);
    addParameter(p, 'SigmaShift', 0.05 + 0.02i, @(x) isnumeric(x) && isscalar(x));
    addParameter(p, 'SigmaTriplet', [], @(x) isempty(x) || isnumeric(x));
    addParameter(p, 'KrylovDimensionFloor', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && x >= 8));
    addParameter(p, 'KrylovDimensionCap', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && x >= 8));
    addParameter(p, 'ForceLowMemoryDescriptor', false, @(x) islogical(x) || isnumeric(x));
    addParameter(p, 'RunPart4', true, @(x) islogical(x) || isnumeric(x));
    addParameter(p, 'Part3Variant', 'current_v6', @(x) ischar(x) || (isstring(x) && isscalar(x)));
    addParameter(p, 'UseSemiArtificialViscosity', [], @(x) isempty(x) || islogical(x) || isnumeric(x));
    addParameter(p, 'UseShockSourceRegularization', [], @(x) isempty(x) || islogical(x) || isnumeric(x));
    addParameter(p, 'UsePressureRowRegularization', [], @(x) isempty(x) || islogical(x) || isnumeric(x));
    addParameter(p, 'EnableAdjointLeadDiagnostics', [], @(x) isempty(x) || islogical(x) || isnumeric(x));
    parse(p, varargin{:});

    paths = setup_double_wedge_paths();
    project_root = paths.project_root;
    scan_case_name = char(string(p.Results.ScanCaseName));
    scan_root_dir = fullfile(project_root, 'outputs', 'mat', scan_case_name);
    if exist(scan_root_dir, 'dir') ~= 7
        mkdir(scan_root_dir);
    end

    betas = p.Results.Betas(:).';
    cases = repmat(struct('beta', 0.0, 'case_name', '', 'case_dir', '', 'summary', struct()), numel(betas), 1);
    for k = 1:numel(betas)
        beta_value = betas(k);
        case_leaf = sprintf('beta_%02d_%s', k, local_fmt_num(beta_value));
        case_name = fullfile(scan_case_name, case_leaf);
        cases(k).beta = beta_value;
        cases(k).case_name = case_name;
        cases(k).summary = run_user_test_baseflow_fullres_v6( ...
            'BaseflowFile', p.Results.BaseflowFile, ...
            'ExpectedDims', p.Results.ExpectedDims, ...
            'StrideX', p.Results.StrideX, ...
            'StrideY', p.Results.StrideY, ...
            'TopType', p.Results.TopType, ...
            'BenchmarkProfile', p.Results.BenchmarkProfile, ...
            'UseSponge', p.Results.UseSponge, ...
            'NEigs', p.Results.NEigs, ...
            'Beta', beta_value, ...
            'SigmaShift', p.Results.SigmaShift, ...
            'SigmaTriplet', p.Results.SigmaTriplet, ...
            'KrylovDimensionFloor', p.Results.KrylovDimensionFloor, ...
            'KrylovDimensionCap', p.Results.KrylovDimensionCap, ...
            'ForceLowMemoryDescriptor', p.Results.ForceLowMemoryDescriptor, ...
            'CaseName', case_name, ...
            'ReuseExistingCase', false, ...
            'RunPart4', p.Results.RunPart4, ...
            'Part3Variant', p.Results.Part3Variant, ...
            'UseSemiArtificialViscosity', p.Results.UseSemiArtificialViscosity, ...
            'UseShockSourceRegularization', p.Results.UseShockSourceRegularization, ...
            'UsePressureRowRegularization', p.Results.UsePressureRowRegularization, ...
            'EnableAdjointLeadDiagnostics', p.Results.EnableAdjointLeadDiagnostics);
        cases(k).case_dir = cases(k).summary.case_dir;
    end

    branch_correlation_to_prev = nan(numel(betas), 1);
    if logical(p.Results.RunPart4)
        for k = 2:numel(betas)
            prev = load(fullfile(cases(k - 1).case_dir, 'Part4_Results.mat'));
            curr = load(fullfile(cases(k).case_dir, 'Part4_Results.mat'));
            [prev_idx, ~, ~] = resolve_part4_plot_lead_position(prev);
            [curr_idx, ~, ~] = resolve_part4_plot_lead_position(curr);
            if isfinite(prev_idx) && isfinite(curr_idx)
                branch_correlation_to_prev(k) = local_mode_correlation(prev.EigVecs_s(:, prev_idx), curr.EigVecs_s(:, curr_idx));
            end
        end
    end

    scan = struct();
    scan.scan_case_name = scan_case_name;
    scan.scan_root_dir = scan_root_dir;
    scan.betas = betas;
    scan.benchmark_profile = char(string(p.Results.BenchmarkProfile));
    scan.run_part4 = logical(p.Results.RunPart4);
    scan.cases = cases;
    scan.branch_correlation_to_prev = branch_correlation_to_prev;
    scan.summary_table = local_build_summary_table(cases, branch_correlation_to_prev);

    save(fullfile(scan_root_dir, 'beta_scan_summary.mat'), 'scan', '-v7.3');
    local_write_summary_text(fullfile(scan_root_dir, 'beta_scan_summary.txt'), scan);
end

function value = local_mode_correlation(q_prev, q_curr)
%LOCAL_MODE_CORRELATION Simple normalized complex mode correlation.

    value = abs(q_prev' * q_curr) / max(norm(q_prev) * norm(q_curr), 1.0e-30);
end

function summary_table = local_build_summary_table(cases, branch_correlation_to_prev)
%LOCAL_BUILD_SUMMARY_TABLE Convert one beta scan to a compact table.

    n = numel(cases);
    beta = nan(n, 1);
    stage = strings(n, 1);
    sigma_r = nan(n, 1);
    sigma_i = nan(n, 1);
    residual = nan(n, 1);
    bubble = nan(n, 1);
    shock = nan(n, 1);
    checker = nan(n, 1);
    mode_family = strings(n, 1);

    for k = 1:n
        beta(k) = cases(k).beta;
        summary_k = cases(k).summary;
        stage(k) = string(summary_k.stage_completed);
        if strcmp(summary_k.stage_completed, 'Part4')
            sigma_r(k) = summary_k.leading_sigma_r;
            sigma_i(k) = summary_k.leading_sigma_i;
            residual(k) = summary_k.leading_residual;
            bubble(k) = summary_k.leading_bubble_overlap;
            shock(k) = summary_k.leading_shock_energy_frac;
            checker(k) = summary_k.leading_checker_ratio;
            mode_family(k) = string(local_get_mode_family(summary_k));
        end
    end

    summary_table = table(beta, stage, sigma_r, sigma_i, residual, bubble, shock, checker, branch_correlation_to_prev, mode_family);
end

function label = local_get_mode_family(summary_k)
%LOCAL_GET_MODE_FAMILY Safely read the leading-mode family label from one summary.

    label = '';
    if isfield(summary_k, 'leading_mode_family') && ~isempty(summary_k.leading_mode_family)
        label = summary_k.leading_mode_family;
    end
end

function local_write_summary_text(output_file, scan)
%LOCAL_WRITE_SUMMARY_TEXT Save one human-readable beta scan summary.

    fid = fopen(output_file, 'w');
    if fid == -1
        warning('run_beta_scan_v6:SummaryWrite', ...
            'Unable to write beta scan summary: %s', output_file);
        return;
    end
    cleanup_obj = onCleanup(@() fclose(fid)); %#ok<NASGU>

    fprintf(fid, 'Beta scan v6\n');
    fprintf(fid, 'scan_case: %s\n', scan.scan_case_name);
    fprintf(fid, 'benchmark_profile: %s\n', scan.benchmark_profile);
    fprintf(fid, 'run_part4: %d\n', scan.run_part4);
    fprintf(fid, '\n');
    for k = 1:numel(scan.cases)
        summary_k = scan.cases(k).summary;
        fprintf(fid, 'beta %d: %.6f\n', k, scan.cases(k).beta);
        fprintf(fid, '  stage: %s\n', summary_k.stage_completed);
        if strcmp(summary_k.stage_completed, 'Part4')
            fprintf(fid, '  leading_sigma: %+.6e%+.6ei\n', summary_k.leading_sigma_r, summary_k.leading_sigma_i);
            fprintf(fid, '  residual: %.6e\n', summary_k.leading_residual);
            fprintf(fid, '  bubble: %.6f\n', summary_k.leading_bubble_overlap);
            fprintf(fid, '  shock: %.6f\n', summary_k.leading_shock_energy_frac);
            fprintf(fid, '  checker: %.6f\n', summary_k.leading_checker_ratio);
            if isfield(summary_k, 'leading_mode_family')
                fprintf(fid, '  family: %s\n', summary_k.leading_mode_family);
            end
        end
        if k > 1
            fprintf(fid, '  corr_to_prev: %.6f\n', scan.branch_correlation_to_prev(k));
        end
        fprintf(fid, '\n');
    end
end

function token = local_fmt_num(value)
%LOCAL_FMT_NUM Convert one scalar into a filesystem-safe token.

    token = sprintf('%.4f', value);
    token = strrep(token, '-', 'm');
    token = strrep(token, '.', 'p');
end
