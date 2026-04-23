function cfg = config_case()
%CONFIG_CASE Return the default modular double-wedge configuration.

    cfg = struct();

    paths = setup_double_wedge_paths();
    project_root = paths.project_root;
    output_root = fullfile(project_root, 'outputs');

    cfg.io = struct();
    cfg.io.baseflow_file = fullfile(project_root, 'double_wedge_baseflow.dat');
    cfg.io.boundary_file = '';
    cfg.io.output_root = output_root;
    cfg.io.figure_dir = fullfile(output_root, 'figs');
    cfg.io.mat_dir = fullfile(output_root, 'mat');
    cfg.io.log_dir = fullfile(output_root, 'logs');

    cfg.reader = struct();
    cfg.reader.expected_dims = [];
    cfg.reader.stride_x = 2;
    cfg.reader.stride_y = 2;
    cfg.reader.n_expected_vars = 12;
    cfg.reader.n_header_hint = 20;
    cfg.reader.remove_duplicate_terminal_lines = true;

    cfg.flow = struct();
    cfg.flow.Ma_inf = 7.0;
    cfg.flow.Re_inf = 1.0e5;
    cfg.flow.T_inf = 191.0;
    cfg.flow.gamma = 1.4;
    cfg.flow.Pr = 0.71;
    cfg.flow.Cv = 1.0 / (cfg.flow.gamma * (cfg.flow.gamma - 1.0) * cfg.flow.Ma_inf^2);
    cfg.flow.Sutherland_nd = 110.4 / cfg.flow.T_inf;
    cfg.flow.T_wall = 298.0;

    cfg.geometry = struct();
    cfg.geometry.x_hinge = 0.0;

    cfg.bc = struct();
    cfg.bc.bottom_type = 'mixed_symmetry_wall';
    cfg.bc.top_type = 'inlet';
    cfg.bc.left_type = 'inlet';
    cfg.bc.right_type = 'outlet';

    cfg.plot = struct();
    cfg.plot.boundary_audit_name = 'grid_boundary_audit.png';
    cfg.plot.visible = 'off';

    cfg.benchmark = get_double_wedge_benchmark_profile('sidharth2018_code_correction_v1');
end
