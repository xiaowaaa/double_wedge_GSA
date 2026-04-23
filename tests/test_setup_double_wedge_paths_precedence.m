function test_setup_double_wedge_paths_precedence()
%TEST_SETUP_DOUBLE_WEDGE_PATHS_PRECEDENCE Ensure the active workspace wins over stale path entries.

    paths = setup_double_wedge_paths('IncludeTests', true);
    project_root = paths.project_root;
    run_dir = fullfile(project_root, 'run');
    core_dir = fullfile(project_root, 'src', 'core');
    tests_dir = fullfile(project_root, 'tests');

    fixture = local_create_shadow_fixture();
    fixture_root = fixture.root_dir;
    fixture_run_dir = fixture.run_dir;
    fixture_core_dir = fixture.core_dir;
    cleanup_fixture = onCleanup(@() local_remove_shadow_fixture(fixture_root)); %#ok<NASGU>

    setup_fn = @setup_double_wedge_paths;
    old_path = path;
    cleanup_obj = onCleanup(@() path(old_path)); %#ok<NASGU>

    restoredefaultpath;
    addpath(fixture_root, '-begin');
    addpath(fixture_run_dir, '-begin');
    addpath(fixture_core_dir, '-begin');
    addpath(project_root, '-end');
    addpath(run_dir, '-end');
    addpath(core_dir, '-end');
    addpath(tests_dir, '-end');

    stale_runner = which('run_user_test_baseflow_fullres_v6');
    assert(strcmpi(stale_runner, fullfile(fixture_run_dir, 'run_user_test_baseflow_fullres_v6.m')), ...
        'The test precondition requires the stale fixture runner to win before setup reprioritizes the path.');

    resolved_paths = setup_fn('StartDir', project_root, 'IncludeTests', true);
    assert(strcmpi(resolved_paths.project_root, project_root), ...
        'setup_double_wedge_paths should resolve the requested project root exactly.');
    assert(strcmpi(which('run_user_test_baseflow_fullres_v6'), ...
        fullfile(run_dir, 'run_user_test_baseflow_fullres_v6.m')), ...
        'The configurable runner should resolve to the active workspace after setup.');
    assert(strcmpi(which('run_phase2_validation'), ...
        fullfile(run_dir, 'run_phase2_validation.m')), ...
        'The validation driver should resolve to the active workspace after setup.');
    assert(strcmpi(which('setup_double_wedge_paths'), ...
        fullfile(project_root, 'setup_double_wedge_paths.m')), ...
        'The setup helper itself should resolve to the active workspace after reprioritization.');

    fprintf('[test_setup_double_wedge_paths_precedence] PASS\n');
end

function fixture = local_create_shadow_fixture()
%LOCAL_CREATE_SHADOW_FIXTURE Create one temporary stale-copy fixture tree.

    fixture_root = tempname();
    fixture_run_dir = fullfile(fixture_root, 'run');
    fixture_core_dir = fullfile(fixture_root, 'src', 'core');

    mkdir(fixture_root);
    mkdir(fixture_run_dir);
    mkdir(fixture_core_dir);

    local_write_function(fullfile(fixture_root, 'setup_double_wedge_paths.m'), {
        'function varargout = setup_double_wedge_paths(varargin)'
        '%SETUP_DOUBLE_WEDGE_PATHS Stale fixture used only for path-precedence testing.'
        'error(''staleFixture:ShouldNotRun'', ...'
        '    ''The stale setup_double_wedge_paths fixture should never execute.'');'
        'end'});

    local_write_function(fullfile(fixture_run_dir, 'run_user_test_baseflow_fullres_v6.m'), {
        'function varargout = run_user_test_baseflow_fullres_v6(varargin)'
        '%RUN_USER_TEST_BASEFLOW_FULLRES_V6 Stale fixture used only for path precedence.'
        'error(''staleFixture:ShouldNotRun'', ...'
        '    ''The stale run_user_test_baseflow_fullres_v6 fixture should never execute.'');'
        'end'});

    local_write_function(fullfile(fixture_run_dir, 'run_phase2_validation.m'), {
        'function run_phase2_validation(varargin)'
        '%RUN_PHASE2_VALIDATION Stale fixture used only for path precedence.'
        'error(''staleFixture:ShouldNotRun'', ...'
        '    ''The stale run_phase2_validation fixture should never execute.'');'
        'end'});

    fixture = struct();
    fixture.root_dir = fixture_root;
    fixture.run_dir = fixture_run_dir;
    fixture.core_dir = fixture_core_dir;
end

function local_write_function(file_path, lines)
%LOCAL_WRITE_FUNCTION Write one tiny MATLAB fixture file.

    fid = fopen(file_path, 'w');
    assert(fid ~= -1, 'Unable to create fixture file: %s', file_path);
    cleanup_obj = onCleanup(@() fclose(fid)); %#ok<NASGU>

    for k = 1:numel(lines)
        fprintf(fid, '%s\n', lines{k});
    end
end

function local_remove_shadow_fixture(fixture_root)
%LOCAL_REMOVE_SHADOW_FIXTURE Best-effort cleanup for the temporary fixture tree.

    if exist(fixture_root, 'dir') == 7
        local_try_rmpath(fullfile(fixture_root, 'run'));
        local_try_rmpath(fullfile(fixture_root, 'src', 'core'));
        local_try_rmpath(fixture_root);
        rmdir(fixture_root, 's');
    end
end

function local_try_rmpath(path_value)
%LOCAL_TRY_RMPATH Remove one path entry when it is still active.

    if exist(path_value, 'dir') == 7 && contains(path, path_value)
        rmpath(path_value);
    end
end
