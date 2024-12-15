function test_suite = test_modox_split_code_and_comment
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;


function test_modox_split_code_and_comment_basics
    cases={    '','','';...
               ' %',' ','%';...
               ' an expr % foo % a',' an expr ','% foo % a';...
               ' ''%'' ',' ''%'' ','';...
               ' {2 ''%'' 3} % com ment',' {2 ''%'' 3} ','% com ment';...
               'a=([1]'') % comment','a=([1]'') ','% comment'
               };

    n_cases=size(cases,1);
    for k=1:n_cases
        line=cases{k,1};
        [code,comment]=modox_split_code_and_comment(line);
        assertEqual(code,cases{k,2});
        assertEqual(comment,cases{k,3});
    end


function test_modox_split_code_and_comment_exceptions
    aet=@(varargin)assertExceptionThrown(@()...
                            modox_split_code_and_comment(varargin{:}),'');
    aet([]);
    aet({'2'});
