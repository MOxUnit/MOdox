function obj = MOdoxMFileLocation(filename, line_number)
    % Initialize .m file location
    %
    % Input:
    %   name            Filename
    %   line_number     line number
    % Output:
    %   obj             MOdoxMFileLocation instance

    check_inputs(filename, line_number);

    s = struct();
    s.filename = filename;
    s.line_number = line_number;
    obj = class(s, 'MOdoxMFileLocation');

function check_inputs(filename, line_number)
    if ~ischar(filename)
        error('first input must be a string');
    end

    if ~isnumeric(line_number) || numel(line_number) ~= 1
        error('second input must be numeric');
    end
