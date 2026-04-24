function tbl_out = localize_output_table_for_text(tbl_in)
%LOCALIZE_OUTPUT_TABLE_FOR_TEXT Make text-dump tables more Chinese-friendly.

    tbl_out = tbl_in;
    if ~istable(tbl_in)
        return;
    end

    original_names = tbl_in.Properties.VariableNames;
    for k = 1:numel(original_names)
        name = original_names{k};
        tbl_out.(name) = local_translate_table_values(tbl_in.(name));
    end

    new_names = cell(size(original_names));
    for k = 1:numel(original_names)
        original_name = original_names{k};
        candidate = local_translate_header(original_name);
        candidate = matlab.lang.makeValidName(candidate, 'ReplacementStyle', 'delete');
        if isempty(candidate) || (~startsWith(lower(original_name), 'x') && ...
                ~isempty(regexp(candidate, '^x(_\d+)?$', 'once')))
            candidate = original_name;
        end
        new_names{k} = candidate;
    end
    new_names = matlab.lang.makeUniqueStrings(new_names, {}, namelengthmax);
    tbl_out.Properties.VariableNames = new_names;
end

function value_out = local_translate_table_values(value_in)
%LOCAL_TRANSLATE_TABLE_VALUES Localize one table variable when it is textual.

    value_out = value_in;
    if isstring(value_in)
        value_out = arrayfun(@(x) string(local_translate_text(char(x))), value_in);
    elseif iscell(value_in) && all(cellfun(@(x) ischar(x) || (isstring(x) && isscalar(x)), value_in(:)))
        value_out = cellfun(@(x) local_translate_text(char(string(x))), value_in, 'UniformOutput', false);
    elseif iscategorical(value_in)
        cell_value = cellstr(value_in);
        cell_value = cellfun(@local_translate_text, cell_value, 'UniformOutput', false);
        value_out = categorical(cell_value);
    end
end

function header = local_translate_header(name)
%LOCAL_TRANSLATE_HEADER Translate one table header with conservative overrides.

    switch lower(strtrim(name))
        case 'quantity'
            header = '量项';
        case 'your_run'
            header = '当前结果';
        case 'literature'
            header = '文献';
        case 'note'
            header = '说明';
        case 'position'
            header = '位置';
        case {'original_index', 'originalindex'}
            header = '原始索引';
        case 'stationary_or_oscillatory'
            header = '定常振荡属性';
        case 'selected_for_plots'
            header = '用于绘图';
        case 'selected_for_publication'
            header = '用于发表';
        case 'mode_index'
            header = '模态索引';
        case 'source_case'
            header = '来源算例';
        case 'gain'
            header = '增益';
        case 'sigma_min'
            header = '最小奇异值';
        otherwise
            header = localize_output_label(name);
    end
end

function text_out = local_translate_text(text_in)
%LOCAL_TRANSLATE_TEXT Translate one compact status/token string when helpful.

    text_out = char(string(text_in));
    key = lower(strtrim(text_out));
    if isempty(key)
        return;
    end

    switch key
        case 'geometry'
            text_out = '几何';
        case 'wall_bc'
            text_out = '壁面边界条件';
        case 'separation_x'
            text_out = '分离点x';
        case 'reattachment_x'
            text_out = '再附点x';
        case 'bubble_length'
            text_out = '分离泡长度';
        case 'delta99_at_separation'
            text_out = '分离点delta99';
        case 'bubble_centred'
            text_out = '分离泡主导';
        case 'boundary_supported'
            text_out = '边界支撑';
        case 'compact_interior_candidate'
            text_out = '紧凑内域候选';
        case 'stationary'
            text_out = '定常';
        case 'oscillatory'
            text_out = '振荡';
        case 'resolved'
            text_out = '已解析';
        case 'plot_leading_mode_position'
            text_out = '绘图主模态位置';
        case 'papera_physical_mode'
            text_out = 'PaperA物理模态';
        case 'code_correction_stage'
            text_out = '代码修正阶段';
        case 'physical_plot_candidates_available'
            text_out = '存在物理绘图候选';
        case {'no_physical_plot_candidate', 'no_physical_plot_candidates'}
            text_out = '无物理绘图候选';
        case 'adiabatic_wall_literature_target'
            text_out = '绝热壁文献目标';
        otherwise
            if ~isempty(regexp(text_out, '^[A-Za-z0-9_\-\s]+$', 'once'))
                candidate = localize_output_label(text_out);
                if ~strcmp(candidate, text_out)
                    text_out = candidate;
                end
            end
    end
end
