function test_part2_mass_continuity_audit()
%TEST_PART2_MASS_CONTINUITY_AUDIT Verify that Part2 tracks compressible mass continuity.

    project_root = fileparts(fileparts(mfilename('fullpath')));
    addpath(project_root);
    addpath(fullfile(project_root, 'run'));
    addpath(fullfile(project_root, 'src', 'core'));

    Nx = 11;
    Ny = 9;
    [X, Y] = meshgrid(linspace(0.0, 1.0, Nx), linspace(0.0, 0.3, Ny)); %#ok<ASGLU>
    alpha = 0.4;

    U = exp(alpha * X);
    V = zeros(Ny, Nx);
    RHO = exp(-alpha * X);

    dX = struct();
    dX.ux = alpha * exp(alpha * X);
    dX.vy = zeros(Ny, Nx);
    dX.rhox = -alpha * exp(-alpha * X);
    dX.rhoy = zeros(Ny, Nx);
    dX.div = dX.ux + dX.vy;

    cfg = config_case();
    cfg.reader.expected_dims = [Nx, Ny];
    cfg.reader.stride_x = 1;
    cfg.reader.stride_y = 1;
    cfg.boundary_map = struct('south', 'mixed_symmetry_wall', 'north', 'inlet', ...
        'west', 'inlet', 'east', 'outlet');
    cfg.x_hinge = cfg.geometry.x_hinge;

    [BoundaryMasks, ~] = build_boundary_masks(X, Y, cfg, 'Verbose', false);
    BaseValidation = struct('eos_relative_error', 0.0, ...
        'wall_temperature_relative_mismatch', 0.0, 'bottom_split_ok', true);

    [audit, ~, ~] = build_paperA_baseflow_context( ...
        X, Y, U, V, RHO, dX, BoundaryMasks, cfg, BaseValidation);

    assert(audit.divergence_proxy_max > 1.0e-1, ...
        'The manufactured field should have a nonzero ux+vy proxy.');
    assert(audit.mass_continuity_residual_max < 1.0e-12, ...
        'The manufactured field should satisfy compressible mass continuity exactly.');
    assert(audit.mass_continuity_relative_max < 1.0e-12, ...
        'The normalized mass-continuity residual should stay near zero.');
    assert(abs(audit.continuity_residual_max - audit.mass_continuity_relative_max) < 1.0e-14, ...
        'continuity_residual_max should now alias the normalized mass-continuity metric.');

    fprintf('[test_part2_mass_continuity_audit] PASS\n');
end
