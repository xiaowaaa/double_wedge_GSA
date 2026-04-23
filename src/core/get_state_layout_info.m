function info = get_state_layout_info(layout_name)
%GET_STATE_LAYOUT_INFO Return metadata for supported perturbation layouts.

    layout_name = char(string(layout_name));
    info = struct();
    info.name = layout_name;

    switch layout_name
        case 'primitive5_u_v_w_T_p'
            info.nvar = 5;
            info.variable_names = {'u', 'v', 'w', 'T', 'p'};
            info.components = struct('rho', NaN, 'u', 1, 'v', 2, 'w', 3, 'T', 4, 'p', 5);
        otherwise
            error('get_state_layout_info:UnsupportedLayout', ...
                'Unsupported state layout "%s".', layout_name);
    end
end
