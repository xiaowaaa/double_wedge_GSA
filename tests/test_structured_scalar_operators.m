function test_structured_scalar_operators()
%TEST_STRUCTURED_SCALAR_OPERATORS Validate sparse scalar derivative operators.

    project_root = fileparts(fileparts(mfilename('fullpath')));
    addpath(project_root);
    addpath(fullfile(project_root, 'src', 'core'));

    Nx = 10;
    Ny = 8;
    [X, Y] = meshgrid(0:Nx-1, 0:Ny-1);
    [Metrics, ~] = compute_structured_metrics(X, Y);
    ops = build_structured_scalar_operators(Metrics);

    F = 1 + 2 * X - 3 * Y + 0.5 * X.^2 + 0.25 * X .* Y + 0.75 * Y.^2;
    Fx = 2 + X + 0.25 * Y;
    Fy = -3 + 0.25 * X + 1.5 * Y;
    Fxx = ones(size(X));
    Fyy = 1.5 * ones(size(X));
    Fxy = 0.25 * ones(size(X));

    f_vec = F(:);

    assert(max(abs(reshape(ops.Dx * f_vec, Ny, Nx) - Fx), [], 'all') < 1e-10, ...
        'Dx operator mismatch on polynomial field.');
    assert(max(abs(reshape(ops.Dy * f_vec, Ny, Nx) - Fy), [], 'all') < 1e-10, ...
        'Dy operator mismatch on polynomial field.');
    assert(max(abs(reshape(ops.Dxx * f_vec, Ny, Nx) - Fxx), [], 'all') < 1e-10, ...
        'Dxx operator mismatch on polynomial field.');
    assert(max(abs(reshape(ops.Dyy * f_vec, Ny, Nx) - Fyy), [], 'all') < 1e-10, ...
        'Dyy operator mismatch on polynomial field.');
    assert(max(abs(reshape(ops.Dxy * f_vec, Ny, Nx) - Fxy), [], 'all') < 1e-10, ...
        'Dxy operator mismatch on polynomial field.');

    fprintf('[test_structured_scalar_operators] PASS\n');
end
