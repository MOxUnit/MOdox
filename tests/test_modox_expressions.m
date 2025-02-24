function test_suite = test_modox_expressions
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions = localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;

function s = randstr()
    s = char(ceil(rand(1, 10) * 24 + 64));

function test_modox_expressions_basics()
    class_ = @MOdoxTestCaseExpression;

    % test without line prefix
    [instance, location, lines, output] = instantiate_class(class_, '');
    assertEqual(getCode(instance), lines);
    assertEqual(getOutputPrefix(instance), '');
    assertEqual(getLocation(instance), location);
    assertEqual(getOutput(instance), output);
    str(instance);

    % test instance with line prefix
    prefix = randstr();
    [instance_pf, location, lines, output] = instantiate_class(class_, ...
                                                               prefix);
    assertEqual(getCode(instance_pf), lines);
    assertEqual(getOutputPrefix(instance_pf), prefix);
    assertEqual(getLocation(instance_pf), location);
    assertEqual(getOutput(instance_pf), output);

    assertTrue(isEvaluable(instance));
    assertTrue(isValid(instance));

function test_separator_expression_basics()
    class_ = @MOdoxSeparatorExpression;
    instance = class_();

    assert(ischar(str(instance)));
    assertFalse(isEvaluable(instance));
    assertTrue(isValid(instance));

function test_unparseble_expresion_basics()
    class_ = @MOdoxUnparseableExpression;

    reason = randstr();
    filename = randstr();
    linenumber = ceil(rand() * 100);
    location = MOdoxMFileLocation(filename, linenumber);

    instance = class_(location, reason);

    assertEqual(getLocation(instance), location);
    assertEqual(getReason(instance), reason);

    assert(ischar(str(instance)));
    assertTrue(isEvaluable(instance));
    assertFalse(isValid(instance));

    aet = @(varargin)assertExceptionThrown(@()class_(varargin{:}), '');
    aet(reason, location);
    aet(struct, reason);
    aet(location, 3);

function [instance, location, lines, output] = instantiate_class(constructor, ...
                                                                 prefix)
    filename = randstr();
    linenumber = ceil(rand() * 100);

    location = MOdoxMFileLocation(filename, linenumber);
    lines = random_cellstr();
    output = random_cellstr();

    instance = constructor(location, lines, prefix, output);

function lines = random_cellstr()
    line_count = ceil(rand() * 10);
    lines = arrayfun(@(unused)randstr(), 1:line_count, ...
                     'UniformOutput', false);

function test_modox_expressions_exceptions()
    class_ = @MOdoxTestCaseExpression;
    aet_class = @(varargin)assertExceptionThrown(@() ...
                                                 class_(varargin{:}), '');

    filename = randstr();
    linenumber = ceil(rand() * 100);

    location = MOdoxMFileLocation(filename, linenumber);
    lines = random_cellstr();
    output = random_cellstr();
    prefix = 'foo';

    % wrong order
    aet_class(lines, location, prefix, output);

    % wrong type
    aet_class(filename, lines, prefix, output);
    aet_class(location, lines{1}, prefix, output);
    aet_class(location, struct, prefix, output);
    aet_class(struct, lines, prefix, output);

    % wrong third argument
    aet_class(location, lines, struct, output);
    aet_class(location, lines, lines, output);

    % wrong fourth argument
    aet_class(location, lines, prefix, '');
    aet_class(location, lines, prefix, struct);

    % wrong lines / output argument
    aet_class(location, {['foo'; 'bar']}, prefix, output);
    aet_class(location, lines, prefix, {['foo'; 'bar']});
