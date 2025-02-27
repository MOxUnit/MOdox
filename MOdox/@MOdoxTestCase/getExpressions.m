function expr = getExpressions(obj)
    % Return expressions part of this instance
    %
    % exprs=getExpressions(obj)
    %
    % Input:
    %   obj             MOdoxTestCase object
    %
    % Output:
    %   expr           cell with MOdoxExpression instances

    expr = obj.expressions;
