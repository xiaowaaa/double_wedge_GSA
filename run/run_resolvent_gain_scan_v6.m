function result = run_resolvent_gain_scan_v6(varargin)
%RUN_RESOLVENT_GAIN_SCAN_V6 Run a Part3-based resolvent-gain scan on the v6 operator.

    p = inputParser;
    p.FunctionName = 'run_resolvent_gain_scan_v6';
    addParameter(p, 'CaseName', 'resolvent_gain_scan_v6', @(x) ischar(x) || (isstring(x) && isscalar(x)));
    addParameter(p, 'ReuseExistingCase', false, @(x) islogical(x) || isnumeric(x));
    addParameter(p, 'SigmaList', [], @(x) isempty(x) || isnumeric(x));
    addParameter(p, 'OmegaList', [], @(x) isempty(x) || isnumeric(x));
    addParameter(p, 'GrowthRate', 0.0, @(x) isnumeric(x) && isscalar(x) && isfinite(x));
    addParameter(p, 'BaseflowFile', '', @(x) ischar(x) || (isstring(x) && isscalar(x)));
    addParameter(p, 'ExpectedDims', [270, 128], @(x) isnumeric(x) && numel(x) == 2);
    addParameter(p, 'StrideX', 1, @(x) isnumeric(x) && isscalar(x) && x >= 1);
    addParameter(p, 'StrideY', 1, @(x) isnumeric(x) && isscalar(x) && x >= 1);
    addParameter(p, 'TopType', 'inlet', @(x) ischar(x) || (isstring(x) && isscalar(x)));
    addParameter(p, 'BenchmarkProfile', 'sidharth2018_code_correction_v1', ...
        @(x) ischar(x) || (isstring(x) && isscalar(x)));
    addParameter(p, 'UseSponge', false, @(x) islogical(x) || isnumeric(x));
    addParameter(p, 'NEigs', 40, @(x) isnumeric(x) && isscalar(x) && x >= 1);
    addParameter(p, 'Beta', 0.0, @(x) isnumeric(x) && isscalar(x) && isfinite(x));
    addParameter(p, 'SigmaShift', 0.05 + 0.02i, @(x) isnumeric(x) && isscalar(x));
    addParameter(p, 'SigmaTriplet', [], @(x) isempty(x) || isnumeric(x));
    addParameter(p, 'KrylovDimensionFloor', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && x >= 8));
    addParameter(p, 'KrylovDimensionCap', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && x >= 8));
    addParameter(p, 'ForceLowMemoryDescriptor', false, @(x) islogical(x) || isnumeric(x));
    addParameter(p, 'Part3Variant', 'current_v6', @(x) ischar(x) || (isstring(x) && isscalar(x)));
    addParameter(p, 'UseSemiArtificialViscosity', [], @(x) isempty(x) || islogical(x) || isnumeric(x));
    addParameter(p, 'SavEpsilon', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && isfinite(x)));
    addParameter(p, 'UseShockSourceRegularization', [], @(x) isempty(x) || islogical(x) || isnumeric(x));
    addParameter(p, 'UsePressureRowRegularization', [], @(x) isempty(x) || islogical(x) || isnumeric(x));
    addParameter(p, 'EnableAdjointLeadDiagnostics', [], @(x) isempty(x) || islogical(x) || isnumeric(x));
    parse(p, varargin{:});

    paths = setup_double_wedge_paths();
    project_root = paths.project_root;

    sigma_list = p.Results.SigmaList(:).';
    if isempty(sigma_list)
        if isempty(p.Results.OmegaList)
            sigma_list = 1i * [0.01, 0.02, 0.04];
        else
            sigma_list = p.Results.GrowthRate + 1i * p.Results.OmegaList(:).';
        end
    end

    summary = run_user_test_baseflow_fullres_v6( ...
        'BaseflowFile', p.Results.BaseflowFile, ...
        'ExpectedDims', p.Results.ExpectedDims, ...
        'StrideX', p.Results.StrideX, ...
        'StrideY', p.Results.StrideY, ...
        'TopType', p.Results.TopType, ...
        'BenchmarkProfile', p.Results.BenchmarkProfile, ...
        'UseSponge', p.Results.UseSponge, ...
        'NEigs', p.Results.NEigs, ...
        'Beta', p.Results.Beta, ...
        'SigmaShift', p.Results.SigmaShift, ...
        'SigmaTriplet', p.Results.SigmaTriplet, ...
        'KrylovDimensionFloor', p.Results.KrylovDimensionFloor, ...
        'KrylovDimensionCap', p.Results.KrylovDimensionCap, ...
        'ForceLowMemoryDescriptor', p.Results.ForceLowMemoryDescriptor, ...
        'CaseName', p.Results.CaseName, ...
        'ReuseExistingCase', p.Results.ReuseExistingCase, ...
        'RunPart4', false, ...
        'Part3Variant', p.Results.Part3Variant, ...
        'UseSemiArtificialViscosity', p.Results.UseSemiArtificialViscosity, ...
        'SavEpsilon', p.Results.SavEpsilon, ...
        'UseShockSourceRegularization', p.Results.UseShockSourceRegularization, ...
        'UsePressureRowRegularization', p.Results.UsePressureRowRegularization, ...
        'EnableAdjointLeadDiagnostics', p.Results.EnableAdjointLeadDiagnostics);

    case_dir = summary.case_dir;
    part3 = load(fullfile(case_dir, 'Part3_Results.mat'));
    scan = compute_descriptor_resolvent_scan(part3.LNS_L, part3.LNS_Gam, part3, part3.Config, sigma_list);

    result = struct();
    result.case_dir = case_dir;
    result.baseflow_file = summary.baseflow_file;
    result.benchmark_profile = summary.benchmark_profile;
    result.beta = summary.beta;
    result.sigma_list = sigma_list;
    result.part3_summary = summary;
    result.scan = scan;
    result.summary_table = scan.summary_table;

    save(fullfile(case_dir, 'resolvent_gain_scan.mat'), 'result', '-v7.3');
    local_write_summary_text(fullfile(case_dir, 'resolvent_gain_scan.txt'), result);
