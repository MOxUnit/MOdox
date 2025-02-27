function test_suite = test_modox_doctest_parser
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions = localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;

function s = randstr()
    s = char(ceil(rand(1, ceil(rand() * 8 + 2)) * 24 + 64));

function i = randint()
    i = ceil(rand() * 10);

function test_read_help_from_cellstring()
    helper_test_read_help_repeatedly(false);

function test_read_help_from_file()
    helper_test_read_help_repeatedly(true);

function helper_test_read_help_repeatedly(with_file)
    n_repeats = 10;

    for repeat = 1:n_repeats
        helper_test_read_help(with_file);
    end

function test_get_output_prefix()
    parser = MOdoxDocTestParser();
    prefix = getOutputPrefix(parser);
    assert(ischar(prefix));

function test_no_help_lines()
    % lines with no help should return empty cell
    lines = {'function foo', ...
             '%% doc', ...
             'bar();'};

    parser = MOdoxDocTestParser();
    doc_lines = getDocTestLines(parser, lines);
    assert(iscellstr(doc_lines));
    assert(isempty(doc_lines));

    fn = write_lines_in_temp_file('', doc_lines);
    cleaner = onCleanup(@()delete(fn));

    expressions = parseMFile(parser, fn);
    assert(iscell(expressions));
    assert(isempty(expressions));

function test_parse_error_lines()
    lines = {' Examples:', ...
             '    disp(2)', ...
             '  indent error', ...
             '    back'};

    parser = MOdoxDocTestParser();
    doc_lines = getDocTestLines(parser, lines);
    assert(ischar(doc_lines));

