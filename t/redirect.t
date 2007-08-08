use Test::More tests => 2;
BEGIN { use_ok('Shell::GetEnv') };

use strict;
use warnings;

use File::Temp;

my $env;

my $stdout = File::Temp->new or die;
my $stderr = File::Temp->new or die;

$env = Shell::GetEnv->new( 'sh', 
			   "echo 1>&2 foo",
			   "echo foo",
			   ". t/testenv.sh", 
			   { Startup => 0,
			     STDERR => $stderr->filename,
			     STDOUT => $stdout->filename,
			   }
			 );

ok(    -f $stdout->filename && -s _
    && -f $stderr->filename && -s _,
       "redirect to filenames" );



