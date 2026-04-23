function mask_out = dilate_mask_no_wrap(mask_in)
%DILATE_MASK_NO_WRAP Apply one 5-point logical dilation step without wrap-around.

    mask_in = logical(mask_in);
    mask_out = mask_in;

    mask_out(2:end, :) = mask_out(2:end, :) | mask_in(1:end-1, :);
    mask_out(1:end-1, :) = mask_out(1:end-1, :) | mask_in(2:end, :);
    mask_out(:, 2:end) = mask_out(:, 2:end) | mask_in(:, 1:end-1);
    mask_out(:, 1:end-1) = mask_out(:, 1:end-1) | mask_in(:, 2:end);
end
