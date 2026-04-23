function suite = run_paperA_validation_suite(varargin)
%RUN_PAPERA_VALIDATION_SUITE Run the retained unit tests and the 270x128 structural benchmark.

    p = inputParser;
    p.FunctionName = 'run_paperA_validation_suite';
    addParameter(p, 'RunBenchmark', true, @(x) islogical(x) || isnumeric(x));
    addParameter(p, 'BaseflowFile', '', @(x) ischar(x) || (isstring(x) && isscalar(x)));
    addParameter(p, 'CaseName', 'paperA_validation_270x128_v6', @(x) ischar(x) || (isstring(x) && isscalar(x)));
    addParameter(p, 'BenchmarkProfile', 'sidharth2018_code_correction_v1', ...
        @(x) ischar(x) || (isstring(x) && isscalar(x)));
    parse(p, varargin{:});

    setup_double_wedge_paths('IncludeTests', true);

    run_phase2_validation;

    suite = struct();
    suite.tests_passed = true;
    suite.case_summary = [];
    if logical(p.Results.RunBenchmark)
        suite.case_summary = run_user_test_baseflow_fullres_v6( ...
            'BaseflowFile', char(string(p.Results.BaseflowFile)), ...
            'CaseName', char(string(p.Results.CaseName)), ...
            'BenchmarkProfile', char(string(p.Results.BenchmarkProfile)));
    end
end
