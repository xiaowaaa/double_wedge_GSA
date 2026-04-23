function test_read_phenglei_headerless_infer_num_vars()
%TEST_READ_PHENGLEI_HEADERLESS_INFER_NUM_VARS Infer column count from I*J.

    project_root = fileparts(fileparts(mfilename('fullpath')));
    addpath(fullfile(project_root, 'run'));
    addpath(fullfile(project_root, 'src', 'core'));

    temp_root = tempname;
    mkdir(temp_root);
    cleanup_obj = onCleanup(@() local_cleanup_temp_root(temp_root)); %#ok<NASGU>

    data_file = fullfile(temp_root, 'synthetic_headerless_12col.dat');
    figure_dir = fullfile(temp_root, 'figs');
    local_write_headerless_file(data_file);

    cfg = config_case();
    cfg.io.baseflow_file = data_file;
    cfg.io.boundary_file = '';
    cfg.io.output_root = temp_root;
    cfg.io.figure_dir = figure_dir;
    cfg.io.mat_dir = fullfile(temp_root, 'mat');
    cfg.io.log_dir = fullfile(temp_root, 'logs');
    cfg.reader.expected_dims = [2, 2];
    cfg.reader.stride_x = 1;
    cfg.reader.stride_y = 1;
    cfg.reader.n_expected_vars = 12;
    cfg.reader.remove_duplicate_terminal_lines = false;

    base = read_phenglei_baseflow(cfg);

    assert(base.metadata.using_headerless_fallback, ...
        'The headerless file should use the expected_dims fallback.');
    assert(base.metadata.num_vars_read == 12, ...
        'The reader should infer the true 12-column layout.');
    assert(base.metadata.gamma_column_present, ...
        'The twelfth PHengLEI column should be preserved as gama/gamma_local.');
    assert(base.metadata.num_optional_standard_vars == 1, ...
        'The twelfth standard PHengLEI column should be tracked as an optional standard field.');
    assert(base.metadata.num_extra_vars == 0, ...
        'A standard 12-column PHengLEI file should not be treated as having extra columns.');
    assert(base.Nx == 2 && base.Ny == 2, ...
        'Stride-1 read should preserve the raw 2x2 dimensions.');
    assert(abs(base.cp(2, 2) - 0.4) < 1.0e-12, ...
        'The required first 11 columns were not mapped correctly.');
    assert(abs(base.gama(2, 2) - 1.40) < 1.0e-12, ...
        'The twelfth PHengLEI column should be mapped into base.gama.');
    assert(exist(fullfile(figure_dir, cfg.plot.boundary_audit_name), 'file') == 2, ...
        'Boundary-audit figure was not written for the headerless test case.');

    fprintf('[test_read_phenglei_headerless_infer_num_vars] PASS\n');
end

function local_write_headerless_file(path_name)
%LOCAL_WRITE_HEADERLESS_FILE Create a tiny 12-column POINT-style sample.

    lines = { ...
        '-1.0 0.0 0.0 1.0 10.0 0.0 0.0 100.0 300.0 5.0 0.1 1.40'; ...
        ' 1.0 0.0 0.0 1.1 11.0 0.1 0.0 101.0 301.0 5.1 0.2 1.40'; ...
        '-1.0 1.0 0.0 1.2 12.0 0.2 0.0 102.0 302.0 5.2 0.3 1.40'; ...
        ' 1.0 1.0 0.0 1.3 13.0 0.3 0.0 103.0 303.0 5.3 0.4 1.40' ...
        };

    fid = fopen(path_name, 'w');
    if fid == -1
        error('test_read_phenglei_headerless_infer_num_vars:IO', ...
            'Unable to create temporary data file: %s', path_name);
    end
    cleanup_obj = onCleanup(@() fclose(fid)); %#ok<NASGU>
    fprintf(fid, '%s\n', lines{:});
end

function local_cleanup_temp_root(temp_root)
%LOCAL_CLEANUP_TEMP_ROOT Remove the temporary test workspace.

    if exist(temp_root, 'dir') == 7
        rmdir(temp_root, 's');
    end
end
