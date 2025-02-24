function flag = modox_skip_test_if(flag, varargin)
    % Skip test if particular condition is fulfilled
    %
    % flag=modox_skip_test_if(flag, reason)
    %
    % Inputs:
    %   flag                    Condition that has to be true in order to skip
    %                           a test.
    %                           - When using MOxUnit, this means that a
    %                             'moxunit:testSkipped' exception is raised.
    %                           - When using xUnit, this means a
    %                             'xunit:testSkipped' warning is shown
    %   msg                     Warning error or message to be shown, if a test
    %                           is to be skipped.
    %
    % Output:
    %   flag                    The same as the input flag.
    %
    if ~islogical(flag) || numel(flag) ~= 1
        error('First input must be logical scalar');
    end

    if ~flag
        return
    end

    if test_platform_is_moxunit()
        error('moxunit:testSkipped', varargin{:});
    elseif test_platform_is_xunit()
        warning('xunit:testSkipped', varargin{:});
    else
        warning('Test skipped (on unknown platform): %s', varargin{:});
    end

function tf = test_platform_is_moxunit()
    tf = ~isempty(which('moxunit_runtests'));

function tf = test_platform_is_xunit()
    tf = ~isempty(which('runtests')) && ~isempty(which('TestCase'));
