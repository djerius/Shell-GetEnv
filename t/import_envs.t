use Test::More tests => 3;
BEGIN { use_ok('Shell::GetEnv') };

use strict;
use warnings;

use Env::Path;



{
    local %ENV = %ENV;
    $ENV{SHELL_GETENV_TEST} = 1;

    Shell::GetEnv
	->new( 'sh',  ". t/testenv.sh", { Startup => 0 } )
	->import_envs( ZapDeleted => 0 );

    ok( $ENV{SHELL_GETENV_TEST} eq 1 &&
	$ENV{SHELL_GETENV} eq 'sh',
	"import_envs: all" );
}

{
    local %ENV = %ENV;
    $ENV{SHELL_GETENV_TEST} = 1;

    Shell::GetEnv
	->new( 'sh',  ". t/testenv.sh", { Startup => 0 } )
	->import_envs( ZapDeleted => 1 );

    ok( ! exists $ENV{SHELL_GETENV_TEST} &&
	$ENV{SHELL_GETENV} eq 'sh',
	"import_envs: ZapDeleted" );
}

