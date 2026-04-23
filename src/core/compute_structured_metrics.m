function [Metrics, Report] = compute_structured_metrics(X, Y)
%COMPUTE_STRUCTURED_METRICS Compute metric terms on a structured grid.

    Metrics = struct();

    Metrics.x_xi = fd4_uniform(X, 2, 1);
    Metrics.x_eta = fd4_uniform(X, 1, 1);
    Metrics.y_xi = fd4_uniform(Y, 2, 1);
    Metrics.y_eta = fd4_uniform(Y, 1, 1);

    Metrics.x_xixi = fd4_uniform(X, 2, 2);
    Metrics.x_etaeta = fd4_uniform(X, 1, 2);
    Metrics.x_xieta = fd4_uniform(Metrics.x_xi, 1, 1);
    Metrics.y_xixi = fd4_uniform(Y, 2, 2);
    Metrics.y_etaeta = fd4_uniform(Y, 1, 2);
    Metrics.y_xieta = fd4_uniform(Metrics.y_xi, 1, 1);

    Metrics.J = Metrics.x_xi .* Metrics.y_eta - Metrics.x_eta .* Metrics.y_xi;
    Metrics.xi_x = Metrics.y_eta ./ Metrics.J;
    Metrics.xi_y = -Metrics.x_eta ./ Metrics.J;
    Metrics.eta_x = -Metrics.y_xi ./ Metrics.J;
    Metrics.eta_y = Metrics.x_xi ./ Metrics.J;

    e11 = Metrics.xi_x .* Metrics.x_xi + Metrics.eta_x .* Metrics.x_eta - 1.0;
    e12 = Metrics.xi_x .* Metrics.y_xi + Metrics.eta_x .* Metrics.y_eta;
    e21 = Metrics.xi_y .* Metrics.x_xi + Metrics.eta_y .* Metrics.x_eta;
    e22 = Metrics.xi_y .* Metrics.y_xi + Metrics.eta_y .* Metrics.y_eta - 1.0;

    Report = struct();
    Report.min_abs_J = min(abs(Metrics.J(:)));
    Report.identity_error = struct( ...
        'e11', max(abs(e11(:))), ...
        'e12', max(abs(e12(:))), ...
        'e21', max(abs(e21(:))), ...
        'e22', max(abs(e22(:))));
end
