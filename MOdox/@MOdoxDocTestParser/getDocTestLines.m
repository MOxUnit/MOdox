function [doctest_lines,doctest_idxs]=getDocTestLines(obj,doctest_lines)
% Return doc test lines
%
% doc_lines=getDocTestLines(obj,lines)
%
% Inputs:
%   obj                     MOdoxDocTestParser object
%   lines                   cellstring with documentation. Documentation
%                           starts with a line 'Examples:',
%                           followed by one or more lines with increased
%                           indentation (white space).
%                           Expected output from expression starts with
%                           the string '%>'
%
% Output:
%   doctest_lines           cellstring with documentation test lines,
%                           with indentation removed. If no documentation
%                           is found, then the output is an empty cell
%                           array.
%   doctest_idxs            the indices of the lines with doctests, i.e.
%                           lines{doctest_idxs}==doctest_lines.
%
% Example:
%     parser=MOdoxDocTestParser();
%     lines={'These lines come',...
%           'before the documentation test lines.',...
%             '  Example:',...
%             '    % these lines are in the doc test lines',...
%             '    disp(''expected output''); % ignored',...
%             '    %|| expected output',...
%             'These lines come after the '...
%             'documentation test lines'};
%     doctest_lines=getDocTestLines(parser,lines);
%     doctest_lines
%     %>{'% these lines are in the doc test lines',...
%     %> 'disp('expected output'); ',...
%     %> '%> expected output'}
%

    check_inputs(obj,doctest_lines)
    doctest_lines=set_empty_lines(doctest_lines);

    % see where the 'Examples' section starts
    header_idx=find_header(doctest_lines);

    % no Examples section
    if isempty(header_idx)
        doctest_idxs=[];
        doctest_lines=cell(0);
        return;
    end

    header_indent=get_indent(doctest_lines,header_idx);
    start_body_idx=header_idx+1;

    body_indent=get_indent(doctest_lines,start_body_idx);

    if header_indent>=body_indent
        error(['Doctest body starting at line %d does not seem to '...
                    'be properly indented'],start_body_idx);
    end

    post_body_idx=get_body_end(doctest_lines,start_body_idx,body_indent);
    post_body_indent=get_indent(doctest_lines,post_body_idx);

    if ~isempty(post_body_indent) && post_body_indent>header_indent
        error(['Indent after doctest body at line %d is greater than '...
                'the indent of the header (''%s'') at line %d'],...
                post_body_indent,doctest_lines{header_idx},header_idx);
    end

    % remove indent from each line
    raw_idxs=start_body_idx:(post_body_idx-1);
    raw_lines=arrayfun(@(i)get_doctest_single_line(...
                                            doctest_lines,i,body_indent),...
                                raw_idxs,'UniformOutput',false);


    [doctest_lines,doctest_idxs]=move_line_continuation(raw_lines,raw_idxs);


function doctest_lines=set_empty_lines(doctest_lines)
    match=cellfun(@isempty,doctest_lines);
    n=sum(match);
    doctest_lines(match)=repmat({''},n,1);

function [clean_lines,clean_idxs]=move_line_continuation(lines,idxs)
% Each line with a line continuation is merged with the line following it.
% An error is thrown if a line continuation is followed by a comment on the
% next non-white line
    n_lines=numel(lines);

    clean_idxs=zeros(n_lines,1);
    clean_lines=repmat({''},n_lines,1);

    row=1;
    while row<=n_lines
        start_row=row;

        while true
            line=lines{row};

            [code,comment]=modox_split_code_and_comment(line);

            whitespace_only_code=isempty(regexp(code,'\S','once'));

            if isempty(code)
                break;
            end

            if whitespace_only_code
                % if no code, keep the comment
                lines{row}=['%' comment];
                break;
            end

            % update lines by removing the comment
            lines{row}=code;

            cont_match=regexp(code,'\.\.\.\s*$','once');
            if isempty(cont_match)
                % no line continuation
                break;
            end

            if row>=n_lines
                break;
            end

            row=row+1;
        end

        clean_idxs(start_row)=idxs(start_row);
        clean_lines{start_row}=join_lines(lines(start_row:row));

        row=row+1;
    end



function joined=join_lines(lines)
    prefix=lines{1};

    if numel(lines)<=1
        suffix='';
    else
        remainder_lines=lines(2:end);
        suffix=sprintf('\n%s',remainder_lines{:});
    end

    joined=sprintf('%s%s',prefix,suffix);

function line=get_doctest_single_line(lines,idx,indent)
% remove indentation from each line
    full_line=lines{idx};
    last_space=regexp(full_line,'[^ ]','once')-1;

    if isempty(last_space)
        % line with only spaces, return empty line
        line='';
    else
        assert(numel(full_line)>=indent);
        line=full_line((indent+1):end);
        assert(all(full_line(1:indent)==' '));
    end


function header_idx=find_header(lines)
    % Return first line contaiing 'Examples' section
    pattern='^\s*Example[s]?[:]?\s*$';
    matches=~cellfun(@isempty,regexp(lines,pattern,'once'));
    header_idx=find(matches,1,'first');


function indent=get_indent(lines,start_idx)
    % Return number of space characters before non-white space;
    % empty if no such lines are found
    n_lines=numel(lines);

    for idx=start_idx:n_lines
        line=lines{idx};

        % find position of last space character
        indent=regexp(line,'[^ ]','once')-1;

        if ~isempty(indent)
            % found line with non-whitespace, we are done
            return;
        end
    end

    % indent is not found
    indent=[];


function idx=get_body_end(lines,start_body_idx,body_indent)
    n_lines=numel(lines);

    for idx=start_body_idx:n_lines
        line=lines{idx};

        indent=regexp(line,'[^ ]','once')-1;

        if ~isempty(indent) && indent<body_indent
            return;
        end
    end

    % when coming here, body end is last line
    idx=idx+1;



function check_inputs(obj,lines)
    empty_or_string=@(x) isempty(x) || ischar(x);
    if ~(iscell(lines) && all(cellfun(empty_or_string,lines)))
        error('Second input must be cell string');
    end

