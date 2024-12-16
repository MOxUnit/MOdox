function test_suite = test_modox_mfile_location
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;

function test_modoxunit_mfile_location_basics
    randstr=@()char(ceil(rand(1,10)*24+64));
    randint=ceil(rand()*1000);

    filename=randstr();
    line_number=randint();
    loc=MOdoxMFileLocation(filename,line_number);

    assertEqual(getFilename(loc),filename);
    assertEqual(getLineNumber(loc),line_number);

    s=str(loc);
    assertEqual(s,sprintf('%s: %d',filename,line_number));



function test_modoxunit_mfile_location_exceptions
    aet=@(varargin)assertExceptionThrown(@()...
                        MOdoxMFileLocation(varargin{:}),'');
    % bad datatype
    aet(struct,2);
    aet('foo',struct);
    aet(2,'foo');

    % non-scalar line number
    aet('foo',[]);
    aet('foo',[2 3]);
