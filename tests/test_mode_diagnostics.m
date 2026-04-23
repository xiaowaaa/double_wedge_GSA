function test_mode_diagnostics()
%TEST_MODE_DIAGNOSTICS Validate primitive-five boundary/checkerboard diagnostics.

    project_root = fileparts(fileparts(mfilename('fullpath')));
    addpath(fullfile(project_root, 'src', 'core'));

    Ny = 40;
    Nx = 40;
    layout = get_state_layout_info('primitive5_u_v_w_T_p');

    [X, Y] = meshgrid(1:Nx, 1:Ny);
    checker_field = (-1) .^ (X + Y);
    smooth_field = exp(-((X - 20.0).^2 + (Y - 16.0).^2) / 30.0);
    top_field = exp(-((X - 30.0).^2 + (Y - 36.0).^2) / 12.0);
    low_field = exp(-((X - 18.0).^2 + (Y - 9.0).^2) / 12.0);

    boundary_mask = false(Ny, Nx);
    boundary_mask(1, :) = true;
    boundary_mask(end, :) = true;
    boundary_mask(:, 1) = true;
    boundary_mask(:, end) = true;
    farfield_mask = false(Ny, Nx);
    farfield_mask(end, :) = true;

    q_checker = zeros(layout.nvar * Ny * Nx, 1);
    q_smooth = zeros(layout.nvar * Ny * Nx, 1);
    q_top = zeros(layout.nvar * Ny * Nx, 1);
    q_low = zeros(layout.nvar * Ny * Nx, 1);

    q_checker(layout.components.u:layout.nvar:end) = checker_field(:);
    q_smooth(layout.components.u:layout.nvar:end) = smooth_field(:);
    q_top(layout.components.u:layout.nvar:end) = top_field(:);
    q_low(layout.components.u:layout.nvar:end) = low_field(:);

    diag_checker = compute_mode_diagnostics(q_checker, Ny, Nx, ...
        'BoundaryMask', boundary_mask, ...
        'FarfieldMask', farfield_mask, ...
        'StateLayout', layout.name);
    diag_smooth = compute_mode_diagnostics(q_smooth, Ny, Nx, ...
        'BoundaryMask', boundary_mask, ...
        'FarfieldMask', farfield_mask, ...
        'StateLayout', layout.name);
    diag_top = compute_mode_diagnostics(q_top, Ny, Nx, ...
        'BoundaryMask', boundary_mask, ...
        'FarfieldMask', farfield_mask, ...
        'StateLayout', layout.name);
    diag_low = compute_mode_diagnostics(q_low, Ny, Nx, ...
        'BoundaryMask', boundary_mask, ...
        'FarfieldMask', farfield_mask, ...
        'StateLayout', layout.name);

    assert(diag_checker.checker_u > diag_smooth.checker_u, ...
        'Primitive5 checkerboard mode should have a larger checker diagnostic.');
    assert(diag_checker.highfreq_u > diag_smooth.highfreq_u, ...
        'Primitive5 checkerboard mode should have a larger high-frequency diagnostic.');
    assert(diag_top.farfield_energy_ratio > diag_low.farfield_energy_ratio, ...
        'Primitive5 top-localized mode should have a larger farfield-band energy ratio.');
    assert(isnan(diag_checker.peak_rho), ...
        'Primitive5 diagnostics should report NaN for an absent rho component.');

    % Wall-distance diagnostics must be measured relative to the local south edge.
    Y_tilt = Y;
    for ii = 1:Nx
        Y_tilt(:, ii) = linspace(10 + 0.6 * (ii - 1), 110 + 0.6 * (ii - 1), Ny).';
    end
    X_tilt = X;
    q_wall_attached = zeros(layout.nvar * Ny * Nx, 1);
    wall_attached = exp(-((X_tilt - 32.0).^2 + (Y_tilt - (Y_tilt(1, :) + 4.0)).^2) / 18.0);
    q_wall_attached(layout.components.u:layout.nvar:end) = wall_attached(:);
    diag_wall = compute_mode_diagnostics(q_wall_attached, Ny, Nx, ...
        'BoundaryMask', boundary_mask, ...
        'FarfieldMask', farfield_mask, ...
        'X', X_tilt, 'Y', Y_tilt, ...
        'StateLayout', layout.name);
    assert(diag_wall.peak_distance_to_wall < 0.15, ...
        'Wall-attached downstream mode should remain close to the local wall.');
    assert(diag_wall.peak_distance_to_farfield > 0.70, ...
        'Wall-attached downstream mode should remain far from the local top edge.');

    fprintf('[test_mode_diagnostics] PASS\n');
end
