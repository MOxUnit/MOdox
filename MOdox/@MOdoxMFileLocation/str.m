function s = str(obj)
    % return string representation number

    s = sprintf('%s: %d', getFilename(obj), getLineNumber(obj));
