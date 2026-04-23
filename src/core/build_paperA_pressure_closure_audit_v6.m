function audit = build_paperA_pressure_closure_audit_v6(rho0, T0, p0, pressure_scale, rho_from_p, rho_from_T, Config)
%BUILD_PAPERA_PRESSURE_CLOSURE_AUDIT_V6 Summarize primitive-five pressure-closure identities.

    gamma_expected = Config.gamma * pressure_scale;
    eos_ref = (1.0 / (Config.gamma * Config.Ma_inf^2)) .* rho0 .* T0;

    audit = struct();
    audit.pressure_scale_min = min(pressure_scale);
    audit.pressure_scale_max = max(pressure_scale);
    audit.rho_from_p_gamma_residual_max = max(abs(rho_from_p - gamma_expected));
    audit.rho_from_T_identity_residual_max = max(abs(rho_from_T .* T0 + rho0));
    audit.eos_closure_ratio_min = min(p0 ./ max(eos_ref, eps));
    audit.eos_closure_ratio_max = max(p0 ./ max(eos_ref, eps));
    audit.eos_closure_ratio_median = median(p0 ./ max(eos_ref, eps));
end
