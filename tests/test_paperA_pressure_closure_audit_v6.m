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

    assert(audit.rho_from_p_gamma_residual_max < 1.0e-12, ...
        'rho_from_p should equal gamma * pressure_scale.');
    assert(audit.rho_from_T_identity_residual_max < 1.0e-12, ...
        'rho_from_T should satisfy rho_from_T * T0 = -rho0.');
    assert(abs(audit.eos_closure_ratio_median - 1.0) < 1.0e-12, ...
        'The EOS closure ratio should be 1 for a consistent baseflow.');

    fprintf('[test_paperA_pressure_closure_audit_v6] PASS\n');
end
