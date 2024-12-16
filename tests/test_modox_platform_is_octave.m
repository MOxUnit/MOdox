function test_suite = test_modox_platform_is_octave
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;

function test_modox_platform_is_octave_basic
    is_octave=exist('OCTAVE_VERSION', 'builtin')~=0;

    % first call
    assertEqual(is_octave,modox_platform_is_octave());

    % try cached version
    assertEqual(is_octave,modox_platform_is_octave());
