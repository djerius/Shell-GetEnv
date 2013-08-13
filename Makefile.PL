

use strict;
use warnings;
use inc::Module::Install;

name 'Shell-GetEnv';

perl_version '5.008000';
license 'gpl3';
all_from 'lib/Shell/GetEnv.pm';

author_tests( 'xt' );
author_requires 'Test::CPAN::Changes';

requires 'File::Temp';
requires 'File::Spec';
requires 'Expect';
requires 'IO::File';
requires 'Storable';

build_requires 'Test::More';
build_requires 'Env::Path';
build_requires 'Time::Out';

auto_install;

WriteAll;
