function obj=MOdoxTestCaseExpression(location,code,output_prefix,output)
% instantiate a Matlab test case expression base object
%
% obj=MOdoxTestCaseExpression(location,lines,output_prefix,output)
%
% Inputs:
%   location                MOdoxMFileLocation instance
%   lines                   cellstring with matlab code
%   output_prefix           (optional) string prefix for output
%   output                  cellstring with expected output


    check_inputs(location,code,output_prefix,output)

    s=struct();
    s.location=location;
    s.code=code;
    s.output_prefix=output_prefix;
    s.output=output;

    obj=class(s,'MOdoxTestCaseExpression',MOdoxExpression());


function check_inputs(location,code,prefix,output)
    if ~isa(location,'MOdoxMFileLocation')
        error('location must be MOdoxMFileLocation');
    end

    check_cellstr_lines(code)
    check_cellstr_lines(output)

    if ~ischar(prefix)
        error('prefix must be string');
    end


function check_cellstr_lines(lines)
    if ~iscellstr(lines)
        error('lines input must be cellstring');
    end

    size1=cellfun(@(x)size(x,1),lines);
    line_is_empty=cellfun(@isempty,lines);
    bad_size=size1~=1 & ~line_is_empty;
    if any(bad_size)
        wrong_pos=find(bad_size,1);
        error('input line %d has %d rows, must be 1',...
                        wrong_pos,size1(wrong_pos));
    end
