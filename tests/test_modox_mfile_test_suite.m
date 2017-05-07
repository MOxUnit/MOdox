function test_suite = test_modox_mfile_test_suite
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;

function passing=get_passing()
    passing={{'disp(2)',output('2')},...
             {'3+4',output('7')},...
             {'2+[1 2]',output('3 4')},...
             {'2+[1 2]',output('   [  3   4  ]')},...
             {'2+[3;4]',output(' 5'),output(' 6')},...
             {'% comment','2',output('2')},...
             };

function failing=get_failing()
    failing={{'disp(2)',output('3')},...
            {'3+4',output(' 8')},...
            {'[3;4]',output(' [3 4]')},...
            {'2+3',output( ' foo')},...
            {'3+4',output('%> 7')},...
            };          % separator


function as_output=output(s)
    parser=MOdoxDocTestParser();
    prefix=getOutputPrefix(parser);

    as_output=sprintf('%s%s',prefix,s);

function test_modox_mfile_test_suite_single_passing()
    helper_test_single_with_cell(get_passing(),true);

function test_modox_mfile_test_suite_single_failing
    helper_test_single_with_cell(get_failing(),false)

function helper_test_single_with_cell(cell_lines,expected_pass)
    for k=1:numel(cell_lines)
        helper_test_with(cell_lines(k),expected_pass);
    end

function test_multiple_mixed
    passing_failing_cell={get_passing(),get_failing};
    ntests=ceil(rand()*5+10);

    expected_pass=false(ntests,1);
    all_lines_cell=cell(1,ntests);
    for k=1:ntests
        is_passing=rand()>.5;
        if is_passing
            index=1;
        else
            index=2;
        end

        lines_cell=passing_failing_cell{index};
        pos=ceil(rand()*numel(lines_cell));

        all_lines_cell{k}=lines_cell{pos};

        expected_pass(k)=is_passing;
    end

    helper_test_with(all_lines_cell,expected_pass);


function helper_test_with(lines_cell,should_pass)
    for split_singleton=[false,true]
        helper_test_with_singleton(lines_cell,should_pass,split_singleton);
    end


function helper_test_with_singleton(lines_cell,should_pass,split_singleton)
    ntests=numel(should_pass);

    if split_singleton
        fns=write_mfiles(lines_cell);
    else
        empty_lines_cell=repmat({'  '},1,ntests);

        % make tests with whitespace in between
        all_lines_cell=reshape([lines_cell; empty_lines_cell],1,[]);
        all_lines=cat(2,all_lines_cell{:});
        fns=write_mfiles({all_lines});
    end

    cleaner=onCleanup(@()delete_files(fns));

    for add_one_by_one=[false,true]
        suite=MOdoxTestSuite();

        if add_one_by_one
            for k=1:numel(fns)
                fn=fns{k};
                suite=addFromFile(suite,fn);
            end
        else
            parent_dir=fileparts(fns{1});
            suite=addFromDirectory(suite,parent_dir,'.*\.m');
        end

        assert(isa(suite,'MOxUnitTestSuite'));
        assertEqual(countTestCases(suite),ntests);

        report=MOxUnitTestReport(0,1,'foo');
        report=run(suite,report);

        assertEqual(wasSuccessful(report),all(should_pass));

        ntests=countTestOutcomes(report);
        assertEqual(ntests,numel(should_pass));

        for k=1:ntests
            outcome=getTestOutcome(report,k);
            assertEqual(isSuccess(outcome),should_pass(k));
        end
    end

function delete_files(fns)
    for k=1:numel(fns)
        fn=fns{k};
        if exist(fn,'file')
            delete(fn);
        end
    end


function fns=write_mfiles(lines_cell)
    ntests=numel(lines_cell);
    fns=cell(ntests,1);

    for k=1:ntests
        prefix=sprintf('t%03d',k);
        suffix=char(ceil(rand(1,10)*26+64));
        [pth,nm]=fileparts(tempname());
        fn=fullfile(pth,sprintf('%s%s%s.m',prefix,nm,suffix));
        fns{k}=fn;
        fid=fopen(fn,'w');
        closer=onCleanup(@()fclose(fid));

        addprefix=@(xs)cellfun(@(x) ['%   ' x],xs,'UniformOutput',false);
        [unused,nm]=fileparts(fn);
        prefix={sprintf('function %s',nm), '% comment', '% Examples:'};
        lines_with_prefix=addprefix(lines_cell{k});
        suffix={'%','% end of examples','function_body'};

        all_lines=[prefix,lines_with_prefix,suffix];

        fprintf(fid,'%s\n',all_lines{:});
        clear closer;
    end
