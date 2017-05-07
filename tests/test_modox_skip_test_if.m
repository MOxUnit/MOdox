function test_suite = test_modox_skip_test_if
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;


function test_modoxunit_skip_test_if_basics()
    skip_test=@()modox_skip_test_if(true,'skipped');
    do_not_skip_test=@()modox_skip_test_if(false,'not skipped');

    if test_platform_is_moxunit()
        assertExceptionThrown(skip_test,...
                                'moxunit:testSkipped');

        is_ok_when_evaluated(@()do_not_skip_test);
    elseif test_platform_is_xunit
        assert_warning_shown(skip_test,'skipped');
        is_ok_when_evaluated(@()do_not_skip_test);
    else
        error('Unknown platform');
    end

function test_modoxunit_skip_test_if_illegal_inputs()
    illegal_inputs={'foo',...
                    1,...
                    [false,true],...
                    [],...
                    struct};
    aet=@(varargin)assertExceptionThrown(@()...
                            modox_skip_test_if(varargin{:}),'');
    for k=1:numel(illegal_inputs)
        illegal_input=illegal_inputs{k};
        aet(illegal_input);
    end



function is_ok_when_evaluated(f)
    f();


function assert_warning_shown(f, msg)
    warning_state=warning();
    cleaner=onCleanup(@()warning(warning_state));
    warning('off');
    f();
    w=lastwarn();
    assertEqual(msg,w);


function tf=test_platform_is_moxunit
    tf=~isempty(which('moxunit_runtests'));

function tf=test_platform_is_xunit
    tf=~isempty(which('runtests')) && ~isempty(which('TestCase'));
