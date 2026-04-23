function paths = setup_double_wedge_paths(varargin)
%SETUP_DOUBLE_WEDGE_PATHS Add the canonical project paths once.
%   PATHS = SETUP_DOUBLE_WEDGE_PATHS() adds the project root, run, and
%   src/core folders to the MATLAB path and returns their absolute paths.

    p = inputParser;
    p.FunctionName = 'setup_double_wedge_paths';
    addParameter(p, 'IncludeTests', false, @(x) islogical(x) && isscalar(x));
    addParameter(p, 'StartDir', '', @(x) ischar(x) || (isstring(x) && isscalar(x)));
    parse(p, varargin{:});

    project_root = local_resolve_project_root(char(string(p.Results.StartDir)));
    paths = struct();
    paths.project_root = project_root;
    paths.run_dir = fullfile(project_root, 'run');
    paths.core_dir = fullfile(project_root, 'src', 'core');
    paths.tests_dir = fullfile(project_root, 'tests');

    local_prioritize_path(paths.project_root);
    local_prioritize_path(paths.run_dir);
    local_prioritize_path(paths.core_dir);
    if p.Results.IncludeTests
        local_prioritize_path(paths.tests_dir);
    end
end

function project_root = local_find_project_root(start_dir)
%LOCAL_FIND_PROJECT_ROOT Walk upward until the repo root is found.

    current_dir = start_dir;
    while true
        has_legacy_main = exist(fullfile(current_dir, 'main_double_wedge_part3.m'), 'file') == 2;
        has_v6_main = exist(fullfile(current_dir, 'Main_DoubleWedge_Part3_v6.m'), 'file') == 2;
        has_core = exist(fullfile(current_dir, 'src', 'core'), 'dir') == 7;
        if (has_legacy_main || has_v6_main) && has_core
            project_root = current_dir;
            return;
        end

        parent_dir = fileparts(current_dir);
        if strcmp(parent_dir, current_dir)
            error('setup_double_wedge_paths:ProjectRoot', ...
                'Unable to locate the double-wedge project root from %s.', start_dir);
        end
        current_dir = parent_dir;
    end
end

function project_root = local_resolve_project_root(requested_start_dir)
%LOCAL_RESOLVE_PROJECT_ROOT Prefer an explicit or current-workspace root before helper-path fallbacks.

    candidate_dirs = {};
    if ~isempty(requested_start_dir)
        candidate_dirs{end + 1} = requested_start_dir; %#ok<AGROW>
    else
        candidate_dirs{end + 1} = pwd; %#ok<AGROW>
        helper_path = mfilename('fullpath');
        if ~isempty(helper_path)
            candidate_dirs{end + 1} = fileparts(helper_path); %#ok<AGROW>
        end
    end

    for k = 1:numel(candidate_dirs)
        project_root = local_try_find_project_root(candidate_dirs{k});
        if ~isempty(project_root)
            return;
        end
    end

    if isempty(requested_start_dir)
        error('setup_double_wedge_paths:ProjectRoot', ...
            'Unable to locate the double-wedge project root from pwd=%s.', pwd);
    end
    error('setup_double_wedge_paths:ProjectRoot', ...
        'Unable to locate the double-wedge project root from %s.', requested_start_dir);
end

function project_root = local_try_find_project_root(start_dir)
%LOCAL_TRY_FIND_PROJECT_ROOT Return one discovered project root or an empty string.

    try
        project_root = local_find_project_root(start_dir);
    catch ME
        if strcmp(ME.identifier, 'setup_double_wedge_paths:ProjectRoot')
            project_root = '';
        else
            rethrow(ME);
        end
    end
end

function local_prioritize_path(path_value)
%LOCAL_PRIORITIZE_PATH Move one canonical path to the front of the MATLAB path.

    path_value = char(string(path_value));
    if isempty(path_value)
        return;
    end

    current_entries = strsplit(path, pathsep);
    target_key = local_canonical_path(path_value);
    remove_entries = {};
    for k = 1:numel(current_entries)
        entry = current_entries{k};
        if isempty(entry)
            continue;
        end
        if strcmpi(local_canonical_path(entry), target_key)
            remove_entries{end + 1} = entry; %#ok<AGROW>
        end
    end

    if ~isempty(remove_entries)
        rmpath(remove_entries{:});
    end
    addpath(path_value, '-begin');
end

function key = local_canonical_path(path_value)
%LOCAL_CANONICAL_PATH Normalize one path for precedence comparisons.

    key = char(string(path_value));
    if isempty(key)
        return;
    end

    try
        key = char(java.io.File(key).getCanonicalPath());
    catch
        % Keep the original path when canonicalization fails.
    end
    key = lower(strrep(key, '/', filesep));
end
