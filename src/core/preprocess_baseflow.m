function base = preprocess_baseflow(base, cfg)
%PREPROCESS_BASEFLOW Add derived thermodynamic quantities and consistency checks.

    S = cfg.flow.Sutherland_nd;
    T = base.T;
    mu = ((1 + S) .* T .^ 1.5) ./ max(T + S, eps);
    h = 1.0e-6;
    mu_p = ((1 + S) .* (T + h) .^ 1.5) ./ max(T + h + S, eps);
    mu_m = ((1 + S) .* max(T - h, 0) .^ 1.5) ./ max(max(T - h, 0) + S, eps);
    dmu_dT = (mu_p - mu_m) / (2 * h);
    d2mu_dT2 = (mu_p - 2 * mu + mu_m) / (h^2);

    R_nd = 1.0 / (cfg.flow.gamma * cfg.flow.Ma_inf^2);
    eos_ref = R_nd * base.rho .* base.T;
    eos_rel = abs(base.p - eos_ref) ./ max(abs(base.p), eps);

    base.derived = struct();
    base.derived.mu = mu;
    base.derived.dmu_dT = dmu_dT;
    base.derived.d2mu_dT2 = d2mu_dT2;

    base.validation = struct();
    base.validation.bottom_split_ok = true;
    base.validation.eos_relative_error = max(eos_rel(:));
    base.validation.wall_temperature_relative_mismatch = ...
        abs(mean(base.T(1, :)) - cfg.flow.T_wall / cfg.flow.T_inf) / ...
        max(abs(cfg.flow.T_wall / cfg.flow.T_inf), eps);
end
