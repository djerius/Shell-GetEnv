use Test::More tests => 4;
BEGIN { use_ok('Shell::GetEnv') };

use strict;
use warnings;

use Env::Path;

my ( $env, $envs, %env0, $env1 );

$ENV{SHELL_GETENV_TEST} = 1;
$env = Shell::GetEnv->new( 'sh',  ". t/testenv.sh", { Startup => 0 } );
$envs = $env->envs( );

    
%env0 = %$envs;
$env1 = $env->envs( Exclude => qr/^SHELL_GETENV/ );

ok( 'sh' eq delete( $env0{SHELL_GETENV} )
    && eq_hash( $env1, \%env0 ),
    'exclude regexp' );


%env0 = %$envs;
$env1 = $env->envs( Exclude => 'SHELL_GETENV' );

ok( 'sh' eq delete( $env0{SHELL_GETENV} )
    && eq_hash( $env1, \%env0 ),
    'exclude scalar' );

%env0 = %$envs;
$env1 = $env->envs( Exclude => 
		    sub { my( $var, $val ) = @_;
			  return $var eq 'SHELL_GETENV' ? 1 : 0 } );

ok( 'sh' eq delete( $env0{SHELL_GETENV} )
    && eq_hash( $env1, \%env0 ),
    'exclude code' );


