function test_curvilinear_scalar_operators()
%TEST_CURVILINEAR_SCALAR_OPERATORS Validate derivatives on a curved grid.
%   This test uses a manufactured scalar field F(x,y) on a non-orthogonal,
%   spatially varying structured mapping. It checks that the current metric
%   construction plus sparse scalar operators recover the exact physical
%   derivatives to high accuracy, especially in the interior where the
%   fourth-order centered stencil is active.

    project_root = fileparts(fileparts(mfilename('fullpath')));
    addpath(project_root);
    addpath(fullfile(project_root, 'src', 'core'));

    Nx = 121;
    Ny = 91;
    [XI, ETA] = meshgrid(linspace(0, 1, Nx), linspace(0, 1, Ny));

    X = XI + 0.15 * XI .* ETA + 0.03 * ETA .^ 2;
    Y = ETA + 0.10 * XI .^ 2 - 0.08 * XI .* ETA;

    [Metrics, ~] = compute_structured_metrics(X, Y);
    ops = build_structured_scalar_operators(Metrics);

    F = 1 + 2 * X - 3 * Y + 0.5 * X .^ 2 + 0.25 * X .* Y + 0.75 * Y .^ 2;
    Fx = 2 + X + 0.25 * Y;
    Fy = -3 + 0.25 * X + 1.5 * Y;
    Fxx = ones(size(X));
    Fyy = 1.5 * ones(size(X));
    Fxy = 0.25 * ones(size(X));

    f_vec = F(:);
    Dx = reshape(ops.Dx * f_vec, Ny, Nx);
    Dy = reshape(ops.Dy * f_vec, Ny, Nx);
    Dxx = reshape(ops.Dxx * f_vec, Ny, Nx);
    Dyy = reshape(ops.Dyy * f_vec, Ny, Nx);
    Dxy = reshape(ops.Dxy * f_vec, Ny, Nx);

    interior_mask = false(Ny, Nx);
    interior_mask(3:Ny-2, 3:Nx-2) = true;
    full_mask = true(Ny, Nx);

    assert(local_relerr(Dx, Fx, interior_mask) < 1e-10, ...
        'Dx interior mismatch on curved mapping.');
    assert(local_relerr(Dy, Fy, interior_mask) < 1e-10, ...
        'Dy interior mismatch on curved mapping.');
    assert(local_relerr(Dxx, Fxx, interior_mask) < 1e-8, ...
        'Dxx interior mismatch on curved mapping.');
    assert(local_relerr(Dyy, Fyy, interior_mask) < 1e-8, ...
        'Dyy interior mismatch on curved mapping.');
    assert(local_relerr(Dxy, Fxy, interior_mask) < 1e-8, ...
        'Dxy interior mismatch on curved mapping.');

    assert(local_relerr(Dx, Fx, full_mask) < 1e-6, ...
        'Dx full-domain mismatch on curved mapping.');
    assert(local_relerr(Dy, Fy, full_mask) < 1e-6, ...
        'Dy full-domain mismatch on curved mapping.');
    assert(local_relerr(Dxx, Fxx, full_mask) < 5e-5, ...
        'Dxx full-domain mismatch on curved mapping.');
    assert(local_relerr(Dyy, Fyy, full_mask) < 5e-5, ...
        'Dyy full-domain mismatch on curved mapping.');
    assert(local_relerr(Dxy, Fxy, full_mask) < 5e-5, ...
        'Dxy full-domain mismatch on curved mapping.');

    fprintf('[test_curvilinear_scalar_operators] PASS\n');
end

function value = local_relerr(actual, expected, mask)
%LOCAL_RELERR Compute max relative error on a masked subset.

    actual_s = actual(mask);
    expected_s = expected(mask);
    denom = max(1e-14, max(abs(expected_s)));
    value = max(abs(actual_s - expected_s)) / denom;
end
