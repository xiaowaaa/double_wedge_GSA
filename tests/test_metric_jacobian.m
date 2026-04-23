function test_metric_jacobian()
%TEST_METRIC_JACOBIAN Validate the structured-grid metric/Jacobian formulas.

    project_root = fileparts(fileparts(mfilename('fullpath')));
    addpath(project_root);
    addpath(fullfile(project_root, 'src', 'core'));

    Nx = 11;
    Ny = 9;
    [XI, ETA] = meshgrid(0:Nx-1, 0:Ny-1);

    X = XI + 0.02 * XI .* ETA + 0.001 * ETA .^ 2;
    Y = ETA + 0.015 * XI .^ 2 - 0.01 * XI .* ETA;

    x_xi_exact = 1 + 0.02 * ETA;
    x_eta_exact = 0.02 * XI + 0.002 * ETA;
    y_xi_exact = 0.03 * XI - 0.01 * ETA;
    y_eta_exact = 1 - 0.01 * XI;
    J_exact = x_xi_exact .* y_eta_exact - x_eta_exact .* y_xi_exact;

    [Metrics, Report] = compute_structured_metrics(X, Y);

    assert(max(abs(Metrics.x_xi(:) - x_xi_exact(:))) < 1e-10, ...
        'x_xi mismatch on quadratic mapping.');
    assert(max(abs(Metrics.x_eta(:) - x_eta_exact(:))) < 1e-10, ...
        'x_eta mismatch on quadratic mapping.');
    assert(max(abs(Metrics.y_xi(:) - y_xi_exact(:))) < 1e-10, ...
        'y_xi mismatch on quadratic mapping.');
    assert(max(abs(Metrics.y_eta(:) - y_eta_exact(:))) < 1e-10, ...
        'y_eta mismatch on quadratic mapping.');
    assert(max(abs(Metrics.J(:) - J_exact(:))) < 1e-10, ...
        'Jacobian mismatch on quadratic mapping.');

    assert(Report.min_abs_J > 0.5, 'Jacobian should remain comfortably away from zero.');
    assert(Report.identity_error.e11 < 1e-10, 'Inverse-metric identity e11 failed.');
    assert(Report.identity_error.e12 < 1e-10, 'Inverse-metric identity e12 failed.');
    assert(Report.identity_error.e21 < 1e-10, 'Inverse-metric identity e21 failed.');
    assert(Report.identity_error.e22 < 1e-10, 'Inverse-metric identity e22 failed.');

    fprintf('[test_metric_jacobian] PASS\n');
end
