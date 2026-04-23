function test_paperA_phase_anchor()
%TEST_PAPERA_PHASE_ANCHOR Ensure phase anchoring prefers bubble support over global peaks.

    project_root = fileparts(fileparts(mfilename('fullpath')));
    addpath(project_root);
    addpath(fullfile(project_root, 'src', 'core'));

    Ny = 16;
    Nx = 18;
    layout = get_state_layout_info('primitive5_u_v_w_T_p');
    q_mode = complex(zeros(layout.nvar * Ny * Nx, 1));

    bubble_mask = false(Ny, Nx);
    bubble_mask(2:5, 6:9) = true;
    near_wall_mask = false(Ny, Nx);
    near_wall_mask(1:3, :) = true;
    [X, Y] = meshgrid(1:Nx, 1:Ny);

    u_field = zeros(Ny, Nx);
    u_field(3, 7) = 1i;
    u_field(12, 15) = 5.0;  % larger global peak, but outside the bubble window
    q_mode(layout.components.u:layout.nvar:end) = u_field(:);

    [phase_factor, audit] = choose_mode_phase_factor(q_mode, Ny, Nx, layout.name, ...
        'BubbleMask', bubble_mask, 'NearWallMask', near_wall_mask, 'X', X, 'Y', Y);

    aligned_u = extract_state_component(q_mode * phase_factor, Ny, Nx, layout.name, 'u');
    assert(strcmp(audit.type, 'bubble'), 'Phase anchor should prefer the bubble mask.');
    assert(abs(imag(aligned_u(3, 7))) < 1.0e-12 && real(aligned_u(3, 7)) > 0, ...
        'Bubble anchor should be rotated to a positive real value.');

    w_field = zeros(Ny, Nx);
    w_field(4, 8) = -2i;
    w_field(12, 15) = 7.0;
    q_mode(layout.components.w:layout.nvar:end) = w_field(:);

    [phase_factor, audit] = choose_mode_phase_factor(q_mode, Ny, Nx, layout.name, ...
        'BubbleMask', bubble_mask, 'NearWallMask', near_wall_mask, ...
        'X', X, 'Y', Y, 'ReferenceComponent', 'w');

    aligned_w = extract_state_component(q_mode * phase_factor, Ny, Nx, layout.name, 'w');
    assert(strcmp(audit.component, 'w'), ...
        'A w-dominant mode should use w'' as the phase-anchor component.');
    assert(strcmp(audit.type, 'bubble'), ...
        'Reference-component phase anchoring should still prefer the bubble mask.');
    assert(abs(imag(aligned_w(4, 8))) < 1.0e-12 && real(aligned_w(4, 8)) > 0, ...
        'The w'' bubble anchor should be rotated to a positive real value.');

    fprintf('[test_paperA_phase_anchor] PASS\n');
end
