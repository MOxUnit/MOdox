function [code,comment]=modox_split_code_and_comment(line)
% splits a line in a code part and a comment part
%
% [code,comment]=modox_split_code_and_comment(line)
%
% Inputs:
%   line                string with single line of matlab code
%   
% Outputs:
%   code                first part of line, containing part of matlab code 
%                       before the start of a comment (indicated by '%')
%   comment             second part of line, 
%
% Notes:
%   - it holds that line==[code comment], and that code does not contain 
%     any '%' characters except within strings

    if ~ischar(line)
        error('Input must be a string');
    end

    in_string=false;
    
    nline=numel(line);
    for k=1:nline
        c=line(k);
        if c=='%' && ~in_string
            % found the start of comment
            code=line(1:(k-1));
            comment=line(k:end);
            
            return;
            
        elseif c==''''
            swap=false;
            if in_string
                swap=true;
            elseif k==1
                swap=true;
            else
                prev_c=line(k-1);
                    
                if any(prev_c==' ([{+_-')
                    swap=true;
                end
            end
            if swap
                in_string=~in_string;
            end
        end
    end
    
    % no comment found
    code=line;
    comment='';
    