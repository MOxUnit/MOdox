function test_suite = test_modox_doc_test_case
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;

function s=randstr()
    s=char(ceil(rand(1,ceil(rand()*8+2))*24+64));

function loc=randloc()
    loc=MOdoxMFileLocation(randstr(),ceil(rand()*100));


function test_test_case_exceptions
    aet=@(varargin)assertExceptionThrown(@()...
                        MOdoxTestCase(varargin{:}),'');
    name=randstr();
    location=randloc();
    aet(struct,name,location);
    aet({2},name,location);

function test_multiple_cases

    code_output_cell={{'a=2;','disp(a)'},{' 2'};...
                        {'b=a*a;','disp(b)'},{' 4'} };
    assert_passes(code_output_cell);



function test_test_case_str
    name=randstr();
    location=randloc();

    prefix='%>> ';
    make_lines_func=arrayfun(@(unused)randstr(),1:(ceil(rand()*10+3)),...
                                 'UniformOutput',false);

    code=make_lines_func();
    output=make_lines_func();

    expr=MOdoxTestCaseExpression(location,code,prefix,output);
    test_case=MOdoxTestCase(name,location,{expr});

    assert(~isempty(findstr(str(location),str(test_case))));




function outcome=get_test_outcome(code_output_cell)
    output_prefix='%||>';

    assert(iscell(code_output_cell));
    assert(size(code_output_cell,2)==2);

    n_expr=size(code_output_cell,1);
    exprs=cell(n_expr,1);
    for k=1:n_expr
        code=code_output_cell{k,1};
        output=code_output_cell{k,2};

        location=randloc();
        expr=MOdoxTestCaseExpression(location,code,...
                                    output_prefix,output);
        exprs{k}=expr;
    end

    name=randstr();
    location=getLocation(exprs{end});

    test_case=MOdoxTestCase(name,location,exprs);
    assertEqual(getName(test_case),name);
    assertEqual(getLocation(test_case),location);
    assertEqual(getExpressions(test_case),exprs);

    verbosity=0;
    report=MOxUnitTestReport(verbosity);
    report=run(test_case,report);

    assertEqual(1,countTestOutcomes(report));
    outcome=getTestOutcome(report,1);


function assert_passes(code_output_cell)
    outcome=get_test_outcome(code_output_cell);
    if ~strcmp(class(outcome),'MOxUnitPassedTestOutcome')
        desc=getSummaryStr(outcome,'text');
        error(desc);
    end



