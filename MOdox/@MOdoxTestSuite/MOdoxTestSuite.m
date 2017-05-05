function obj=MOdoxTestSuite(name)
% Initialize empty doc test suite
%
% Input:
%   name            Optional name of the test suite
% Output:
%   obj             MOdoxTestSuite instance with no tests.
%
% Notes:
%   MOdoxTestSuite is a subclass of MOxUnitTestSuite, which is a subclass
%   of MoxUnitTestNode.
%
% See also: MoxUnitTestNode, MoxUnitTestNode
%
% NNO 2015

    class_name='MOdoxTestSuite';
    if nargin<1
        name=class_name;
    end

    s=struct();
    obj=class(s,class_name,MOxUnitTestSuite(name));