end

function local_write_summary_text(output_file, result)
%LOCAL_WRITE_SUMMARY_TEXT Save one human-readable resolvent summary.

    fid = fopen(output_file, 'w');
    if fid == -1
        warning('run_resolvent_gain_scan_v6:SummaryWrite', ...
            'Unable to write resolvent summary file: %s', output_file);
        return;
    end
    cleanup_obj = onCleanup(@() fclose(fid)); %#ok<NASGU>

    fprintf(fid, 'Resolvent gain scan v6\n');
    fprintf(fid, 'case_dir: %s\n', result.case_dir);
    fprintf(fid, 'baseflow_file: %s\n', result.baseflow_file);
    fprintf(fid, 'benchmark_profile: %s\n', result.benchmark_profile);
    fprintf(fid, 'beta: %.6f\n', result.beta);
    fprintf(fid, '\n');
    for k = 1:numel(result.scan.entries)
        entry = result.scan.entries(k);
        fprintf(fid, 'sigma %d: %+.6e%+.6ei\n', k, real(entry.sigma), imag(entry.sigma));
        fprintf(fid, '  gain: %.6e\n', entry.gain);
        fprintf(fid, '  sigma_min: %.6e\n', entry.sigma_min);
        fprintf(fid, '  bubble: %.6f\n', entry.bubble_overlap);
        fprintf(fid, '  near_wall: %.6f\n', entry.near_wall_energy_frac);
        fprintf(fid, '  shock: %.6f\n', entry.shock_energy_frac);
        fprintf(fid, '  free_stream: %.6f\n', entry.free_stream_energy_frac);
        fprintf(fid, '  outlet_wall: %.6f\n', entry.outlet_wall_energy_frac);
        fprintf(fid, '  solver: %s\n', entry.solver);
        fprintf(fid, '\n');
    end
end
