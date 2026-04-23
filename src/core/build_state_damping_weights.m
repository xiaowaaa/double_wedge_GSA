function weights = build_state_damping_weights(layout_name, varargin)
%BUILD_STATE_DAMPING_WEIGHTS Return simple per-component damping weights.

    info = get_state_layout_info(layout_name);
    weights = ones(info.nvar, 1);

    p = inputParser;
    p.FunctionName = 'build_state_damping_weights';
    addParameter(p, 'VelocityWeight', 1.0, @(x) isnumeric(x) && isscalar(x) && x >= 0);
    addParameter(p, 'ScalarWeight', 1.0, @(x) isnumeric(x) && isscalar(x) && x >= 0);
    parse(p, varargin{:});

    component_names = fieldnames(info.components);
    for k = 1:numel(component_names)
        comp = component_names{k};
        idx = info.components.(comp);
        if isnan(idx)
            continue;
        end
        switch comp
            case {'u', 'v', 'w'}
                weights(idx) = p.Results.VelocityWeight;
            otherwise
                weights(idx) = p.Results.ScalarWeight;
        end
    end
end
