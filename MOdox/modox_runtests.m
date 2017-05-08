function all_passed=modox_runtests(varargin)
% Run documentation tests using MOdox
%
% all_passed=modox(...)
%
% Inputs:
%   mfile_name                  Matlab .m filename with  }
%                               file to be documentation } can be
%                               tested                   } supplied
%   dir_name                    Directory with .m files  } multiple
%                               to be documentation      } times
%                               tested                   }
%   '-quiet',                   Make output more quiet
%                               default: false
%   '-verbose',                 Make output more verbose
%                               default: false
%   '-recursive'                When using directories /after/ this option,
%                               add files recursively
%
% Examples:
%   % run tests from all .m files in current directory
%   modox
%
%   % run tests for file foo.m
%   modox foo.m
%
% Notes:
%   if no file name or directory is provided, then all mfiles in the
%   current directory are considered

    opt=parse_options(varargin{:});
    filenames=opt.filenames;
    verbosity=opt.verbosity;

    suite=MOdoxTestSuite();

    n_files=numel(filenames);
    for k=1:n_files
        fn=filenames{k};
        suite=addFromFile(suite,fn);
    end

    if opt.verbosity>0
        disp(suite);
    end

    report=MOxUnitTestReport(verbosity);
    report=run(suite,report);

    disp(report);

    all_passed=wasSuccessful(report);


function opt=parse_options(varargin)
    opt=struct();
    opt.verbosity=1;

    narg=numel(varargin);
    filenames_cell=cell(narg,1);

    add_recursively=false;

    k=0;
    while k<narg
        k=k+1;
        arg=varargin{k};
        if ~ischar(arg)
            error('Argument %d must be a string',k);
        end

        switch arg
            case '-quiet'
                opt.verbosity=opt.verbosity-1;

            case '-verbose'
                opt.verbosity=opt.verbosity+1;

            case '-recursive'
                add_recursively=true;

            otherwise
                if isdir(arg)
                    fns=find_files(arg,add_recursively);
                elseif exist(arg,'file')
                    fns={arg};
                else
                    error(['Illegal option, and file '...
                            'or directory not found: ''%s'''],arg);
                end

                filenames_cell{k}=fns;
        end
    end

    keep_msk=~cellfun(@isempty,filenames_cell);
    if any(keep_msk)
        filenames=cat(1,filenames_cell{keep_msk});
    else
        % all files in current directory
        cur_dir=pwd();
        filenames=find_files(cur_dir,add_recursively);
    end

    opt.filenames=filenames;
    if opt.verbosity<0
        opt.verbosity=0;
    end


function fns=find_files(dir_name,add_recursively)
    mfile_re='^.*\.m$';

    fns=moxunit_util_find_files(dir_name,'^.*\.m$',...
                                    add_recursively);


