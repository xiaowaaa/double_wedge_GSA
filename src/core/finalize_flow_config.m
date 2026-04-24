function flow = finalize_flow_config(flow)
%FINALIZE_FLOW_CONFIG Normalize freestream and wall settings for the solver.

    required_fields = {'Ma_inf', 'Re_inf', 'T_inf', 'gamma', 'Pr'};
    for k = 1:numel(required_fields)
        name = required_fields{k};
        if ~isfield(flow, name)
            error('finalize_flow_config:MissingField', ...
                'Missing required flow field "%s".', name);
        end
    end

    local_assert_positive_scalar(flow.Ma_inf, 'Ma_inf');
    local_assert_positive_scalar(flow.Re_inf, 'Re_inf');
    local_assert_positive_scalar(flow.T_inf, 'T_inf');
    local_assert_positive_scalar(flow.Pr, 'Pr');
    local_assert_positive_scalar(flow.gamma, 'gamma');
    if flow.gamma <= 1.0
        error('finalize_flow_config:Gamma', ...
            'gamma must be greater than 1 for the current compressible solver.');
    end

    if ~isfield(flow, 'wall_model') || isempty(flow.wall_model)
        flow.wall_model = 'adiabatic';
    end
    flow.wall_model = normalize_wall_model(flow.wall_model, ...
        'ErrorIdentifier', 'finalize_flow_config:WallModel');

    if ~isfield(flow, 'T_wall') || isempty(flow.T_wall)
        flow.T_wall = 298.0;
    end
    local_assert_positive_scalar(flow.T_wall, 'T_wall');

    flow.Cv = 1.0 / (flow.gamma * (flow.gamma - 1.0) * flow.Ma_inf^2);
    if ~isfield(flow, 'Sutherland_nd') || isempty(flow.Sutherland_nd)
        flow.Sutherland_nd = 110.4 / flow.T_inf;
    else
        local_assert_positive_scalar(flow.Sutherland_nd, 'Sutherland_nd');
    end
    flow.T_wall_nd = flow.T_wall / flow.T_inf;
end

function local_assert_positive_scalar(value, name)
%LOCAL_ASSERT_POSITIVE_SCALAR Validate one positive finite scalar input.

    if ~(isnumeric(value) && isscalar(value) && isfinite(value) && value > 0)
        error('finalize_flow_config:InvalidScalar', ...
            '%s must be one positive finite scalar.', name);
    end
end
