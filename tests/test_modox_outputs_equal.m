function test_suite = test_modox_outputs_equal
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;

function test_outputs_equal_basics
    % two elements in each row are equal expressions
    % but elemens in different rows are not equal to each other
    equals={{'1'},{'1'};...
            {'1','  2'},{' 1        2'};...
            {'2 1'},{'2 3 1'};...
            {'foo'},{'  foo'};...
            };

    n=size(equals,1);
    for k=1:n
        for j=(k+1):n
            p=equals{k,1};
            q=equals{j,2};



            assertEqual(k==j,modox_outputs_equal(joined(p),joined(q)));
        end
    end

function s=joined(p)
    s=sprintf('%s\n',p{:});


function test_outputs_equal_exceptions
    aet=@(varargin)assertExceptionThrown(@()...
                            modox_outputs_equal(varargin{:}),'');
    aet(struct,struct);
    aet({'foo'},{'bar'});
    aet({1},{'bar'})
    aet({'bar'},{1})