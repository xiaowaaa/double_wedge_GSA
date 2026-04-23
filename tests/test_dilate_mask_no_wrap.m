function test_dilate_mask_no_wrap()
%TEST_DILATE_MASK_NO_WRAP Validate that mask dilation never wraps across boundaries.

    project_root = fileparts(fileparts(mfilename('fullpath')));
    addpath(project_root);
    addpath(fullfile(project_root, 'src', 'core'));

    top_seed = false(6, 7);
    top_seed(1, 3) = true;
    top_dilated = dilate_mask_no_wrap(top_seed);
    assert(top_dilated(1, 3) && top_dilated(2, 3), ...
        'Top seed should expand into the interior neighbor.');
    assert(top_dilated(1, 2) && top_dilated(1, 4), ...
        'Top seed should expand laterally on the same boundary row.');
    assert(~top_dilated(end, 3), ...
        'Top seed must not wrap onto the bottom boundary.');

    left_seed = false(6, 7);
    left_seed(4, 1) = true;
    left_dilated = dilate_mask_no_wrap(left_seed);
    assert(left_dilated(4, 1) && left_dilated(4, 2), ...
        'Left seed should expand into the interior neighbor.');
    assert(left_dilated(3, 1) && left_dilated(5, 1), ...
        'Left seed should expand vertically on the same boundary column.');
    assert(~left_dilated(4, end), ...
        'Left seed must not wrap onto the right boundary.');

    fprintf('[test_dilate_mask_no_wrap] PASS\n');
end
