function token = sanitize_output_filename_token(text_value)
%SANITIZE_OUTPUT_FILENAME_TOKEN Convert one label into a filename-safe token.

    token = char(string(text_value));
    token = regexprep(token, '[\\/:*?"<>|]+', '');
    token = regexprep(token, '\s+', '_');
    token = regexprep(token, '_+', '_');
    token = regexprep(token, '^[._]+|[._]+$', '');
    if isempty(token)
        token = 'output';
    end
end