function test_simple_expressions()
    parser = MOdoxDocTestParser();

    exprs = {'p''', 'p'''; ...
             'p  % foo', 'p  '; ...
             '''p''  % foo', '''p''  '};

    n_expr = size(exprs, 1);
    for k = 1:n_expr
        lines_to_parse = {'Examples:', ['    ' exprs{k, 1}]};
        doc_lines = getDocTestLines(parser, lines_to_parse);
        assertEqual(doc_lines, exprs(k, 2));
    end

function test_get_lines_exceptions()
    parser = MOdoxDocTestParser();
    assert_returns_string = @(lines) ...
                                assertEqual('char', ...
                                            class(getDocTestLines(parser, lines)));
    assert_returns_string({'Examples:', ...
                           '    four lines indent', ...
                           '  back to two', ...
                           '    %|| '});

    assert_returns_string({'    Examples:', ...
                           '  only two', ...
                           '    %|| '});

function helper_test_read_help(with_file)
    with_continuation = rand() > .5;

    if with_continuation
        header = {sprintf('function %s(...', randstr()); ...
                  sprintf('%s,%s,...', randstr(), randstr()); ...
                  sprintf('%s,%s,...', randstr(), randstr())};

        nlines_header = 3;
    else
        header = sprintf('function %s(%s,%s)', ...
                         randstr(), randstr(), randstr());
        nlines_header = 1;
    end

    nlines_empty = floor(rand() * 4);
    empty_lines_cell = arrayfun(@(unused)repmat(' ', 1, floor(rand() * 4)), ...
                                (1:nlines_empty)', ...
                                'UniformOutput', false);

    nlines_help = floor(rand() * 5);

    expected_help_cell = cell(nlines_help, 1);
    help_cell = cell(nlines_help, 1);

    % insert help lines
    for row = 1:nlines_help
        space_count = floor(rand() * 5);

        % indent
        pre = repmat(' ', 1, space_count);

        % comment characters
        comment_count = floor(rand() * 5) + 1;
        comment = repmat('%', 1, comment_count);

        % comment string
        post = randstr();

        help_cell{row} = [pre comment post];
        expected_help_cell{row} = [regexprep(comment, '%', ' ', 'once')...
                                   post];
    end

    nlines_body = ceil(rand() * 2);
    body_cell = arrayfun(@(unused)randstr(), (1:nlines_body)', ...
                         'UniformOutput', false);
    if nlines_help == 0
        % no help, make sure that the body is not interpreted as help
        post_body_cell = {};
    else
        % there is already a help section in expected_help_cell
        post_body_cell = arrayfun(@(unused)['% ' randstr()], ...
                                  (1:nlines_body)', ...
                                  'UniformOutput', false);
    end

    all_lines_cell = [header; ...
                      empty_lines_cell; ...
                      help_cell; ...
                      body_cell; ...
                      post_body_cell];

    if with_file
        temp_fn = tempname();
        cleaner = onCleanup(@()delete(temp_fn));
        fid = fopen(temp_fn, 'w');
        fprintf(fid, '%s\n', all_lines_cell{:});
        fclose(fid);

        arg = temp_fn;
    else
        arg = all_lines_cell;
    end

    expected_empty = repmat({''}, nlines_header + nlines_empty, 1);
    expected_result = [expected_empty; expected_help_cell];

    parser = MOdoxDocTestParser();
    result = getHelpLines(parser, arg);

    if isempty(result)
        assert(all(cellfun(@isempty, expected_result)));
    else
        assertEqual(result, expected_result);
    end

function test_get_help_lines_exceptions()
    parser = MOdoxDocTestParser();
    aet = @(varargin)assertExceptionThrown(@() ...
                                           getHelpLines(parser, varargin{:}), '');
    % illegal types
    aet(struct);
    aet(2);
    aet({2});

    not_existing_filename = tempname();
    aet(not_existing_filename);

function test_get_help_lines_trivial()
    parser = MOdoxDocTestParser();
    aeq = @(arg, result)assertEqual(result(:), ...
                                    getHelpLines(parser, arg), '');

    aeq({'function()', 'foo', '% ab'}, {'', '', '  ab'});
    aeq({'function()', 'foo', '% ab', 'c'}, {'', '', '  ab'});
    aeq({'function()', 'foo', '% ab', '%c', 'd'}, {'', '', '  ab', ' c'});
    aeq({'', 'foo', '% ab', '%c', 'd'}, {'', '', '  ab', ' c'});

function test_mfile_parser
    [mfile_lines, idx, expected_expressions] = generate_simulated_help('');

    parser = MOdoxDocTestParser();

    mfile_name = randstr();

    % test with parser
    expressions = parseLines(parser, mfile_name, mfile_lines);
    assertExpressionsEqual(expressions, expected_expressions);

    temp_fn = write_lines_in_temp_file('%% ', mfile_lines);
    cleaner = onCleanup(@()delete(temp_fn));

    expressions = parseMFile(parser, temp_fn);
    assertExpressionsEqual(expressions, expected_expressions);

function test_mfile_parser_not_parseable
    mfile_name = randstr();
    lines = {'Examples', ...
             '   disp(2)', ...
             ' 2'};

    for in_file = [false, true]
        parser = MOdoxDocTestParser();

        if in_file
            temp_fn = write_lines_in_temp_file('%% ', lines);
            cleaner = onCleanup(@()delete(temp_fn));

            expressions = parseMFile(parser, temp_fn);
        else
            expressions = parseLines(parser, mfile_name, lines);
        end

        assert(iscell(expressions));
        assertEqual(numel(expressions), 1);
        assertEqual(class(expressions{1}), 'MOdoxUnparseableExpression');
    end

function temp_fn = write_lines_in_temp_file(prefix_pat, lines)
    temp_fn = [tempname() '.m'];
    fid = fopen(temp_fn, 'w');
    cleaner = onCleanup(@()fclose(fid));

    fprintf(fid, [prefix_pat '%s\n'], lines{:});

function assertExpressionsEqual(expressions, expected_expressions)
    n = numel(expressions);
    assertEqual(n, numel(expected_expressions), ...
                'Expression count mismatch');
    for k = 1:n
        expected = expected_expressions{k};
        actual = expressions{k};

        assertEqual(class(expected), class(actual));

        if isa(actual, 'MOdoxSeparatorExpression')
            continue
        end

        exp_lines = getCode(expected);
        act_lines = getCode(actual);

        desc = sprintf('In expression #%d', k);

        if all(cellfun(@isempty, exp_lines))
            % all empty
            assertTrue(all(cellfun(@isempty, act_lines)), desc);
        else
            % not empty, verify that code matches
            assertEqual(exp_lines, act_lines, desc);

            % verify that output matches
            assertEqual(getOutput(expected), getOutput(actual), desc);

            % verify that line numbers match
            %             x=getLineNumber(getLocation(expected));
            %             y=getLineNumber(getLocation(actual));
            %
            %             assertEqual(x,y);
        end
    end

function test_get_test_lines_trivial_cases()
    aeq = @assert_output_equal;
    parser = MOdoxDocTestParser();
    prefix = getOutputPrefix(parser);

    % output is required - define helper functions here
    out = @(x)sprintf('%s%s', prefix, x);
    out2 = @(x)sprintf('  %s', out(x));
    outb = out('baz');
    out2b = out2('baz');

    aeq({'foo', outb}, {'Examples', '  foo', out2b});
    aeq({'foo', outb}, {'Examples', '  foo', out2b, 'dedent'});
    aeq({'foo', 'bar', outb}, {'Examples', '  foo', ...
                               '  bar', out2b});
    aeq({'foo', 'bar', outb}, {'Examples', '  foo', ...
                               '  bar', out2b, 'dedent'});

    % indent
    aeq({'foo', '   bar', out('baz')}, {'Examples', '  foo', ...
                                        '     bar', out2('baz'), 'dedent'});

    % try with comments
    aeq({'foo ', outb}, {'Examples', '  foo % comment', out2b, 'dedent'});
    aeq({'foo ', 'bar ', outb}, ...
        {'Examples', '  foo % comment', '  bar % %', ...
         out2b, 'back'});
    aeq({'f(''%s'')', 'g ', outb}, ...
        {'Examples', '  f(''%s'')', '  g % %', out2b, 'back'});

    % line continuation
    aeq({sprintf('f(''%%s''...\n   g);'), [], outb}, ...
        {'Examples', '  f(''%s''...', '     g);', out2b, 'back'});

    % comments & line continuation
    aeq({sprintf('f(''%%s''...\ng);'), [], outb}, ...
        {'Examples', '  f(''%s''...', '  g);', out2b, 'back'});

    % comments & line continuation & indent
    aeq({sprintf('f(''%%s''...\n   g);'), [], outb}, ...
        {'Examples', '  f(''%s''...', '     g);', out2b, 'back'});

    % comments & line continuation & indent & trailing whitespace
    aeq({sprintf('f(''%%s''...\n   g);  '), [], outb}, ...
        {'Examples', '  f(''%s''...', '     g);  ', ...
         out2b, 'back'});

    % comments & line continuation & indent & 'difficult' use of "%" char
    aeq({sprintf('f(''%%s''...\n,g...\n h)  '), [], [], outb}, ...
        {'Examples', '  f(''%s''...', '  ,g...', '   h)  %c', ...
         out2b});

function assert_output_equal(expected_output, varargin)
    parser = MOdoxDocTestParser();
    result = getDocTestLines(parser, varargin{:});
    assertEqual(expected_output(:), result(:));

function test_get_test_lines_exceptions()
    parser = MOdoxDocTestParser();

    bad_inputs = {struct(), ...
                  'foo' ...
                 };

    for k = 1:numel(bad_inputs)
        bad_input = bad_inputs{k};
        assertExceptionThrown(@() ...
                              getDocTestLines(parser, bad_input), '');
    end

function [mfile_lines, doctest_idx, expressions] = generate_simulated_help( ...
                                                                           wrong_line_type)
    assert(ischar(wrong_line_type));

    parser = MOdoxDocTestParser();
    output_prefix = getOutputPrefix(parser);
    start_section = {'Example', 'Examples'};
    indent_count = 1 + ceil(rand() * 5);
    indent = repmat(' ', 1, indent_count);
    assert(numel(indent) >= 2); % ensure we can do too small indents

    classes = struct();

    % expected output
    classes.out.prefix = output_prefix;
    classes.out.multiline = '';
    classes.out.end_code = true;

    % code
    classes.code.prefix = '';
    classes.code.multiline = '...';
    classes.code.add_code = true;

    % comment
    classes.comment.prefix = '%   ';

    % separator between test cases
    classes.sp.prefix = '';
    classes.sp.generator = @()repmat(' ', 1, floor(rand() * 10));
    classes.sp.end_code = true;

    keys = fieldnames(classes);
    nkeys = numel(keys);

    % define preamble
    npreamble = 1:randint();
    preamble = arrayfun(@(unused)randstr, npreamble, 'UniformOutput', false);

    header = start_section{ceil(rand() * numel(start_section))};

    pre_body = [preamble(:); ...
                {header}];

    % define body
    %%%% nlines=ceil(rand()*100+100);
    nlines = 20;
    body_parts = cell(nlines, 1);
    raw_parts = cell(nlines, 1);
    expressions = cell(nlines, 1);
    doctest_idx_cell = cell(nlines, 1);

    max_safety = 1000;

    not_allowed = {'sp', 'out'; ...
                   '^', 'out'; ...
                   'out', 'out'};
    n_not_allowed = size(not_allowed, 1);

    curline = numel(pre_body);

    prev_key = '^';
    code_start = [];
    for k = 1:nlines
        i_safety = max_safety;
        while true
            i_safety = i_safety - 1;
            if i_safety < 0
                error('max safety limit exceeded');
            end

            key = keys{ceil(rand() * nkeys)};

            is_not_allowed = false(n_not_allowed, 1);
            for j = 1:n_not_allowed
                to_avoid = not_allowed(j, :);
                is_not_allowed(j) = isequal(to_avoid, {prev_key, key});
            end

            if any(is_not_allowed)
                % try again
                continue
            end

            if isempty(code_start) && strcmp(key, 'out')
                % no current code, so force no output
                continue
            end

            break
        end

        cls = classes.(key);

        if isfield(cls, 'generator')
            generator = cls.generator;
        else
            generator = @randstr;
        end

        use_multiline = isfield(cls, 'multiline') && rand() > .5;

        if use_multiline
            multiline = cls.multiline;
            raw_lines = {[generator() multiline]; ...
                         [generator() multiline]; ...
                         [generator()]};
        else
            raw_lines = {generator()};
        end

        prefix_func = @(pf)@(line) [pf line];
        % add prefix
        lines_with_prefix = cellfun(prefix_func(cls.prefix), raw_lines, ...
                                    'UniformOutput', false);

        % add indent
        lines = cellfun(prefix_func(indent), lines_with_prefix, ...
                        'UniformOutput', false);

        switch key
            case 'out'
                location = MOdoxMFileLocation(randstr(), curline);

                code_lines = cellfun(@join_lines, ...
                                     raw_parts(code_start:(k - 1)), ...
                                     'UniformOutput', false);

                empty_code = cellfun(@isempty, code_lines);
                expr = MOdoxTestCaseExpression(location, ...
                                               code_lines(~empty_code), ...
                                               cls.prefix, raw_lines);

                expressions{k} = expr;
                code_start = [];

            case 'sp'
                expr = MOdoxSeparatorExpression();
                expressions{k} = expr;
                code_start = [];

            case 'code'
                if isempty(code_start)
                    code_start = k;
                end

        end

        body_parts{k} = lines;

        nrawlines = numel(raw_lines);
        doctest_idx_cell{k} = curline + (1:nrawlines)';
        curline = curline + nrawlines;

        % store raw lines, except when in comment
        if strcmp(key, 'comment')
            raw_lines = {};
        end
        raw_parts{k} = raw_lines;

        prev_key = key;
    end

    switch wrong_line_type
        case 'wrong_indent'
            % find nonempty line
            char_is_expr = @(x)~isempty(regexp(x, '[a-zA-Z%]', 'once'));

            offset = numel(indent) + 1;

            for i_safety = 1:max_safety
                r = ceil(rand() * nlines);

                has_line_before = false;
                for before_r = 1:(r - 1)
                    % needs at least one line before the one where the
                    % indent is going to be removed
                    if numel(body_parts{before_r}{1}) >= offset && ...
                                char_is_expr( ...
                                             body_parts{before_r}{1}(offset))
                        has_line_before = true;
                        break
                    end
                end

                if ~has_line_before
                    continue
                end

                has_cur = numel(body_parts{r}{1}) >= offset;
                if ~has_cur
                    continue
                end

                line_char = body_parts{r}{1}(offset);
                if char_is_expr(line_char)
                    % remove space
                    assertEqual(body_parts{r}{1}(1:numel(indent)), indent);
                    body_parts{r}{1} = body_parts{r}{1}(2:end);
                    break
                end
            end

            assert(i_safety < max_safety, 'Safety limit reached');

        case ''
            % no wrong type, just continue

        otherwise
            error('illegal wrong_line_type');

    end

    postamble = arrayfun(@(unused)randstr, 1:randint(), 'UniformOutput', false);
    body = cat(1, body_parts{:});

    % remove empty expressions
    keep_msk = ~cellfun(@isempty, expressions);
    expressions = expressions(keep_msk);
    doctest_idx = cat(1, doctest_idx_cell{keep_msk});

    % add some lines at the end
    post_body = postamble(:);

    % get indices for test lines in the body
    mfile_lines = [pre_body; ...
                   body; ...
                   post_body(:)];

function s = join_lines(lines)
    assert(iscellstr(lines));
    if isempty(lines)
        s = '';
        return
    end

    infix = sprintf('\n');
    pat = sprintf('%%s%s', infix);
    s = sprintf(pat, lines{:});
    s = s(1:(end - numel(infix)));
