function obj = MOdoxTestCase(name, location, expressions)
    % instantiate a MOdoxTestCase documentation test case
    %
    % obj=MOdoxTestCase(expression)
    %
    % Inputs:
    %   expression              MOdoxExpression instances
    %

    verify_input(expressions);

    s = struct();
    s.expressions = expressions;

    obj = class(s, 'MOdoxTestCase', MOxUnitTestCase(name, location));

function verify_input(expressions)
    if ~(iscell(expressions) && ...
         all(cellfun(@(x)isa(x, 'MOdoxExpression'), expressions)))
        error(['Third argument must be a cell with '...
               'MOdoxExpression instances']);
    end
