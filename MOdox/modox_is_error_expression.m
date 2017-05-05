function tf=modox_is_error_expression(expr)
% returns whether an expression is one that calls builtin 'error'
%
% tf=modoxunit_util_is_error_expression_basics(expr)
%
% Input:
%   expr                    Expression that can be evaluated
%
% Output:
%   tf                      true if expression starts with 'error('
%                           (modulo whitespace), false otherwise
%

    if ~ischar(expr)
        error('Input must be a string, found %s', class(expr));
    end

    tf=~isempty(regexp(expr,'^\s*error\s*','once'));