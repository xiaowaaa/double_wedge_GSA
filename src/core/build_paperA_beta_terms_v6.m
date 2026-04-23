function [beta_terms, audit] = build_paperA_beta_terms_v6(Dx, Dy, I, varargin)
%BUILD_PAPERA_BETA_TERMS_V6 Build the explicit beta-dependent operator contributions.

    p = inputParser;
    p.FunctionName = 'build_paperA_beta_terms_v6';
    addParameter(p, 'Beta', 0.0, @(x) isnumeric(x) && isscalar(x));
    addParameter(p, 'Mu0', [], @isnumeric);
    addParameter(p, 'MuX', [], @isnumeric);
    addParameter(p, 'MuY', [], @isnumeric);
    addParameter(p, 'P0', [], @isnumeric);
    addParameter(p, 'Rho0', [], @isnumeric);
    addParameter(p, 'Div0', [], @isnumeric);
    addParameter(p, 'FacVis', 1.0, @(x) isnumeric(x) && isscalar(x));
    addParameter(p, 'FacHeat', 1.0, @(x) isnumeric(x) && isscalar(x));
    parse(p, varargin{:});

    beta = p.Results.Beta;
    mu0 = p.Results.Mu0(:);
    mu_x = p.Results.MuX(:);
    mu_y = p.Results.MuY(:);
    p0 = p.Results.P0(:);
    rho0 = p.Results.Rho0(:);
    div0 = p.Results.Div0(:);

    N = size(I, 1);
    D = @(x) spdiags(x(:), 0, N, N);
    beta_terms = struct();
    beta_terms.Luu = -p.Results.FacVis * D(mu0 * beta^2) * I;
    beta_terms.Lvv = -p.Results.FacVis * D(mu0 * beta^2) * I;
    beta_terms.Luw = p.Results.FacVis * ( ...
        D(1i * beta * mu0 / 3.0) * Dx + D(1i * beta * mu_x / 3.0));
    beta_terms.Lvw = p.Results.FacVis * ( ...
        D(1i * beta * mu0 / 3.0) * Dy + D(1i * beta * mu_y / 3.0));
    beta_terms.Lwu = p.Results.FacVis * ( ...
        D(1i * beta * mu0 / 3.0) * Dx + D(1i * beta * mu_x));
    beta_terms.Lwv = p.Results.FacVis * ( ...
        D(1i * beta * mu0 / 3.0) * Dy + D(1i * beta * mu_y));
    beta_terms.Lww = -p.Results.FacVis * D((4.0 / 3.0) * mu0 * beta^2) * I;
    beta_terms.LwP = -1i * beta * I;
    beta_terms.LTw = -1i * beta * D(p0) + D(p.Results.FacVis * mu0 .* ((-4.0 / 3.0) * 1i * beta .* div0));
    beta_terms.LTT = -p.Results.FacHeat * D(mu0 * beta^2) * I;
    beta_terms.LPw = -1i * beta * D(rho0);

    audit = struct();
    audit.beta = beta;
    audit.has_spanwise_terms = abs(beta) > 0;
    audit.linear_term_names = {'Luw', 'Lvw', 'Lwu', 'Lwv', 'LwP', 'LTw', 'LPw'};
    audit.quadratic_term_names = {'Luu', 'Lvv', 'Lww', 'LTT'};
    audit.linear_term_nnz = local_nnz_summary(beta_terms, audit.linear_term_names);
    audit.quadratic_term_nnz = local_nnz_summary(beta_terms, audit.quadratic_term_names);
    audit.linear_term_fro = local_norm_summary(beta_terms, audit.linear_term_names);
    audit.quadratic_term_fro = local_norm_summary(beta_terms, audit.quadratic_term_names);
    audit.zero_beta_all_zero = local_all_zero(beta_terms, [audit.linear_term_names, audit.quadratic_term_names]);
end

function summary = local_nnz_summary(beta_terms, names)
%LOCAL_NNZ_SUMMARY Count nonzeros for selected beta-term blocks.

    summary = struct();
    for k = 1:numel(names)
        name = names{k};
        summary.(name) = nnz(beta_terms.(name));
    end
end

function summary = local_norm_summary(beta_terms, names)
%LOCAL_NORM_SUMMARY Compute Frobenius norms for selected beta-term blocks.

    summary = struct();
    for k = 1:numel(names)
        name = names{k};
        summary.(name) = full(norm(beta_terms.(name), 'fro'));
    end
end

function tf = local_all_zero(beta_terms, names)
%LOCAL_ALL_ZERO True when all requested blocks are exactly zero.

    tf = true;
    for k = 1:numel(names)
        if nnz(beta_terms.(names{k})) ~= 0
            tf = false;
            return;
        end
    end
end
