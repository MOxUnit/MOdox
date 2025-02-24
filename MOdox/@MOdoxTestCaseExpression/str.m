function s = str(obj)
    % Return string representation of expression

    code = getCode(obj);

    prefix = getOutputPrefix(obj);
    add_prefix_func = @(line)[prefix line];
    output = cellfun(add_prefix_func, getOutput(obj), 'UniformOutput', false);

    code_str = sprintf('%s\n', code{:});
    output_str = sprintf('%s\n', output{:});
    s = sprintf('%s\n%s', code_str, output_str);
