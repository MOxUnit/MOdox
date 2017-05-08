# MOdox [![Build Status](https://travis-ci.org/MOdox/MOdox.svg?branch=master)](https://travis-ci.org/MOdox/MOdox) [![Coverage Status](https://coveralls.io/repos/github/MOdox/MOdox/badge.svg?branch=master)](https://coveralls.io/github/MOdox/MOdox?branch=master)

MOdox is documentation test ("doctest") framework for Matlab and GNU Octave.


### Features

- Runs on both the [Matlab] and [GNU Octave] platforms.
- Can be used directly with continuous integration services, such as [coveralls.io] and [Shippable].
- Extends [MOxUnit], a unit test framework for Matlab and GNU Octave.
- Is distributed under the MIT license, a permissive free software license.


### Dependencies
- Working installation of [MOxUnit]. 
- The ``evalc`` function. This functon is generally available in Matlab. Older versions of Octave without ``evalc`` can compile the ``evalc.cc`` file from in the "externals" directory. This can be done by running ``make build-octave`` from the shell, or in Octave by running ``mkoctfile('evalc.cc')`` in the ``externals`` directory and then adding that directory to the search path. The ``evalc.cc`` implementation is Copyright 2015 Oliver Heimlich, distributed under the GPL v3+ license.


### Installation

- Using the shell (requires a Unix-like operating system such as GNU/Linux or Apple OSX):

    ```bash
    git clone https://github.com/MOdox/MOdox.git
    cd MOdox
    make install
    ```
    This will add the MOdox directory to the Matlab and/or GNU Octave search path. If both Matlab and GNU Octave are available on your machine, it will install MOdox for both.

- Manual installation:

    + Download the zip archive from the [MOdox] website.
    + Start Matlab or GNU Octave.
    + On the Matlab or GNU Octave prompt, `cd` to the `MOdox` root directory, then run:

        ```matlab
        cd MOdox            % cd to MOdox subdirectory
        addpath(pwd)        % add the current directory to the Matlab/GNU Octave path
        savepath            % save the path
        ```


### Writing documentation tests
Documentation tests can be defined in the help section of a Matlab / Octave .m file. The help section of a function "foo" is the text shown when running "help foo".

Documentation tests must be placed in an example section starting with a header that consists of exactly one of the strings "Example", "Examples", "Example:" or "Examples:" (optionally surrounded by whitespace). Subsequent lines, if indented (by being prefixed by more whitespace than the example header), are used to construct documentation tests. The examples section ends when the indentation is back to the original level.
Multiple test sections can be defined by separating them by whitespace. Each tests contains one or more Matlab epxressions, and one or more lines containing expected output. Expected output is prefixed by "%||"; this ensures that documentation tests can be run by using copy-pasting code fragments. If a potential test section does not have expected output, then it is ignored (and not used to construct a test).

In the following example, a file "foo.m" defines two documentation tests:

```matlab
        function foo()
        % This function illustrates a documentation test defined for MOdox.
        % Other than that it does absolutely nothing
        %
        % Examples:
        %   a=2;
        %   disp(a)
        %   % Expected output is prefixed by '%||' as in the following line:
        %   %|| 2
        %   %
        %   % The test continues because no interruption through whitespace,
        %   % as the previous line used a '%' comment character;
        %   % thus the 'a' variable is still in the namespace and can be 
        %   % accessed.
        %   b=3+a;
        %   disp(a+[3 4])
        %   %|| [5 6]
        %
        %   % A new test starts here because the previous line was white-space
        %   % only. Thus the 'a' and 'b' variables are not present here anymore.
        %   % The following expression raises an error because the 'b' variable
        %   % is not defined (and does not carry over from the previous test).
        %   % Because the expected output indicates an error as well, 
        %   % the test passes
        %   disp(b)
        %   %|| error('Some error')
        %
        %   % A set of expressions is ignored if there is no expected output 
        %   % (that is, no lines starting with '%||').
        %   % Thus, the following expression is not part of any test,
        %   % and therefore does not raise an error.
        %   error('this is never executed)
        %
        %
        % % tests end here because test indentation has ended
```

### Running documentation tests
Tests can be run using the ``modox`` function. For example, to run the documentation test defined above (in file foo.m):

```matlab

    modox foo.m

```

The ``modox`` accepts as input arguments both single .m files and directories with m files. If no .m files or directories are given, it runs tests on all .m files in the current directory.



### Use with travis-ci and Shippable
MOdox can be used with the [Travis-ci] and [Shippable] services for continuous integration testing. This is achieved by setting up a `travis.yml` file. For an example in the related [MOxUnit] project, see the [MOxUnit travis.yml] file.


### Compatibility notes
- Because GNU Octave 3.8 and 4.0 do not support `classdef` syntax, 'old-style' object-oriented syntax is used for the class definitions.

### Limitations
- Expressions with the "for" keyword are not supported in Octave because ``evalc`` does not seem to support it
- It is possible to indicate that an expression throws an exception, but not *which* exception.

### Acknowledgements
- Thanks to Oliver Heimlich for the evalc implementation for GNU Octave.

### Contact
Nikolaas N. Oosterhof, n.n.oosterhof <at> gmail <dot> com.

### License

(The MIT License)

Copyright (c) 2017 Nikolaas N. Oosterhof

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge,
publish, distribute, sublicense, and/or sell copies of the Software,
and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


[GNU Octave]: http://www.gnu.org/software/octave/
[Matlab]: http://www.mathworks.com/products/matlab/
[MOxUnit]: https://github.com/MOxUnit/MOxUnit
[MOdox]: https://github.com/MOdox/MOdox
[MOxUnit .travis.yml]: https://github.com/MOxUnit/MOxUnit/blob/master/.travis.yml
[Travis-ci]: https://travis-ci.org
[coveralls.io]: https://coveralls.io/
[Shippable]: https://shippable.com


