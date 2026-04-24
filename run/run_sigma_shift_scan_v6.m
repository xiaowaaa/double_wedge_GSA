function scan = run_sigma_shift_scan_v6(varargin)
%RUN_SIGMA_SHIFT_SCAN_V6 Run a configurable sigma-shift scan on the v6 chain.

    p = inputParser;
    p.FunctionName = 'run_sigma_shift_scan_v6';
    addParameter(p, 'ScanCaseName', 'sigma_shift_scan_v6', @(x) ischar(x) || (isstring(x) && isscalar(x)));
    addParameter(p, 'SigmaShifts', 0.05 + 0.02i, @(x) isnumeric(x) && ~isempty(x));
    addParameter(p, 'LockSigmaTripletToShift', true, @(x) islogical(x) || isnumeric(x));
    addParameter(p, 'BaseflowFile', '', @(x) ischar(x) || (isstring(x) && isscalar(x)));
    addParameter(p, 'ExpectedDims', [270, 128], @(x) isnumeric(x) && numel(x) == 2);
    addParameter(p, 'StrideX', 1, @(x) isnumeric(x) && isscalar(x) && x >= 1);
    addParameter(p, 'StrideY', 1, @(x) isnumeric(x) && isscalar(x) && x >= 1);
    addParameter(p, 'TopType', 'inlet', @(x) ischar(x) || (isstring(x) && isscalar(x)));
    addParameter(p, 'BenchmarkProfile', 'sidharth2018_code_correction_v1', ...
        @(x) ischar(x) || (isstring(x) && isscalar(x)));
    addParameter(p, 'UseSponge', false, @(x) islogical(x) || isnumeric(x));
    addParameter(p, 'NEigs', 80, @(x) isnumeric(x) && isscalar(x) && x >= 1);
    addParameter(p, 'Beta', 0.0, @(x) isnumeric(x) && isscalar(x) && isfinite(x));
    addParameter(p, 'SigmaTriplet', [], @(x) isempty(x) || isnumeric(x));
    addParameter(p, 'KrylovDimensionFloor', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && x >= 8));
    addParameter(p, 'KrylovDimensionCap', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && x >= 8));
    addParameter(p, 'MachInf', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && isfinite(x) && x > 0));
    addParameter(p, 'ReInf', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && isfinite(x) && x > 0));
    addParameter(p, 'TInf', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && isfinite(x) && x > 0));
    addParameter(p, 'Gamma', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && isfinite(x) && x > 1.0));
    addParameter(p, 'Pr', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && isfinite(x) && x > 0));
    addParameter(p, 'WallModel', '', @(x) ischar(x) || (isstring(x) && isscalar(x)));
    addParameter(p, 'WallTemperature', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && isfinite(x) && x > 0));
    addParameter(p, 'ForceLowMemoryDescriptor', false, @(x) islogical(x) || isnumeric(x));
    addParameter(p, 'RunPart4', true, @(x) islogical(x) || isnumeric(x));
    addParameter(p, 'Part3Variant', 'current_v6', @(x) ischar(x) || (isstring(x) && isscalar(x)));
    addParameter(p, 'UseSemiArtificialViscosity', [], @(x) isempty(x) || islogical(x) || isnumeric(x));
    addParameter(p, 'SavEpsilon', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && isfinite(x)));
    addParameter(p, 'SavShockPercentile', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && isfinite(x)));
    addParameter(p, 'SavDilationSteps', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && x >= 0));
    addParameter(p, 'SavNearWallFraction', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && x >= 0));
    addParameter(p, 'UseShockSourceRegularization', [], @(x) isempty(x) || islogical(x) || isnumeric(x));
    addParameter(p, 'ShockClipPercentile', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && isfinite(x)));
    addParameter(p, 'ShockDmuClipPercentile', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && isfinite(x)));
    addParameter(p, 'ZeroSecondDerivativesInShock', [], @(x) isempty(x) || islogical(x) || isnumeric(x));
    addParameter(p, 'SuppressViscosityGradientTermsInShock', [], @(x) isempty(x) || islogical(x) || isnumeric(x));
    addParameter(p, 'UsePressureRowRegularization', [], @(x) isempty(x) || islogical(x) || isnumeric(x));
    addParameter(p, 'PressureGradientClipPercentile', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && isfinite(x)));
    addParameter(p, 'PressureDivergenceClipPercentile', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && isfinite(x)));
    addParameter(p, 'SuppressPressureGradientsInShock', [], @(x) isempty(x) || islogical(x) || isnumeric(x));
    addParameter(p, 'SuppressPressureDivergenceInShock', [], @(x) isempty(x) || islogical(x) || isnumeric(x));
    parse(p, varargin{:});

    paths = setup_double_wedge_paths();
    project_root = paths.project_root;

    scan_case_name = char(string(p.Results.ScanCaseName));
    scan_root_dir = fullfile(project_root, 'outputs', 'mat', scan_case_name);
    if exist(scan_root_dir, 'dir') ~= 7
        mkdir(scan_root_dir);
    end

    shifts = p.Results.SigmaShifts(:).';
    cases = repmat(struct( ...
        'shift', 0.0 + 0.0i, ...
        'case_name', '', ...
        'case_dir', '', ...
        'summary', struct()), numel(shifts), 1);

    for k = 1:numel(shifts)
        shift_value = shifts(k);
        case_leaf = local_case_leaf_name(k, shift_value);
        case_name = fullfile(scan_case_name, case_leaf);
        case_dir = fullfile(scan_root_dir, case_leaf);
        sigma_triplet = p.Results.SigmaTriplet;
        % Empty SigmaTriplet should preserve the Part1 default shift family.
        % Only force a one-shift solve when the caller explicitly asks for it.
        if logical(p.Results.LockSigmaTripletToShift)
            sigma_triplet = shift_value;
        end

        summary_k = run_user_test_baseflow_fullres_v6( ...
            'BaseflowFile', p.Results.BaseflowFile, ...
            'ExpectedDims', p.Results.ExpectedDims, ...
            'StrideX', p.Results.StrideX, ...
            'StrideY', p.Results.StrideY, ...
            'TopType', p.Results.TopType, ...
            'BenchmarkProfile', p.Results.BenchmarkProfile, ...
            'UseSponge', p.Results.UseSponge, ...
            'NEigs', p.Results.NEigs, ...
            'Beta', p.Results.Beta, ...
            'SigmaShift', shift_value, ...
            'SigmaTriplet', sigma_triplet, ...
            'KrylovDimensionFloor', p.Results.KrylovDimensionFloor, ...
            'KrylovDimensionCap', p.Results.KrylovDimensionCap, ...
            'MachInf', p.Results.MachInf, ...
            'ReInf', p.Results.ReInf, ...
            'TInf', p.Results.TInf, ...
            'Gamma', p.Results.Gamma, ...
            'Pr', p.Results.Pr, ...
            'WallModel', p.Results.WallModel, ...
            'WallTemperature', p.Results.WallTemperature, ...
            'ForceLowMemoryDescriptor', p.Results.ForceLowMemoryDescriptor, ...
            'CaseName', case_name, ...
            'ReuseExistingCase', false, ...
            'RunPart4', p.Results.RunPart4, ...
            'Part3Variant', p.Results.Part3Variant, ...
            'UseSemiArtificialViscosity', p.Results.UseSemiArtificialViscosity, ...
            'SavEpsilon', p.Results.SavEpsilon, ...
            'SavShockPercentile', p.Results.SavShockPercentile, ...
            'SavDilationSteps', p.Results.SavDilationSteps, ...
            'SavNearWallFraction', p.Results.SavNearWallFraction, ...
            'UseShockSourceRegularization', p.Results.UseShockSourceRegularization, ...
            'ShockClipPercentile', p.Results.ShockClipPercentile, ...
            'ShockDmuClipPercentile', p.Results.ShockDmuClipPercentile, ...
            'ZeroSecondDerivativesInShock', p.Results.ZeroSecondDerivativesInShock, ...
            'SuppressViscosityGradientTermsInShock', p.Results.SuppressViscosityGradientTermsInShock, ...
            'UsePressureRowRegularization', p.Results.UsePressureRowRegularization, ...
            'PressureGradientClipPercentile', p.Results.PressureGradientClipPercentile, ...
            'PressureDivergenceClipPercentile', p.Results.PressureDivergenceClipPercentile, ...
            'SuppressPressureGradientsInShock', p.Results.SuppressPressureGradientsInShock, ...
            'SuppressPressureDivergenceInShock', p.Results.SuppressPressureDivergenceInShock);

        cases(k).shift = shift_value;
        cases(k).case_name = case_name;
        cases(k).case_dir = case_dir;
        cases(k).summary = summary_k;
    end

    scan = struct();
    scan.scan_case_name = scan_case_name;
    scan.scan_root_dir = scan_root_dir;
    scan.shifts = shifts;
    scan.lock_sigma_triplet_to_shift = logical(p.Results.LockSigmaTripletToShift);
    scan.run_part4 = logical(p.Results.RunPart4);
    scan.part3_variant = char(string(p.Results.Part3Variant));
    scan.benchmark_profile = char(string(p.Results.BenchmarkProfile));
    scan.wall_model = local_resolve_wall_model_option(p.Results.WallModel);
    scan.cases = cases;
    scan.summary_table = local_build_summary_table(cases);

    save(fullfile(scan_root_dir, 'sigma_shift_scan_summary.mat'), 'scan', '-v7.3');
    local_write_summary_text(fullfile(scan_root_dir, 'sigma_shift_scan_summary.txt'), scan);
