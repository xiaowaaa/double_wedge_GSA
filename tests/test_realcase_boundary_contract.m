function test_realcase_boundary_contract()
%TEST_REALCASE_BOUNDARY_CONTRACT Validate the north-edge contract with side-owned corners.

    project_root = fileparts(fileparts(mfilename('fullpath')));
    addpath(project_root);
    addpath(fullfile(project_root, 'src', 'core'));

    [X, Y] = meshgrid(linspace(-1.0, 1.0, 6), linspace(0.0, 1.0, 4));
    cfg = struct();
    cfg.bc = struct('top_type', 'inlet');
    cfg.flow = struct('Ma_inf', 7.0, 'Re_inf', 1.0e5, 'T_inf', 191.0, 'gamma', 1.4, 'Pr', 0.71);
    cfg.geometry = struct('x_hinge', 0.0);
    cfg.io = struct('baseflow_file', 'synthetic.dat');

    legacy_cfg = struct();
    legacy_cfg.Ma_inf = cfg.flow.Ma_inf;
    legacy_cfg.Re_inf = cfg.flow.Re_inf;
    legacy_cfg.T_inf = cfg.flow.T_inf;
    legacy_cfg.gamma = cfg.flow.gamma;
    legacy_cfg.Pr = cfg.flow.Pr;
    legacy_cfg.x_hinge = cfg.geometry.x_hinge;
    legacy_cfg.n_eigs = 10;
    legacy_cfg.datafile = cfg.io.baseflow_file;
    legacy_cfg.boundary_map = struct( ...
        'south', 'mixed_symmetry_wall', ...
        'north', 'inlet', ...
        'west', 'inlet', ...
        'east', 'outlet');

    [masks, counts] = build_boundary_masks(X, Y, legacy_cfg, 'Verbose', false);
    base = struct();
    base.raw = struct('x', X, 'y', Y);
    base.x = X;
    base.y = Y;
    base.Nx = size(X, 2);
    base.Ny = size(X, 1);
    base.boundary = struct('masks', masks, 'counts', counts.counts, 'top_type', 'inlet');
    base.validation = struct('bottom_split_ok', true);

    contract = struct('case_tag', 'synthetic_realcase', 'expected_dims', [size(X, 2), size(X, 1)], 'top_type', 'inlet');
    report = assert_realcase_boundary_contract(base, cfg, contract);
    assert(report.north_counts.total == size(X, 2) - 2, ...
        'The north-edge contract should exclude the side-owned top corners.');
    assert(report.north_counts.inlet == report.north_counts.total, ...
        'All remaining north-edge nodes should satisfy the inlet contract.');

    bad_masks = masks;
    bad_masks.inlet(end, 3) = false;
    bad_masks.outlet(end, 3) = true;
    base.boundary.masks = bad_masks;
    try
        assert_realcase_boundary_contract(base, cfg, contract);
        error('test_realcase_boundary_contract:MissingFailure', ...
            'A mislabeled north-edge interior node should fail the contract.');
    catch ME
        assert(strcmp(ME.identifier, 'assert_realcase_boundary_contract:NorthLabel'), ...
            'The contract should fail specifically on the north-edge label check.');
    end

    fprintf('[test_realcase_boundary_contract] PASS\n');
end
