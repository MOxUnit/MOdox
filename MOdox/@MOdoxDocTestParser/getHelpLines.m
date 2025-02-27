function help_lines = getHelpLines(obj, content)
    % Return doc test lines
    %
    % help_lines=getHelpLines(obj,content)
    %
    % Inputs:
    %   obj                     MOdoxDocTestParser object
    %   lines                   cellstring with matlab code as found in
    %                           .m file, or filename of an .m file.
    % Output:
    %   help_lines              Cell string with lines containing help.
    %                           If the m-file starts with one or more lines
    %                           that do not start with '%' (modulo whitespace),
    %                           then the output has the empty string for those
    %                           lines. Any lines after that are returned in the
    %                           output, until a line does not start with '%'

    lines = get_lines(content);

    n_lines = numel(lines);
    row = 0;

    help_section_has_started = false;
    help_end = n_lines;

    clean_lines = cell(n_lines, 1);

    while row < n_lines
        row = row + 1;
        line = lines{row};

        [code, comment] = modox_split_code_and_comment(line);
        has_comment = ~isempty(comment);
        has_code = ~isempty(regexp(code, '\S', 'once'));

        if has_comment && ~has_code
            if ~help_section_has_started
                % first line with comment, start of help section
                help_section_has_started = true;
            end

            clean_lines{row} = [' ' comment(2:end)];

        elseif ~help_section_has_started
            % before the start of the help, replace content by empty string
            clean_lines{row} = '';

        else
            assert(help_section_has_started);

            % first line without comment after header, end of help section
            help_end = row - 1;
            break
        end
    end

    if help_section_has_started
        help_lines = clean_lines(1:help_end);
    else
        help_lines = {};
    end

function lines = get_lines(content)
    if iscellstr(content)
        lines = content;
    elseif ischar(content)
        lines = read_lines_from_file(content);
    else
        error('illegal input of type %s', class(content));
    end

function lines = read_lines_from_file(content)
    if isempty(dir(content))
        error('file %s does not exist', content);
    end
    fid = fopen(content);
    cleaner = onCleanup(@()fclose(fid));
    lines_vec = fread(fid, 'char=>char')';
    lines = regexp(lines_vec, sprintf('\n'), 'split');
