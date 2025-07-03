function tf = modox_outputs_equal(expected, observed)
    % Indicates whether two output are equal
    %
    % tf=modox_outputs_equal(expected, observed)
    %
    % Inputs:
    %   expected                string with expected output
    %   observed                string with observed output
    %
    % Output:
    %   tf                      true if expected and observed are the same,
    %                           modulo whitespace

    check_inputs(expected, observed);

    tf = output_matches(expected, observed);

    % Indicates wther

function tf = output_matches(exp_str, found_str)
    for without_ans = [false, true]
        if without_ans
            found_str = remove_ans_eq(found_str);
        end

        exp_lines = regexp(exp_str, sprintf('\n'), 'split');
        found_lines = regexp(found_str, sprintf('\n'), 'split');

        exp_lines = clean_lines(exp_lines);
        found_lines = clean_lines(found_lines);

        % strings equal modulo whitespace, pass
        if is_equal_modulo_whitespace(exp_lines, found_lines)
            tf = true;
            return
        end
    end

    % not equal, try conversion to numeric
    [exp_num, exp_ok] = lines2numeric(exp_lines);
    [found_num, found_ok] = lines2numeric(found_lines);

    if exp_ok && ...
            found_ok && ...
            isequal_nan_wrapper(exp_num, found_num)
        tf = true;
        return
    end

    % try to evaluate expected as expression
    try
        exp_str = evalc(sprintf('%s\n', exp_lines{:}));
    catch
        tf = false;
        return
    end

    exp_str = remove_ans_eq(exp_str);

    tf = isequal(exp_str, found_str);

function tf = is_equal_modulo_whitespace(a_cell, b_cell)
    splitter = @(x_cell)regexp(sprintf('%s ', x_cell{:}), '\s+', 'split');
    a = splitter(a_cell);
    b = splitter(b_cell);

    tf = isequal(a, b);

function tf = isequal_nan_wrapper(a, b)
    if ~isempty(which('isequaln', 'builtin'))
        tf = isequaln(a, b);
    else
        tf = isequalwithequalnans(a, b);
    end

function [numeric, is_ok] = lines2numeric(lines)
    [numeric, is_ok] = str2num(sprintf('%s\n', lines{:}));

function line = remove_ans_eq(line)
    line = regexprep(line, '^\s*ans\s*=', '');

function lines = clean_lines(lines)
    % remove repeated whitespace
    lines = regexprep(lines, '\s+', ' ');

    % replace ASCII character 215 (representing multiplication sign in
    % Matlab) by the 'x' sign
    lines = strrep(lines, char(215), 'x');

    % trim at begin and end
    lines = regexprep(lines, '^\s+', '');
    lines = regexprep(lines, '\s+$', '');

    % remove empty lines at begin and end
    isempty_msk = cellfun(@isempty, lines);
    first = find(~isempty_msk, 1, 'first');
    last = find(~isempty_msk, 1, 'last');

    keep_idxs = first:last;
    lines = lines(keep_idxs);
    lines = lines(:);

function check_inputs(varargin)
    for k = 1:numel(varargin)
        if ~ischar(varargin{k})
            error('Argument %d must be a string', k);
        end
    end
