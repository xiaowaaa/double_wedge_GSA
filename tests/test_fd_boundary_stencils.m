function test_fd_boundary_stencils()
%TEST_FD_BOUNDARY_STENCILS Validate 4th-order interior / 3rd-order boundary FD.

    project_root = fileparts(fileparts(mfilename('fullpath')));
    addpath(project_root);
    addpath(fullfile(project_root, 'src', 'core'));

    Nx = 8;
    Ny = 6;
    [X, Y] = meshgrid(0:Nx-1, 0:Ny-1);

    F = X.^3 - 2.0 * X.^2 + X + 0.5 * Y.^3 - Y.^2;
    Fx = 3.0 * X.^2 - 4.0 * X + 1.0;
    Fy = 1.5 * Y.^2 - 2.0 * Y;
    Fxx = 6.0 * X - 4.0;
    Fyy = 3.0 * Y - 2.0;

    D1 = build_uniform_fd_matrix(Nx, 1);
    D2 = build_uniform_fd_matrix(Nx, 2);
    cols_d1_interior = find(D1(3, :));
    cols_d2_interior = find(D2(3, :));
    cols_d2_row1 = find(D2(1, :));
    cols_d2_row2 = find(D2(2, :));

    assert(nnz(D1(1, :)) == 4, 'First-derivative first row should use 4 boundary points.');
    assert(nnz(D1(2, :)) == 4, 'First-derivative second row should use 4 boundary points.');
    assert((max(cols_d1_interior) - min(cols_d1_interior)) == 4, ...
        'Interior first-derivative rows should span a 5-point centered stencil.');
    assert((max(cols_d2_row1) - min(cols_d2_row1)) == 3, ...
        'Second-derivative first row should use a 4-point boundary stencil.');
    assert((max(cols_d2_row2) - min(cols_d2_row2)) == 2, ...
        'Second-derivative second row should remain confined to the 4-point boundary stencil.');
    assert(nnz(D2(3, :)) == 5 && (max(cols_d2_interior) - min(cols_d2_interior)) == 4, ...
        'Interior second-derivative rows should use a 5-point centered stencil.');

    dFx = fd4_uniform(F, 2, 1);
    dFy = fd4_uniform(F, 1, 1);
    dFxx = fd4_uniform(F, 2, 2);
    dFyy = fd4_uniform(F, 1, 2);

    assert(max(abs(dFx - Fx), [], 'all') < 1e-12, ...
        'fd4_uniform first derivative in x failed on a cubic polynomial.');
    assert(max(abs(dFy - Fy), [], 'all') < 1e-12, ...
        'fd4_uniform first derivative in y failed on a cubic polynomial.');
    assert(max(abs(dFxx - Fxx), [], 'all') < 1e-12, ...
        'fd4_uniform second derivative in x failed on a cubic polynomial.');
    assert(max(abs(dFyy - Fyy), [], 'all') < 1e-12, ...
        'fd4_uniform second derivative in y failed on a cubic polynomial.');

    fprintf('[test_fd_boundary_stencils] PASS\n');
end
