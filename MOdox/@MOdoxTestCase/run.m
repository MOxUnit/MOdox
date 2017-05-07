function report=run(obj,report)
% Run test associated with MOdoxTestCase
%
% report=run(obj,report)
%
% Inputs:
%   obj             MOdoxTestCase object
%   report          MoxUnitTestReport instance to which test results are to
%                   be reported.
%
% Output:
%   report          MoxUnitTestReport containing tests results
%                   after running the test associated with obj.
%
% See also: MoxUnitTestReport

    start_tic = tic();

    try
        outcome_args=run_with(getExpressions(obj));
        if isempty(outcome_args)
            % no error, so pass
            outcome_constr=@MOxUnitPassedTestOutcome;
        elseif isstruct(outcome_args)
            % failed outcome with argument in struct
            outcome_constr=@MOxUnitFailedTestOutcome;
            outcome_args={outcome_args};
        else
            % anything else, with first argument the constructor
            % (currently only used for skipped test)
            outcome_constr=outcome_args{1};
            outcome_args=outcome_args(2:end);
        end
    catch
        e=lasterror();
        outcome_constr=@MOxUnitErroredTestOutcome;
        outcome_args={e};
    end

    outcome=outcome_constr(obj,toc(start_tic),outcome_args{:});
    report = reportTestOutcome(report, outcome);



function DXD__outcome_args=run_with(DXD__expressions)
    % There is no way to protect variables in Matlab by putting them in
    % a separate scope. Thus when running evalc it could overwrite existing
    % variables. To minimize this risk, all variables are prefixed by
    % 'DXD__'. Note however that if a test sets these variables, this
    % function could really crash.

    % get reference to function handles
    DXD__get_reason_if_no_match=@get_reason_if_no_match;
    DXD__build_error_struct=@build_error_struct;
    DXD__moxunit_isa_test_skipped_exception=...
                                @moxunit_isa_test_skipped_exception;

    % by default no outcome arguments, which means a passing test
    DXD__outcome_args={};

    DXD__n_expressions=numel(DXD__expressions);
    for DXD__i=1:DXD__n_expressions
        DXD__expression=DXD__expressions{DXD__i};

        if isEvaluable(DXD__expression)
            DXD__last_error=false;
            DXD__last_output=[];

            try
                DXD__code=getCode(DXD__expression);
                DXD__code_one_line=sprintf('%s\n',DXD__code{:});
                DXD__last_output=evalc(DXD__code_one_line);
            catch
                DXD__last_error=lasterror();
            end

            DXD__has_error=isstruct(DXD__last_error);
            if DXD__has_error ...
                    && DXD__moxunit_isa_test_skipped_exception(...
                                                    DXD__last_error)

                % Skipped test exxceptionw was raised
                % or a failed test
                DXD__reason=DXD__last_error.message;
                DXD__outcome_args={@MOxUnitSkippedTestOutcome,...
                                    DXD__build_error_struct(DXD__reason,...
                                            DXD__expression)};
                return;
            else
                DXD__reason=DXD__get_reason_if_no_match(DXD__last_output,...
                                                DXD__last_error,...
                                                DXD__expression);
                if ~isempty(DXD__reason)
                    DXD__outcome_args=DXD__build_error_struct(DXD__reason,...
                                            DXD__expression);
                    return
                end
            end
        end
    end


function outcome_args=build_error_struct(reason,expression)
    % build stack
    loc=getLocation(expression);
    fn=getFilename(loc);
    [unused,nm]=fileparts(fn);

    s=struct();
    s.file=fn;
    s.name=nm;
    s.line=getLineNumber(loc);

    % build error struct
    e=struct();
    e.identifier='MOdox:testFailed';
    e.message=reason;
    e.stack=s;

    outcome_args=e;


function reason=get_reason_from_error_struct(last_error)
    stack_str=moxunit_util_stack2str(last_error.stack,'      ');
    reason=sprintf('Unexpected exception ''%s'': %s raised\n%s',...
                      last_error.identifier,...
                      last_error.message,...
                      stack_str);


function reason=get_reason_if_no_match(observed_output,...
                                        observed_error,...
                                        expr)
    reason=[];
    has_error=isstruct(observed_error);

    expected_lines=getOutput(expr);
    expected_output=sprintf('%s\n',expected_lines{:});
    if modox_is_error_expression(expected_output)
        if ~has_error
            reason=sprintf('Expected exception was not raised');
        end
    else
        if has_error
            reason=get_reason_from_error_struct(observed_error);
        else
            if ~modox_outputs_equal(expected_output, observed_output)
                desc=get_different_output_description(expr,...
                                                        observed_output);
                reason=sprintf('Outputs differ:\n%s',desc);
            end
        end
    end


function msg=get_different_output_description(expr,found_output)
    found_output=remove_ans_eq(found_output);
    found_lines=regexp(found_output,sprintf('\n'),'split');

    prefix=getOutputPrefix(expr);
    exp_lines=getOutput(expr);

    % print with comment prefix so that true output can more easily be
    % copy-pasted
    comment_prefix='%     ';
    suffix=' ';
    full_prefix=[comment_prefix, prefix, suffix];

    found_str=concat_with_prefix(full_prefix,found_lines);
    exp_str=concat_with_prefix(full_prefix,exp_lines);

    msg=sprintf('Found:\n%s\n\nExpected:\n%s\n',...
                found_str,exp_str);


function s=concat_with_prefix(prefix,lines)
    lines_with_prefix=cellfun(@(x)[prefix x],lines,'UniformOutput',false);
    s=sprintf('%s\n',lines_with_prefix{:});


function line=remove_ans_eq(line)
    line=regexprep(line,'^\s*ans\s*=','');




