function audit = build_paperA_pressure_closure_audit_v6(rho0, T0, p0, pressure_scale, rho_from_p, rho_from_T, Config)
%BUILD_PAPERA_PRESSURE_CLOSURE_AUDIT_V6 Summarize primitive-five pressure-closure identities.

    eos_ref = (1.0 / (Config.gamma * Config.Ma_inf^2)) .* rho0 .* T0;
    rho_from_p_density = rho_from_p .* p0;
    pressure_scale_density = Config.gamma .* pressure_scale .* p0;
    density_ratio = rho_from_p_density ./ max(rho0, eps);
    pressure_scale_ratio = pressure_scale_density ./ max(rho0, eps);

    audit = struct();
    audit.pressure_scale_min = min(pressure_scale);
    audit.pressure_scale_max = max(pressure_scale);
    audit.rho_from_p_density_residual_max = max(abs(rho_from_p_density - rho0));
    audit.pressure_scale_density_residual_max = max(abs(pressure_scale_density - rho0));
    audit.linearized_eos_balance_residual_max = max(abs(rho_from_p_density + rho_from_T .* T0));
    audit.rho_from_p_density_ratio_min = min(density_ratio);
    audit.rho_from_p_density_ratio_max = max(density_ratio);
    audit.rho_from_p_density_ratio_median = median(density_ratio);
    audit.pressure_scale_density_ratio_min = min(pressure_scale_ratio);
    audit.pressure_scale_density_ratio_max = max(pressure_scale_ratio);
    audit.pressure_scale_density_ratio_median = median(pressure_scale_ratio);
    audit.eos_closure_ratio_min = min(p0 ./ max(eos_ref, eps));
    audit.eos_closure_ratio_max = max(p0 ./ max(eos_ref, eps));
    audit.eos_closure_ratio_median = median(p0 ./ max(eos_ref, eps));
end
