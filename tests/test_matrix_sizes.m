function test_matrix_sizes(result_file)
%TEST_MATRIX_SIZES Validate sparse-matrix sizes on one reproducible Part3 result file.

    paths = setup_double_wedge_paths('IncludeTests', true);
    project_root = paths.project_root;
    if nargin < 1 || isempty(result_file)
        result_file = getenv('DOUBLE_WEDGE_TEST_PART3_RESULTS');
    end
    if nargin < 1 || isempty(result_file)
        result_file = local_ensure_default_result_file(project_root);
    end
    result_file = char(string(result_file));
    assert(exist(result_file, 'file') == 2, ...
        'Expected Part3 result file is missing: %s', result_file);

    data = load(result_file, 'LNS_L', 'LNS_Gam', 'Ndof');

    assert(issparse(data.LNS_L), 'LNS_L must be sparse.');
    assert(issparse(data.LNS_Gam), 'LNS_Gam must be sparse.');
    assert(isequal(size(data.LNS_L), [data.Ndof, data.Ndof]), ...
        'LNS_L must be Ndof-by-Ndof.');
    assert(isequal(size(data.LNS_Gam), [data.Ndof, data.Ndof]), ...
        'LNS_Gam must be Ndof-by-Ndof.');
    gamma_diag = spdiags(diag(data.LNS_Gam), 0, data.Ndof, data.Ndof);
    assert(nnz(data.LNS_Gam - gamma_diag) == 0, ...
        'LNS_Gam must remain diagonal even after BC rows are zeroed.');
    assert(nnz(data.LNS_Gam) <= data.Ndof, ...
        'LNS_Gam cannot have more than Ndof diagonal entries.');

    [~, ~, values_l] = find(data.LNS_L);
    [~, ~, values_g] = find(data.LNS_Gam);
    assert(~any(isnan(values_l(:))), 'LNS_L must not contain NaN.');
    assert(~any(isinf(values_l(:))), 'LNS_L must not contain Inf.');
    assert(~any(isnan(values_g(:))), 'LNS_Gam must not contain NaN.');
    assert(~any(isinf(values_g(:))), 'LNS_Gam must not contain Inf.');

    fprintf('[test_matrix_sizes] PASS\n');
end

function result_file = local_ensure_default_result_file(project_root)
%LOCAL_ENSURE_DEFAULT_RESULT_FILE Build or reuse one cheap Part3-only smoke artefact.

    case_name = 'test_run_user_test_part3_only_v6';
    case_dir = fullfile(project_root, 'outputs', 'mat', case_name);
    result_file = fullfile(case_dir, 'Part3_Results.mat');
    if exist(result_file, 'file') == 2
        return;
    end

    if exist(case_dir, 'dir') == 7
        rmdir(case_dir, 's');
    end

    run_user_test_baseflow_fullres_v6( ...
        'BaseflowFile', fullfile(project_root, 'double_wedge_baseflow.dat'), ...
        'ExpectedDims', [270, 128], ...
        'StrideX', 30, ...
        'StrideY', 20, ...
        'TopType', 'inlet', ...
        'RunPart4', false, ...
        'Part3Variant', 'current_v6', ...
        'UseSemiArtificialViscosity', false, ...
        'UseShockSourceRegularization', false, ...
        'UsePressureRowRegularization', false, ...
        'CaseName', case_name);
end
