function ops = build_structured_scalar_operators(Metrics)
%BUILD_STRUCTURED_SCALAR_OPERATORS Build sparse physical derivative operators.

    [Ny, Nx] = size(Metrics.J);
    N = Ny * Nx;

    Dxi_1 = build_uniform_fd_matrix(Nx, 1);
    Deta_1 = build_uniform_fd_matrix(Ny, 1);
    Dxi_2 = build_uniform_fd_matrix(Nx, 2);
    Deta_2 = build_uniform_fd_matrix(Ny, 2);

    I_x = speye(Nx);
    I_y = speye(Ny);

    ops = struct();
    ops.Dxi = kron(Dxi_1, I_y);
    ops.Deta = kron(I_x, Deta_1);
    ops.Dxixi = kron(Dxi_2, I_y);
    ops.Detaeta = kron(I_x, Deta_2);
    ops.Dxieta = ops.Deta * ops.Dxi;

    dxi_x = spdiags(Metrics.xi_x(:), 0, N, N);
    deta_x = spdiags(Metrics.eta_x(:), 0, N, N);
    dxi_y = spdiags(Metrics.xi_y(:), 0, N, N);
    deta_y = spdiags(Metrics.eta_y(:), 0, N, N);

    ops.Dx = dxi_x * ops.Dxi + deta_x * ops.Deta;
    ops.Dy = dxi_y * ops.Dxi + deta_y * ops.Deta;

    rx1 = ops.Dxixi ...
        - spdiags(Metrics.x_xixi(:), 0, N, N) * ops.Dx ...
        - spdiags(Metrics.y_xixi(:), 0, N, N) * ops.Dy;
    rx2 = ops.Dxieta ...
        - spdiags(Metrics.x_xieta(:), 0, N, N) * ops.Dx ...
        - spdiags(Metrics.y_xieta(:), 0, N, N) * ops.Dy;
    rx3 = ops.Detaeta ...
        - spdiags(Metrics.x_etaeta(:), 0, N, N) * ops.Dx ...
        - spdiags(Metrics.y_etaeta(:), 0, N, N) * ops.Dy;

    coeff_xx = zeros(N, 3);
    coeff_xy = zeros(N, 3);
    coeff_yy = zeros(N, 3);

    for n = 1:N
        x_xi = Metrics.x_xi(n);
        x_eta = Metrics.x_eta(n);
        y_xi = Metrics.y_xi(n);
        y_eta = Metrics.y_eta(n);

        M = [ ...
            x_xi^2,                 2.0 * x_xi * y_xi,                 y_xi^2; ...
            x_xi * x_eta,           x_xi * y_eta + x_eta * y_xi,      y_xi * y_eta; ...
            x_eta^2,                2.0 * x_eta * y_eta,              y_eta^2];
        inv_M = M \ eye(3);

        coeff_xx(n, :) = inv_M(1, :);
        coeff_xy(n, :) = inv_M(2, :);
        coeff_yy(n, :) = inv_M(3, :);
    end

    ops.Dxx = spdiags(coeff_xx(:, 1), 0, N, N) * rx1 + ...
        spdiags(coeff_xx(:, 2), 0, N, N) * rx2 + ...
        spdiags(coeff_xx(:, 3), 0, N, N) * rx3;
    ops.Dxy = spdiags(coeff_xy(:, 1), 0, N, N) * rx1 + ...
        spdiags(coeff_xy(:, 2), 0, N, N) * rx2 + ...
        spdiags(coeff_xy(:, 3), 0, N, N) * rx3;
    ops.Dyy = spdiags(coeff_yy(:, 1), 0, N, N) * rx1 + ...
        spdiags(coeff_yy(:, 2), 0, N, N) * rx2 + ...
        spdiags(coeff_yy(:, 3), 0, N, N) * rx3;
end
