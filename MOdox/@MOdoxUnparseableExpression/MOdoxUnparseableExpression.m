function obj=MOdoxUnparseableExpression(location,reason)
% instantiate a Matlab parse error object
%
% obj=MOdoxTestCaseExpression(location,reason)
%
% Inputs:
%   location                MOdoxMFileLocation instance
%   reason                  string with parsing error description


    check_inputs(location,reason);

    s=struct();
    s.location=location;
    s.reason=reason;

    obj=class(s,'MOdoxUnparseableExpression',MOdoxExpression());


function check_inputs(location,reason)
    if ~isa(location,'MOdoxMFileLocation')
        error('location must be MOdoxMFileLocation');
    end

    if ~ischar(reason)
        error('prefix must be string');
    end
