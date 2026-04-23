function test_semi_artificial_viscosity_matrix()
%TEST_SEMI_ARTIFICIAL_VISCOSITY_MATRIX Validate the fourth-difference filter matrix.

    project_root = fileparts(fileparts(mfilename('fullpath')));
    addpath(project_root);
    addpath(fullfile(project_root, 'src', 'core'));

    Ny = 8;
    Nx = 9;
    layout = 'primitive5_u_v_w_T_p';
    info_layout = get_state_layout_info(layout);
    idx = @(j, i, var) (i - 1) * Ny * info_layout.nvar + (j - 1) * info_layout.nvar + var;

    [Kav, info] = build_semi_artificial_viscosity_matrix(Ny, Nx, ...
        'StateLayout', layout);

    assert(strcmp(info.state_layout, layout), 'Unexpected state layout in filter info.');
    assert(info.active_points == (Ny - 4) * (Nx - 4), ...
        'Unexpected number of active interior points.');
    assert(info.active_rows == info.active_points * info_layout.nvar, ...
        'Unexpected number of active filter rows.');

    row_id = idx(4, 5, 2);
    [~, cols, vals] = find(Kav(row_id, :));
    [cols, order] = sort(cols);
    vals = full(vals(order));
    expected_cols = [ ...
        idx(2, 5, 2), ...
        idx(3, 5, 2), ...
        idx(4, 3, 2), ...
        idx(4, 4, 2), ...
        idx(4, 5, 2), ...
        idx(4, 6, 2), ...
        idx(4, 7, 2), ...
        idx(5, 5, 2), ...
        idx(6, 5, 2)];
    expected_vals = [-1, 4, -1, 4, -12, 4, -1, 4, -1];
    [expected_cols, order_expected] = sort(expected_cols);
    expected_vals = expected_vals(order_expected);

    assert(isequal(cols(:), expected_cols(:)), ...
        'Interior filter row columns do not match the expected cross stencil.');
    assert(all(abs(vals(:) - expected_vals(:)) < 1.0e-12), ...
        'Interior filter row values do not match the expected cross stencil.');

    assert(nnz(Kav(idx(2, 5, 2), :)) == 0, ...
        'Rows in the near-boundary layer must not receive the interior-only filter.');
    assert(nnz(Kav(idx(4, 2, 2), :)) == 0, ...
        'Rows in the near-boundary layer must not receive the interior-only filter.');

    [J, I] = ndgrid(1:Ny, 1:Nx);
    smooth_field = sin(pi * (I - 1) / (Nx - 1)) .* sin(pi * (J - 1) / (Ny - 1));
    checker_field = (-1) .^ (I + J);

    q_smooth = zeros(info_layout.nvar * Ny * Nx, 1);
    q_checker = zeros(info_layout.nvar * Ny * Nx, 1);
    q_smooth(info_layout.components.u:info_layout.nvar:end) = smooth_field(:);
    q_checker(info_layout.components.u:info_layout.nvar:end) = checker_field(:);

    damping_smooth = real(q_smooth' * (Kav * q_smooth)) / max(real(q_smooth' * q_smooth), eps);
    damping_checker = real(q_checker' * (Kav * q_checker)) / max(real(q_checker' * q_checker), eps);

    assert(damping_checker < damping_smooth, ...
        'Checkerboard content should receive stronger damping than the smooth mode.');
    assert(abs(damping_checker) > 10.0 * max(abs(damping_smooth), eps), ...
        'The fourth-difference filter should be strongly scale-selective.');

    fprintf('[test_semi_artificial_viscosity_matrix] PASS\n');
end
