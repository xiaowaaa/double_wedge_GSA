function test_boundary_masks()
%TEST_BOUNDARY_MASKS Validate explicit structured-edge boundary masks.

    project_root = fileparts(fileparts(mfilename('fullpath')));
    addpath(project_root);
    addpath(fullfile(project_root, 'src', 'core'));

    x_line = [-1.0, -0.5, 0.0, 0.5, 1.0];
    y_line = [0.0; 0.5; 1.0; 1.5];
    X = repmat(x_line, numel(y_line), 1);
    Y = repmat(y_line, 1, numel(x_line));

    config = struct();
    config.Ma_inf = 7.0;
    config.Re_inf = 1.0e5;
    config.T_inf = 191.0;
    config.gamma = 1.4;
    config.Pr = 0.71;
    config.x_hinge = 0.0;
    config.n_eigs = 10;
    config.datafile = 'double_wedge_baseflow.dat';
    config.boundary_map = struct( ...
        'south', 'mixed_symmetry_wall', ...
        'north', 'farfield', ...
        'west', 'inlet', ...
        'east', 'outlet');

    [mask, info] = build_boundary_masks(X, Y, config, 'Verbose', false);

    label_sum = double(mask.inlet) + double(mask.outlet) + ...
        double(mask.farfield) + double(mask.wall) + double(mask.symmetry);

    assert(all(label_sum(mask.outer) == 1), 'Each outer node must have exactly one label.');
    assert(all(label_sum(~mask.outer) == 0), 'Inner nodes must not be labeled.');

    assert(info.counts.symmetry == 2, 'Expected 2 symmetry nodes on the south edge.');
    assert(info.counts.wall == 3, 'Expected 3 wall nodes on the south edge.');
    assert(info.counts.inlet == 3, 'Expected 3 inlet nodes after corner ownership resolution.');
    assert(info.counts.outlet == 3, 'Expected 3 outlet nodes after corner ownership resolution.');
    assert(info.counts.farfield == 3, 'Expected 3 farfield nodes after corner ownership resolution.');

    assert(mask.symmetry(1, 1), 'Bottom-left corner should belong to the south edge.');
    assert(mask.wall(1, end), 'Bottom-right corner should belong to the south edge.');
    assert(mask.inlet(end, 1), 'Top-left corner should belong to the inlet.');
    assert(mask.outlet(end, end), 'Top-right corner should belong to the outlet.');
    assert(~mask.farfield(end, 1), 'Top-left corner must not be double-labeled as farfield.');
    assert(~mask.farfield(end, end), 'Top-right corner must not be double-labeled as farfield.');

    fprintf('[test_boundary_masks] PASS\n');
end
