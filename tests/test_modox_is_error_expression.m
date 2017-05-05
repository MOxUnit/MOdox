function test_suite = test_modox_is_error_expression
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;


function test_modox_is_error_expression_basics()
    aeq=@(value,varargin)assertEqual(value,...
                    modox_is_error_expression(varargin{:}));
    aeq(true,'error(''foo'')');
    aeq(true,'    error     (    ''foo'')');
    aeq(true,sprintf('  \t  error \t    (    3   )\n'));
    
    aeq(false,'    abs(2)');
    aeq(false,'    fprintf(2,''error'')');
    aeq(false,'    % error(''foo'')');
    
function test_modox_is_error_expression_exceptions()    
    aet=@(varargin)assertExceptionThrown(@()...
                    modox_is_error_expression(varargin{:}),'');
    aet(struct)
    aet(2)