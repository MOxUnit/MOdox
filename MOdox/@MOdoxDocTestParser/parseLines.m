function expressions=parseLines(obj,mfile_name,all_lines)
% return MOdox Expressions in documentation test section
%
% expressions=getExpressions(obj,lines)
%
% Inputs:
%   obj                     MOdoxDocTestParser object
%   mfile_name              String with name of file
%   all_lines               cellstring with documentation. Documentation
%                           starts with a line 'Examples:',
%                           followed by one or more lines with increased
%                           indentation (white space).
%                           Expected output from expression starts with
%                           the string '%||'
%
% Output:
%   doctest_lines           cellstring with MOdoxExpression subclasses,
%                           i.e. each element is one of
%                           - MOdoxNoOutputExpression
%                           - MOdoxOutputExpression
%                           - MOdoxExpectedStringExpression

    output_prefix=getOutputPrefix(obj);
    output_pat=translate_prefix2pat(output_prefix);

    comment_prefix='%';
    comment_pat=translate_prefix2pat(comment_prefix);

    [doc_lines,doc_idxs]=getDocTestLines(obj,all_lines);

    if ischar(doc_lines)
        % unparsable expression
        reason=doc_lines;
        line_number=max([1,doc_idxs(find(doc_idxs,1))]);
        location=MOdoxMFileLocation(mfile_name,line_number);
        expressions={MOdoxUnparseableExpression(location,reason)};
        return;
    end

    % see which lines have output
    expected_output_match=regexp(doc_lines,output_pat,'tokens','once');
    has_expected_output=~cellfun(@isempty,expected_output_match);

    % see which lines have a comment
    comment_match=regexp(doc_lines,comment_pat,'tokens','once');
    has_comment=~cellfun(@isempty,comment_match) & ~has_expected_output;

    % ignored lines are the result of moving line continuations
    has_to_be_ignored=doc_idxs==0;

    % find separating lines
    has_separator=cellfun(@isempty,doc_lines) & ~has_to_be_ignored & ~has_comment;

    % find code lines
    has_code=~cellfun(@isempty,doc_lines) ...
                & ~has_to_be_ignored ...
                & ~has_expected_output ...
                & ~has_comment;


    n_lines=numel(doc_lines);
    expressions=cell(n_lines,1);

    code_start=[];
    output_start=[];

    for k=1:n_lines
        if has_to_be_ignored(k)
            continue;
        end

        if has_code(k) && isempty(code_start)
            code_start=k;
            continue;
        end

        if has_expected_output(k) ...
                && isempty(output_start) ...
                && ~isempty(code_start)

            output_start=k;
        end

        is_last_line=k==n_lines;
        is_end_of_output=~has_expected_output(k);

        if has_separator(k)
            expressions{k}=MOdoxSeparatorExpression();

            if isempty(output_start)
                code_start=[];
            end
        end

        if ~isempty(output_start) && ...
                    (is_last_line || is_end_of_output)

            if is_end_of_output
                output_end=k-1;
            else
                output_end=n_lines;
            end

            code_msk=~(has_to_be_ignored | has_comment);
            code_msk(1:(code_start-1))=false;
            code_msk(output_start:end)=false;

            output_msk=~(has_to_be_ignored | has_comment);
            output_msk(1:(output_start-1))=false;
            output_msk((output_end+1):end)=false;

            code_lines=doc_lines(code_msk);
            output_lines=cat(1,expected_output_match{output_msk});

            location=MOdoxMFileLocation(mfile_name,doc_idxs(k));

            expressions{k-1}=MOdoxTestCaseExpression(location,...
                                                code_lines,...
                                                output_prefix,...
                                                output_lines);

            if has_code(k)
                code_start=k;
            else
                code_start=[];
            end

            output_start=[];
        end
    end

    keep_msk=~cellfun(@isempty,expressions);
    expressions=expressions(keep_msk);




function pat=translate_prefix2pat(prefix)
    % escape special characters
    escaped_prefix=regexptranslate('escape',prefix);

    pat=['^\s*' escaped_prefix '(.*)$'];
