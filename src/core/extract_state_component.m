function field = extract_state_component(q_mode, Ny, Nx, layout_name, component_name)
%EXTRACT_STATE_COMPONENT Reshape one modal component on the Ny-by-Nx grid.

    info = get_state_layout_info(layout_name);
    component_name = char(string(component_name));
    if ~isfield(info.components, component_name)
        error('extract_state_component:Component', ...
            'Unsupported component "%s".', component_name);
    end

    comp_idx = info.components.(component_name);
    if isnan(comp_idx)
        field = NaN(Ny, Nx);
        return;
    end

    expected_len = info.nvar * Ny * Nx;
    if numel(q_mode) ~= expected_len
        error('extract_state_component:Size', ...
            'Expected %d entries for %s on a %d x %d grid, got %d.', ...
            expected_len, layout_name, Nx, Ny, numel(q_mode));
    end

    field = reshape(q_mode(comp_idx:info.nvar:end), Ny, Nx);
end
