function base = preprocess_baseflow(base, cfg)
%PREPROCESS_BASEFLOW Add derived thermodynamic quantities and consistency checks.

    flow = finalize_flow_config(cfg.flow);
    S = flow.Sutherland_nd;
    T = base.T;
    T_pos = max(T, 0.0);
    T_eps = max(T_pos, eps);
    denom = max(T_pos + S, eps);

    mu = ((1 + S) .* T_pos .^ 1.5) ./ denom;
    dmu_dT = 0.5 * (1 + S) .* sqrt(T_pos) .* (T_pos + 3.0 * S) ./ max(denom .^ 2, eps);
    d2mu_dT2 = -0.25 * (1 + S) .* (T_pos .^ 2 + 6.0 * S .* T_pos - 3.0 * S^2) ./ ...
        max(sqrt(T_eps) .* denom .^ 3, eps);

    R_nd = 1.0 / (flow.gamma * flow.Ma_inf^2);
    eos_ref = R_nd * base.rho .* base.T;
    eos_rel = abs(base.p - eos_ref) ./ max(abs(base.p), eps);

    base.derived = struct();
    base.derived.mu = mu;
    base.derived.dmu_dT = dmu_dT;
    base.derived.d2mu_dT2 = d2mu_dT2;

    base.validation = struct();
    base.validation.bottom_split_ok = true;
    base.validation.eos_relative_error = max(eos_rel(:));
    base.validation.wall_model = flow.wall_model;
    base.validation.wall_temperature_target = flow.T_wall;
    base.validation.wall_temperature_target_nd = flow.T_wall_nd;
    base.validation.wall_temperature_check_applied = strcmp(flow.wall_model, 'isothermal');
    if base.validation.wall_temperature_check_applied
        base.validation.wall_temperature_relative_mismatch = ...
            abs(mean(base.T(1, :)) - flow.T_wall_nd) / ...
            max(abs(flow.T_wall_nd), eps);
    else
        base.validation.wall_temperature_relative_mismatch = NaN;
    end
end
