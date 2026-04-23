function [sigma_sp, info] = build_restricted_sponge_profile(X, Y, varargin)
%BUILD_RESTRICTED_SPONGE_PROFILE Build a top/outlet sponge away from the near wall.

    p = inputParser;
    p.FunctionName = 'build_restricted_sponge_profile';
    addParameter(p, 'SigmaMax', 2.0, @(x) isnumeric(x) && isscalar(x) && x >= 0);
    addParameter(p, 'FarfieldFraction', 0.12, @(x) isnumeric(x) && isscalar(x) && x > 0 && x < 1);
    addParameter(p, 'OutletFraction', 0.12, @(x) isnumeric(x) && isscalar(x) && x > 0 && x < 1);
    addParameter(p, 'Power', 4, @(x) isnumeric(x) && isscalar(x) && x >= 1);
    parse(p, varargin{:});

    [Ny, Nx] = size(X);
    sigma_sp = zeros(Ny, Nx);

    x_min = min(X(:));
    x_max = max(X(:));
    y_min = min(Y(:));
    y_max = max(Y(:));
    x_span = max(x_max - x_min, eps);
    y_span = max(y_max - y_min, eps);

    j_cut = max(1, round(0.85 * Ny));
    i_cut = max(1, round(0.85 * Nx));

    for i = i_cut:Nx
        s = (X(:, i) - (x_max - p.Results.OutletFraction * x_span)) / max(p.Results.OutletFraction * x_span, eps);
        sigma_sp(:, i) = sigma_sp(:, i) + p.Results.SigmaMax * max(0.0, min(1.0, s)) .^ p.Results.Power;
    end

    for j = j_cut:Ny
        s = (Y(j, :) - (y_max - p.Results.FarfieldFraction * y_span)) / max(p.Results.FarfieldFraction * y_span, eps);
        sigma_sp(j, :) = sigma_sp(j, :) + p.Results.SigmaMax * max(0.0, min(1.0, s)) .^ p.Results.Power;
    end

    sigma_sp(1:j_cut-1, :) = 0.0;
    sigma_sp(:, 1:i_cut-1) = 0.0;

    info = struct();
    info.j_cut = j_cut;
    info.i_cut = i_cut;
    info.max_sigma = max(sigma_sp(:));
    info.min_sigma = min(sigma_sp(:));
end
