function [sigma_sp, info] = build_sponge_profile(X, Y, boundary_masks, varargin)
%BUILD_SPONGE_PROFILE Construct a simple polynomial sponge profile.

    p = inputParser;
    p.FunctionName = 'build_sponge_profile';
    addParameter(p, 'SigmaMax', 15.0, @(x) isnumeric(x) && isscalar(x) && x >= 0);
    addParameter(p, 'Power', 2.0, @(x) isnumeric(x) && isscalar(x) && x >= 1);
    addParameter(p, 'OutletFraction', 0.18, @(x) isnumeric(x) && isscalar(x) && x > 0);
    addParameter(p, 'TopFraction', 0.18, @(x) isnumeric(x) && isscalar(x) && x > 0);
    addParameter(p, 'InletFraction', 0.05, @(x) isnumeric(x) && isscalar(x) && x > 0);
    addParameter(p, 'BottomFraction', 0.05, @(x) isnumeric(x) && isscalar(x) && x > 0);
    addParameter(p, 'ApplyOutlet', true, @(x) islogical(x) && isscalar(x));
    addParameter(p, 'ApplyTop', true, @(x) islogical(x) && isscalar(x));
    addParameter(p, 'ApplyInlet', false, @(x) islogical(x) && isscalar(x));
    addParameter(p, 'ApplyBottom', false, @(x) islogical(x) && isscalar(x));
    parse(p, varargin{:});

    sigma_sp = zeros(size(X));
    x_min = min(X(:));
    x_max = max(X(:));
    y_min = min(Y(:));
    y_max = max(Y(:));
    x_span = max(x_max - x_min, eps);
    y_span = max(y_max - y_min, eps);

    if p.Results.ApplyOutlet
        sigma_sp = sigma_sp + local_poly_band((X - (x_max - p.Results.OutletFraction * x_span)) / ...
            max(p.Results.OutletFraction * x_span, eps), p.Results.Power) * p.Results.SigmaMax;
    end
    if p.Results.ApplyTop
        sigma_sp = sigma_sp + local_poly_band((Y - (y_max - p.Results.TopFraction * y_span)) / ...
            max(p.Results.TopFraction * y_span, eps), p.Results.Power) * p.Results.SigmaMax;
    end
    if p.Results.ApplyInlet
        sigma_sp = sigma_sp + local_poly_band(((x_min + p.Results.InletFraction * x_span) - X) / ...
            max(p.Results.InletFraction * x_span, eps), p.Results.Power) * p.Results.SigmaMax;
    end
    if p.Results.ApplyBottom
        sigma_sp = sigma_sp + local_poly_band(((y_min + p.Results.BottomFraction * y_span) - Y) / ...
            max(p.Results.BottomFraction * y_span, eps), p.Results.Power) * p.Results.SigmaMax;
    end

    if nargin >= 3 && ~isempty(boundary_masks) && isstruct(boundary_masks) && isfield(boundary_masks, 'outer')
        sigma_sp(~isfinite(sigma_sp)) = 0.0;
    end

    info = struct();
    info.sigma_max = p.Results.SigmaMax;
    info.max_sigma = max(sigma_sp(:));
    info.min_sigma = min(sigma_sp(:));
end

function profile = local_poly_band(s, power_value)
%LOCAL_POLY_BAND Clamp and raise the normalized band coordinate.

    s = max(0.0, min(1.0, s));
    profile = s .^ power_value;
end