end

function case_leaf = local_case_leaf_name(k, shift_value)
%LOCAL_CASE_LEAF_NAME Build one stable folder name for a complex shift.

    case_leaf = sprintf('shift_%02d_sr_%s_si_%s', ...
        k, local_fmt_num(real(shift_value)), local_fmt_num(imag(shift_value)));
end

function token = local_fmt_num(value)
%LOCAL_FMT_NUM Convert one scalar into a filesystem-safe token.

    token = sprintf('%.4f', value);
    token = strrep(token, '-', 'm');
    token = strrep(token, '.', 'p');
end

function summary_table = local_build_summary_table(cases)
%LOCAL_BUILD_SUMMARY_TABLE Convert scan cases into one compact comparison table.

    n = numel(cases);
    shift = zeros(n, 1);
    stage = strings(n, 1);
    sigma_r = nan(n, 1);
    sigma_i = nan(n, 1);
    residual = nan(n, 1);
    bubble = nan(n, 1);
    near_wall = nan(n, 1);
    shock = nan(n, 1);
    checker = nan(n, 1);
    row_ratio = nan(n, 1);
    pressure_clip = nan(n, 1);

    for k = 1:n
        shift(k) = cases(k).shift;
        summary_k = cases(k).summary;
        stage(k) = string(summary_k.stage_completed);
        if strcmp(summary_k.stage_completed, 'Part4')
            sigma_r(k) = summary_k.leading_sigma_r;
            sigma_i(k) = summary_k.leading_sigma_i;
            residual(k) = summary_k.leading_residual;
            bubble(k) = summary_k.leading_bubble_overlap;
            near_wall(k) = summary_k.leading_near_wall_energy_frac;
            shock(k) = summary_k.leading_shock_energy_frac;
            checker(k) = summary_k.leading_checker_ratio;
        else
            row_ratio(k) = summary_k.operator_health.row_ratio_before;
            pressure_clip(k) = summary_k.pressure_row_audit.total_clipped;
        end
    end

    summary_table = table(shift, stage, sigma_r, sigma_i, residual, bubble, near_wall, ...
        shock, checker, row_ratio, pressure_clip);
