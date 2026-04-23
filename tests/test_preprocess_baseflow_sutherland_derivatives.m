function test_preprocess_baseflow_sutherland_derivatives()
%TEST_PREPROCESS_BASEFLOW_SUTHERLAND_DERIVATIVES Validate analytic Sutherland derivatives.

    project_root = fileparts(fileparts(mfilename('fullpath')));
    addpath(project_root);
    addpath(fullfile(project_root, 'src', 'core'));

    cfg = struct();
    cfg.flow = struct( ...
        'Sutherland_nd', 0.35, ...
        'gamma', 1.4, ...
        'Ma_inf', 6.0, ...
        'T_wall', 2.0, ...
        'T_inf', 1.0);

    T = [2.0, 2.0, 2.0; ...
         1.5, 0.8, 0.3];
    rho = [1.0, 1.1, 1.2; ...
           0.9, 1.05, 1.3];
    R_nd = 1.0 / (cfg.flow.gamma * cfg.flow.Ma_inf^2);
    p = R_nd .* rho .* T;

    base = struct('T', T, 'rho', rho, 'p', p);
    base = preprocess_baseflow(base, cfg);

    S = cfg.flow.Sutherland_nd;
    mu_expected = ((1 + S) .* T .^ 1.5) ./ (T + S);
    dmu_expected = 0.5 * (1 + S) .* sqrt(T) .* (T + 3.0 * S) ./ (T + S) .^ 2;
    d2mu_expected = -0.25 * (1 + S) .* (T .^ 2 + 6.0 * S .* T - 3.0 * S^2) ./ ...
        (sqrt(T) .* (T + S) .^ 3);

    assert(max(abs(base.derived.mu - mu_expected), [], 'all') < 1.0e-12, ...
        'Sutherland viscosity should match the analytic expression.');
    assert(max(abs(base.derived.dmu_dT - dmu_expected), [], 'all') < 1.0e-12, ...
        'dmu_dT should match the analytic Sutherland derivative.');
    assert(max(abs(base.derived.d2mu_dT2 - d2mu_expected), [], 'all') < 1.0e-12, ...
        'd2mu_dT2 should match the analytic Sutherland second derivative.');
    assert(all(isfinite(base.derived.dmu_dT), 'all') && all(isfinite(base.derived.d2mu_dT2), 'all'), ...
        'Analytic derivative outputs should stay finite for positive temperatures.');

    mu_fun = @(TT) ((1 + S) .* TT .^ 1.5) ./ (TT + S);
    h = 1.0e-6;
    fd_dmu = (mu_fun(T + h) - mu_fun(T - h)) ./ (2.0 * h);
    fd_d2mu = (mu_fun(T + h) - 2.0 * mu_fun(T) + mu_fun(T - h)) ./ (h^2);

    assert(max(abs(base.derived.dmu_dT - fd_dmu), [], 'all') < 1.0e-9, ...
        'Analytic dmu_dT should agree with a finite-difference reference.');
    assert(max(abs(base.derived.d2mu_dT2 - fd_d2mu), [], 'all') < 1.0e-3, ...
        'Analytic d2mu_dT2 should agree with a finite-difference reference.');

    fprintf('[test_preprocess_baseflow_sutherland_derivatives] PASS\n');
end
