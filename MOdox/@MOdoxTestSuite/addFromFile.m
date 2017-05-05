function suite=addFromFile(suite,fn,parser)
% Add mfile doct tests from file
%
% obj=addFromFile(obj,fn,parser)
%
% Inputs:
%   obj             MOdocTestSuite instance.
%   fn              name of mfile that contains documentation test
%   parser          MOdoxDocTestParser instance that can parse
%                   documentation tests
%
% Output:
%   obj             MOdocTestSuite instance with the MOxUnitTestNode test
%                   added, if present.
%

    if nargin<=3
        parser=MOdoxDocTestParser();
    end

    expressions=parseMFile(parser,fn);
    n_expressions=numel(expressions);
    
    current_evaluable=cellfun(@(x)isEvaluable(x),expressions);
    next_evaluable=[current_evaluable(2:end); false];
    
    test_start=[];
    for k=1:n_expressions        
        if current_evaluable(k)
            if isempty(test_start)
                test_start=k;
            end
            
            if ~next_evaluable(k)
                test_end=k;
                
                case_expressions=expressions(test_start:test_end);
                last_expression=case_expressions{end};
                
                
                location=getLocation(last_expression);
                test_case=MOdoxTestCase(fn,location,case_expressions);
                suite=addTest(suite,test_case);
                test_start=[];
            end
        end
    end
    
 