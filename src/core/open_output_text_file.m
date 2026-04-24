function fid = open_output_text_file(output_file)
%OPEN_OUTPUT_TEXT_FILE Open one user-facing text output with UTF-8 encoding.

    fid = -1;
    try
        fid = fopen(output_file, 'w', 'n', 'UTF-8');
    catch
        fid = fopen(output_file, 'w');
        return;
    end

    if fid ~= -1
        fwrite(fid, uint8([239, 187, 191]), 'uint8');
    end
end
