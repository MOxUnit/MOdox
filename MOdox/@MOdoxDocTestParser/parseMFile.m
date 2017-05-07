function expressions=parseMFile(obj,mfile_name)
% return MOdox Expressions from .m file
%
% expressions=getExpressions(obj,mfile_name)
%
% Inputs:
%   obj                     MOdoxDocTestParser object
%   mfile_name              String with name of file
%
% Output:
%   doctest_lines           cellstring with MOdoxExpression subclasses,
%                           i.e. each element is one of
%                           - MOdoxNoOutputExpression
%                           - MOdoxOutputExpression
%                           - MOdoxExpectedStringExpression

    all_lines=getHelpLines(obj,mfile_name);
    expressions=parseLines(obj,mfile_name,all_lines);
