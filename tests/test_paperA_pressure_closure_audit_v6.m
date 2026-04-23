function test_paperA_pressure_closure_audit_v6()
%TEST_PAPERA_PRESSURE_CLOSURE_AUDIT_V6 Validate primitive-five pressure-closure identities.

    project_root = fileparts(fileparts(mfilename('fullpath')));
    addpath(project_root);
    addpath(fullfile(project_root, 'src', 'core'));

    Config = struct('gamma', 1.4, 'Ma_inf', 7.0);
    rho0 = [1.0; 1.5; 2.0; 2.5];
    T0 = [1.0; 1.2; 1.6; 2.0];
    R_nd = 1.0 / (Config.gamma * Config.Ma_inf^2);
    p0 = R_nd .* rho0 .* T0;
    pressure_scale = 1.0 ./ max(Config.gamma * R_nd .* T0, eps);
    rho_from_p = 1.0 ./ max(R_nd * T0, eps);
    rho_from_T = -rho0 ./ max(T0, eps);

    audit = build_paperA_pressure_closure_audit_v6( ...
        rho0, T0, p0, pressure_scale, rho_from_p, rho_from_T, Config);

    assert(audit.rho_from_p_density_residual_max < 1.0e-12, ...
        'rho_from_p should map pressure back to the consistent density coefficient.');
    assert(audit.pressure_scale_density_residual_max < 1.0e-12, ...
        'pressure_scale should remain consistent with rho0/(gamma*p0).');
    assert(audit.linearized_eos_balance_residual_max < 1.0e-12, ...
        'rho_from_p and rho_from_T should satisfy the linearized EOS balance.');
    assert(abs(audit.rho_from_p_density_ratio_median - 1.0) < 1.0e-12, ...
        'The rho_from_p density ratio should be 1 for a consistent baseflow.');
    assert(abs(audit.eos_closure_ratio_median - 1.0) < 1.0e-12, ...
        'The EOS closure ratio should be 1 for a consistent baseflow.');

    fprintf('[test_paperA_pressure_closure_audit_v6] PASS\n');
end