end

function local_write_summary_text(output_file, scan)
%LOCAL_WRITE_SUMMARY_TEXT Write a compact comparison text file next to the scan outputs.

    fid = open_output_text_file(output_file);
    if fid == -1
        warning('run_sigma_shift_scan_v6:SummaryWrite', ...
            'Unable to write scan summary: %s', output_file);
        return;
    end

    cleanup_obj = onCleanup(@() fclose(fid)); %#ok<NASGU>

    fprintf(fid, '%s\n', localize_output_label('Sigma-shift scan v6'));
    fprintf(fid, '%s: %s\n', localize_output_label('scan_case'), scan.scan_case_name);
    fprintf(fid, '%s: %s\n', localize_output_label('benchmark_profile'), scan.benchmark_profile);
    fprintf(fid, '%s: %s\n', localize_output_label('wall_model'), scan.wall_model);
    fprintf(fid, '%s: %d\n', localize_output_label('run_part4'), scan.run_part4);
    fprintf(fid, '%s: %s\n', localize_output_label('part3_variant'), scan.part3_variant);
    fprintf(fid, '\n');
    for k = 1:numel(scan.cases)
        summary_k = scan.cases(k).summary;
        fprintf(fid, 'shift %d: %+.6f%+.6fi\n', k, real(scan.cases(k).shift), imag(scan.cases(k).shift));
        fprintf(fid, '  %s: %s\n', localize_output_label('case_dir'), scan.cases(k).case_dir);
        fprintf(fid, '  %s: %s\n', localize_output_label('stage'), summary_k.stage_completed);
        if strcmp(summary_k.stage_completed, 'Part4')
            fprintf(fid, '  %s: %+.6e%+.6ei\n', localize_output_label('leading_sigma'), summary_k.leading_sigma_r, summary_k.leading_sigma_i);
            fprintf(fid, '  %s: %.6e\n', localize_output_label('leading_residual'), summary_k.leading_residual);
            fprintf(fid, '  %s: %.6f\n', localize_output_label('bubble'), summary_k.leading_bubble_overlap);
            fprintf(fid, '  %s: %.6f\n', localize_output_label('near_wall'), summary_k.leading_near_wall_energy_frac);
            fprintf(fid, '  %s: %.6f\n', localize_output_label('shock'), summary_k.leading_shock_energy_frac);
            fprintf(fid, '  %s: %.6f\n', localize_output_label('checker'), summary_k.leading_checker_ratio);
        else
            fprintf(fid, '  %s: %.6e\n', localize_output_label('row_ratio_before'), summary_k.operator_health.row_ratio_before);
            fprintf(fid, '  %s: %.6f\n', localize_output_label('shock_coverage'), summary_k.shock_info.coverage_fraction);
            fprintf(fid, '  %s: %d\n', localize_output_label('pressure_clip'), summary_k.pressure_row_audit.total_clipped);
        end
        fprintf(fid, '\n');
    end
end

function wall_model = local_resolve_wall_model_option(override_value)
%LOCAL_RESOLVE_WALL_MODEL_OPTION Resolve one wall-model option with defaults.

    if strlength(string(override_value)) == 0
        wall_model = 'adiabatic';
    else
        wall_model = char(string(override_value));
    end
    wall_model = normalize_wall_model(wall_model, ...
        'ErrorIdentifier', 'run_sigma_shift_scan_v6:WallModel');
end
