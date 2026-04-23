function [lead_position, lead_original_index, audit] = resolve_part4_plot_lead_position(part4)
%RESOLVE_PART4_PLOT_LEAD_POSITION Resolve the sorted plotted-lead position from Part4 metadata.

    n_modes = 0;
    if isstruct(part4) && isfield(part4, 'EigVals_s')
        n_modes = numel(part4.EigVals_s);
    end

    lead_position = NaN;
    lead_original_index = NaN;
    audit = struct( ...
        'status', 'no_modes', ...
        'source', 'none', ...
        'mode_count', n_modes, ...
        'used_original_index_lookup', false);
    if n_modes <= 0
        return;
    end

    [lead_position, source] = local_first_finite_scalar(part4, { ...
        {'plot_leading_mode_position'}, ...
        {'selection_summary', 'plot_leading_mode_position'}});
    if isfinite(lead_position)
        lead_position = min(max(round(lead_position), 1), n_modes);
        lead_original_index = local_lookup_original_index(part4, lead_position);
        audit.status = 'resolved';
        audit.source = source;
        return;
    end

    if local_explicitly_has_no_plot_lead(part4)
        audit.status = 'no_physical_plot_candidate';
        audit.source = 'explicit_no_plot_lead';
        return;
    end

    [lead_original_index, source] = local_first_finite_scalar(part4, { ...
        {'plot_leading_mode_original_index'}, ...
        {'selection_summary', 'plot_leading_mode_original_index'}, ...
        {'plot_leading_mode_index'}, ...
        {'selection_summary', 'plot_leading_mode_index'}});
    if isfinite(lead_original_index)
        lead_position = local_lookup_sorted_position(part4, lead_original_index);
        if isfinite(lead_position)
            audit.status = 'resolved';
            audit.source = source;
            audit.used_original_index_lookup = true;
            return;
        end

        if lead_original_index >= 1 && lead_original_index <= n_modes
            lead_position = round(lead_original_index);
            lead_original_index = local_lookup_original_index(part4, lead_position);
            audit.status = 'legacy_direct_index';
            audit.source = source;
            return;
        end
    end

    lead_position = 1;
    lead_original_index = local_lookup_original_index(part4, lead_position);
    audit.status = 'default_first_mode';
    audit.source = 'default_first_mode';
end

function [value, source] = local_first_finite_scalar(S, field_chains)
%LOCAL_FIRST_FINITE_SCALAR Return the first finite scalar found in the requested field chains.

    value = NaN;
    source = 'none';
    for k = 1:numel(field_chains)
        chain = field_chains{k};
        [candidate, ok] = local_get_nested_scalar(S, chain);
        if ok
            value = candidate;
            source = strjoin(chain, '.');
            return;
        end
    end
end

function [value, ok] = local_get_nested_scalar(S, chain)
%LOCAL_GET_NESTED_SCALAR Follow a nested field chain and return one finite scalar when present.

    value = NaN;
    ok = false;
    current = S;
    for k = 1:numel(chain)
        name = chain{k};
        if ~isstruct(current) || ~isfield(current, name)
            return;
        end
        current = current.(name);
    end

    if isnumeric(current) && isscalar(current) && isfinite(current)
        value = current;
        ok = true;
    end
end

function tf = local_explicitly_has_no_plot_lead(part4)
%LOCAL_EXPLICITLY_HAS_NO_PLOT_LEAD True when Part4 metadata says no physical plot candidate exists.

    tf = false;
    if ~isstruct(part4)
        return;
    end

    if isfield(part4, 'selection_summary') && isstruct(part4.selection_summary)
        if isfield(part4.selection_summary, 'plot_status') && ...
                strcmp(part4.selection_summary.plot_status, 'no_physical_plot_candidates')
            tf = true;
            return;
        end
        if isfield(part4.selection_summary, 'plot_lead_status') && ...
                strcmp(part4.selection_summary.plot_lead_status, 'no_physical_plot_candidate')
            tf = true;
            return;
        end
    end

    if isfield(part4, 'mode_validity_report') && isstruct(part4.mode_validity_report) && ...
            isfield(part4.mode_validity_report, 'primary_reason') && ...
            strcmp(part4.mode_validity_report.primary_reason, 'no_physical_plot_candidate')
        tf = true;
    end
end

function lead_position = local_lookup_sorted_position(part4, original_index)
%LOCAL_LOOKUP_SORTED_POSITION Map one original mode index onto the sorted Part4 arrays.

    lead_position = NaN;
    if ~isstruct(part4) || ~isfield(part4, 'ranking_table') || ~istable(part4.ranking_table)
        return;
    end
    if ~ismember('mode_index', part4.ranking_table.Properties.VariableNames)
        return;
    end

    matches = find(part4.ranking_table.mode_index == round(original_index));
    if numel(matches) == 1
        lead_position = matches;
    end
end

function original_index = local_lookup_original_index(part4, lead_position)
%LOCAL_LOOKUP_ORIGINAL_INDEX Map one sorted position back to the original mode index when possible.

    original_index = NaN;
    if ~isstruct(part4) || ~isfield(part4, 'ranking_table') || ~istable(part4.ranking_table)
        return;
    end
    if ~ismember('mode_index', part4.ranking_table.Properties.VariableNames)
        return;
    end
    if lead_position < 1 || lead_position > height(part4.ranking_table)
        return;
    end
    original_index = part4.ranking_table.mode_index(lead_position);
end
