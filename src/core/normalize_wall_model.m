function wall_model = normalize_wall_model(value, varargin)
%NORMALIZE_WALL_MODEL Map accepted wall-model labels to canonical values.

    p = inputParser;
    p.FunctionName = 'normalize_wall_model';
    addParameter(p, 'ErrorIdentifier', 'normalize_wall_model:InvalidValue', ...
        @(x) ischar(x) || (isstring(x) && isscalar(x)));
    parse(p, varargin{:});

    if nargin < 1 || isempty(value)
        value = 'adiabatic';
    end

    key = lower(strtrim(char(string(value))));
    switch key
        case {'adiabatic', 'adiabatic_wall', 'adiabaticwall', 'wall_adiabatic'}
            wall_model = 'adiabatic';
        case {'isothermal', 'isothermal_wall', 'isothermalwall', ...
                'wall_isothermal', 'fixed_temperature', 'constant_temperature'}
            wall_model = 'isothermal';
        otherwise
            error(char(string(p.Results.ErrorIdentifier)), ...
                'Unsupported wall thermal model "%s". Use "adiabatic" or "isothermal".', ...
                char(string(value)));
    end
end