function test_multiplication_sign()
    % newer versions of matlab use the multiplication sign (ASCII character
    % 215) instead of the 'x' to indicate sizes of fields
    if moxunit_util_platform_is_octave()
        reason='''disp'' is only tested for matlab';
        moxunit_throw_test_skipped_exception(reason);
    end

    code_output_cell={{'a=struct();',...
                        'a.samples=randn(10);',...
                        'disp(a)'},...
                                {'  samples: [10x10 double]'}};

    assert_passes(code_output_cell);


function pass_cases=get_pass_cases()
    pass_cases={...
                {'',{''}},...
                {'2',{'2'}},...
                {'disp(3)','%',{'3'}},...
                {'disp(3)','%','disp(4)',{'3','4'}},...
                {'1+[2 3]','% foo','  % bar',{'3 4'}},...
                {'error(''here'')',{'error(''here'')'}},...
               };

function fail_cases=get_fail_cases()
    fail_cases={...
                {'2',{'3'}},...
                {'disp(3)','%',{'4'}},...
                {'disp(3)','%','disp(4)',{'4'}},...
                {'1+[2 3]','% foo','  % bar',{''}},...
                {'error(''here'')',{'2'}},...
               };

function skip_cases=get_skip_cases()
    skip_cases={...
                {'moxunit_throw_test_skipped_exception(''foo'')',{'X'}},...
                };


function test_test_cases
    % each element has contain the code lines to be executed, with the
    % last value in each a cell with expected output
    all_cases={@MOxUnitPassedTestOutcome, get_pass_cases();...
               @MOxUnitFailedTestOutcome, get_fail_cases();...
               @MOxUnitSkippedTestOutcome, get_skip_cases()};

    output_prefix='%||>';

    n_sets=size(all_cases,1);
    for i_set=1:n_sets
        row=all_cases(i_set,:);
        assert(numel(row)==2);

        cls_str=func2str(row{1});
        cases_cell=row{2};

        for i_case=1:numel(cases_cell)
            name=randstr();
            location=randloc();

            expr_args=cases_cell{i_case};
            code=expr_args(1:(end-1));
            output=expr_args{end};
            expr=MOdoxTestCaseExpression(location,code,...
                                            output_prefix,output);

            exprs={expr};
            test_case=MOdoxTestCase(name,location,exprs);
            assertEqual(getName(test_case),name);
            assertEqual(getLocation(test_case),location);
            assertEqual(getExpressions(test_case),exprs);

            verbosity=0;
            report=MOxUnitTestReport(verbosity);
            report=run(test_case,report);

            assertEqual(1,countTestOutcomes(report));
            outcome=getTestOutcome(report,1);

            is_correct_class=isa(outcome,cls_str);

            if ~is_correct_class
                error('outcome is %s, not %s:\n%s',...
                                            class(outcome),...
                                            cls_str,...
                                            getSummaryStr(outcome,'text'));
            end
        end
    end

function test_modox_main
    for n_pass=0:2
        for n_fail=0:2
            if n_pass==0 && n_fail==0
                continue;
            end
        end
        temp_dir=tempname();
        all_fns_cell={write_test_cases(temp_dir,get_pass_cases(),n_pass),...
                      write_test_cases(temp_dir,get_fail_cases(),n_fail)};
        msk=[n_pass>0, n_fail>0];
        fns_cell=all_fns_cell(msk);
        fns=cat(1,fns_cell{:});

        file_cleaner=onCleanup(@()delete_files_in_dir(temp_dir,fns));

        expected_result=n_fail==0;

        more_args={};
        % try with multiple files
        result=modox_runtests_wrapper(fns{:},more_args{:});
        assertEqual(result,expected_result);

        % try with directory
        result=modox_runtests_wrapper(temp_dir,more_args{:});
        assertEqual(result,expected_result);

        % try with running directory from the directory
        cur_pwd=pwd();
        pwd_resetter=onCleanup(@()cd(cur_pwd));
        cd(temp_dir);
        [result,output]=modox_runtests_wrapper(more_args{:},...
                                        '-verbose','-recursive');
        assertEqual(result,expected_result);
        assert_contains_if_else(result,output,'OK','FAILED');

        clear pwd_resetter;
        clear file_cleaner;
    end

function [result,output]=modox_runtests_wrapper(varargin)
    arg_str=sprintf('''%s'',',varargin{:});
    to_eval=sprintf('result=modox_runtests(%s);',arg_str(1:(end-1)));

    output=evalc(to_eval);

function assert_contains_if_else(flag,needle,if_true,if_false)
    assertEqual(~flag,isempty(findstr(needle,if_true)));
    assertEqual(flag,isempty(findstr(needle,if_false)));



function fns=write_test_cases(dir_name,case_specs,fn_count)
    if ~isdir(dir_name)
        mkdir(dir_name);
    end

    parser=MOdoxDocTestParser();
    output_prefix=getOutputPrefix(parser);

    fns=cell(fn_count,1);
    for k=1:fn_count
        function_name=randstr();
        fn=fullfile(dir_name,sprintf('%s.m',function_name));

        case_count=ceil(rand()*3+3);

        head_part={sprintf('function %s',function_name),...
                            '','% Examples:'};
        indent='%  ';
        add_prefix=@(pf,xs)cellfun(@(x)[pf x],xs,'UniformOutput',false);

        parts_cell=cell(3,case_count);
        for j=1:case_count
            % sample with replacement
            idx=ceil(rand()*numel(case_specs));

            case_spec=case_specs{idx};
            parts_cell{1,j}=add_prefix(indent,...
                                            case_spec(1:(end-1)));
            parts_cell{2,j}=add_prefix([indent output_prefix],...
                                            case_spec{end});
            parts_cell{3,j}=add_prefix('%',{''});
        end

        parts=cat(2,parts_cell(:)');

        tail_part={'% end','foo'};

        all_elems=cat(2,head_part,parts{:},tail_part);

        fid=fopen(fn,'w');
        closer=onCleanup(@()fclose(fid));
        fprintf(fid,'%s\n',all_elems{:});
        clear closer;

        fns{k}=fn;
    end


function delete_files_in_dir(dir_name,fns)
    for k=1:numel(fns)
        delete(fns{k});
    end

    rmdir(dir_name);


function test_modox_main_exceptions
    aet=@(varargin)assertExceptionThrown(@()...
                        modox_runtests(varargin{:}),'');

    aet(tempname());
    aet('-foo');
    aet(struct);
