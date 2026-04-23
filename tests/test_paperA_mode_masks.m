function test_paperA_mode_masks()
%TEST_PAPERA_MODE_MASKS Validate the shared bubble/near-wall/shock masks.

    project_root = fileparts(fileparts(mfilename('fullpath')));
    addpath(project_root);
    addpath(fullfile(project_root, 'src', 'core'));

    Ny = 20;
    Nx = 24;
    [X, Y] = meshgrid(linspace(0.0, 2.0, Nx), linspace(0.0, 1.0, Ny));
    U = ones(Ny, Nx);
    U(1:4, 7:12) = -0.2;

    data = struct();
    data.U = U;
    data.Y = Y;
    corner_mask = false(Ny, Nx);
    corner_mask(1:2, 5:6) = true;
    bad_point_mask = false(Ny, Nx);
    bad_point_mask(10, 14) = true;
    shock_mask = false(Ny, Nx);
    shock_mask(6:9, 14:17) = true;
    shock_raw = shock_mask;
    shock_raw(1, 15) = true;
    data.BaseflowMasks = struct( ...
        'shock_mask', false(Ny, Nx), ...
        'corner_mask', corner_mask, ...
        'eos_bad_point_mask', bad_point_mask);
    data.ShockInfo = struct( ...
        'shock_mask', shock_mask, ...
        'shock_raw', shock_raw);

    Config = struct();
    Config.mode_filter = struct('near_wall_fraction', 0.15);

    masks = build_paperA_mode_masks(data, Config, Ny, Nx);

    assert(any(masks.bubble(:)), 'Bubble mask should detect the U<0 patch.');
    assert(nnz(masks.near_wall(1:3, :)) > 0, 'Near-wall mask should cover the south-edge band.');
    assert(~any(masks.free_stream(1:5, :), 'all'), 'Free-stream mask should exclude the lowest part of the domain.');
    assert(all(size(masks.shock) == [Ny, Nx]), 'Shock mask size should match the working grid.');
    assert(~masks.shock_core(1, 15), 'Shock-core mask must stay inside the protected Part3 shock band.');
    assert(masks.shock_core(6, 15), 'Shock-core mask should preserve valid interior shock cells.');
    assert(any(masks.outlet(:, end)), 'Outlet mask should cover the downstream edge.');
    assert(all(~masks.outlet_wall(~masks.near_wall)), 'Outlet-wall mask must stay inside the near-wall strip.');
    assert(isequal(masks.corner, corner_mask), 'Corner mask should pass through from BaseflowMasks.');
    assert(isequal(masks.bad_point, bad_point_mask), 'EOS bad-point mask should pass through from BaseflowMasks.');

    fprintf('[test_paperA_mode_masks] PASS\n');
end
