function info = build_semi_artificial_viscosity(pressure_proxy, varargin)
%BUILD_SEMI_ARTIFICIAL_VISCOSITY Build a weak scalar SAV coefficient field.

    p = inputParser;
    p.FunctionName = 'build_semi_artificial_viscosity';
    addParameter(p, 'Epsilon', 1.0e-2, @(x) isnumeric(x) && isscalar(x) && x >= 0);
    addParameter(p, 'Power', 2.0, @(x) isnumeric(x) && isscalar(x) && x >= 1);
    addParameter(p, 'Threshold', 0.02, @(x) isnumeric(x) && isscalar(x) && x >= 0);
    parse(p, varargin{:});

    grad_x = fd4_uniform(pressure_proxy, 2, 1);
    grad_y = fd4_uniform(pressure_proxy, 1, 1);
    sensor = hypot(grad_x, grad_y);
    if max(sensor(:)) > 0
        sensor = sensor / max(sensor(:));
    end
    sensor = max(0.0, sensor - p.Results.Threshold);

    info = struct();
    info.epsilon = p.Results.Epsilon;
    info.power = p.Results.Power;
    info.threshold = p.Results.Threshold;
    info.sensor = sensor;
    info.coefficient = p.Results.Epsilon * sensor .^ p.Results.Power;
end
