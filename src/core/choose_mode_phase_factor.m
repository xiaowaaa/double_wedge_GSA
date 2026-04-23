function [phase_factor, anchor_info] = choose_mode_phase_factor(q_mode, Ny, Nx, layout_name, varargin)
%CHOOSE_MODE_PHASE_FACTOR Pick a phase anchored in bubble, then near-wall, then global support.

    p = inputParser;
    p.FunctionName = 'choose_mode_phase_factor';
    addParameter(p, 'BubbleMask', [], @(x) isempty(x) || islogical(x) || isnumeric(x));
    addParameter(p, 'NearWallMask', [], @(x) isempty(x) || islogical(x) || isnumeric(x));
    addParameter(p, 'X', [], @(x) isempty(x) || isnumeric(x));
    addParameter(p, 'Y', [], @(x) isempty(x) || isnumeric(x));
    addParameter(p, 'ReferenceComponent', 'u', @(x) isempty(x) || ischar(x) || (isstring(x) && isscalar(x)));
    parse(p, varargin{:});

    info = get_state_layout_info(layout_name);
    requested_component = local_normalize_component_name(p.Results.ReferenceComponent);
    anchor_info = struct( ...
        'type', 'global', ...
        'row', NaN, ...
        'col', NaN, ...
        'x', NaN, ...
        'y', NaN, ...
        'component', '', ...
        'requested_component', requested_component);

    candidate = 0;
    peak_row = NaN;
    peak_col = NaN;
    anchor_type = 'none';
    anchor_component = '';
    component_order = local_anchor_component_order(requested_component);
    for c = 1:numel(component_order)
        component_name = component_order{c};
        if ~local_has_component(info, component_name)
            continue;
        end
        component_field = extract_state_component(q_mode, Ny, Nx, layout_name, component_name);
        [candidate, peak_row, peak_col, anchor_type] = local_pick_candidate( ...
            component_field, p.Results.BubbleMask, p.Results.NearWallMask);
        if ~strcmp(anchor_type, 'none')
            anchor_component = component_name;
            break;
        end
    end
    if strcmp(anchor_type, 'none')
        nonzero = q_mode(abs(q_mode) > 0);
        if ~isempty(nonzero)
            candidate = nonzero(1);
            anchor_type = 'global';
            anchor_component = 'state_vector';
        end
    end

    if candidate == 0
        phase_factor = 1.0;
    else
        phase_factor = exp(-1i * angle(candidate));
    end

    anchor_info.type = anchor_type;
    anchor_info.row = peak_row;
    anchor_info.col = peak_col;
    anchor_info.component = anchor_component;
    if ~isempty(p.Results.X) && ~isempty(p.Results.Y) && isfinite(peak_row) && isfinite(peak_col)
        anchor_info.x = p.Results.X(peak_row, peak_col);
        anchor_info.y = p.Results.Y(peak_row, peak_col);
    end
end

function [candidate, peak_row, peak_col, anchor_type] = local_pick_candidate(component_field, bubble_mask, near_wall_mask)
%LOCAL_PICK_CANDIDATE Choose the phase anchor from bubble, near-wall, or global support.

    amp = abs(component_field);
    [candidate, peak_row, peak_col, found] = local_pick_from_mask(component_field, bubble_mask);
    if found
        anchor_type = 'bubble';
        return;
    end

    [candidate, peak_row, peak_col, found] = local_pick_from_mask(component_field, near_wall_mask);
    if found
        anchor_type = 'near_wall';
        return;
    end

    [~, peak_idx] = max(amp(:));
    if isempty(peak_idx) || amp(peak_idx) <= 0
        candidate = 0;
        peak_row = NaN;
        peak_col = NaN;
        anchor_type = 'none';
    else
        [peak_row, peak_col] = ind2sub(size(component_field), peak_idx);
        candidate = component_field(peak_row, peak_col);
        anchor_type = 'global';
    end
end

function [candidate, peak_row, peak_col, found] = local_pick_from_mask(field, mask)
%LOCAL_PICK_FROM_MASK Return the strongest value inside one logical mask.

    found = false;
    candidate = 0;
    peak_row = NaN;
    peak_col = NaN;
    if isempty(mask)
        return;
    end

    mask = logical(mask);
    if ~any(mask(:))
        return;
    end

    masked_amp = abs(field);
    masked_amp(~mask) = 0;
    [peak_value, peak_idx] = max(masked_amp(:));
    if isempty(peak_idx) || peak_value <= 0
        return;
    end

    [peak_row, peak_col] = ind2sub(size(field), peak_idx);
    candidate = field(peak_row, peak_col);
    found = true;
end

function component_order = local_anchor_component_order(requested_component)
%LOCAL_ANCHOR_COMPONENT_ORDER Prefer the requested component, then safe fallbacks.

    base_order = {'u', 'w', 'v', 'T', 'p'};
    if isempty(requested_component)
        component_order = base_order;
        return;
    end
    component_order = [{requested_component}, base_order];
    [~, unique_idx] = unique(component_order, 'stable');
    component_order = component_order(sort(unique_idx));
end

function tf = local_has_component(info, component_name)
%LOCAL_HAS_COMPONENT True when the current state layout exposes one component.

    tf = isfield(info.components, component_name) && ~isnan(info.components.(component_name));
end

function component_name = local_normalize_component_name(component_name)
%LOCAL_NORMALIZE_COMPONENT_NAME Normalize one optional component selector.

    if isempty(component_name)
        component_name = '';
    else
        component_name = char(string(component_name));
        component_name = strtrim(component_name);
    end
end
