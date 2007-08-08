use Test::More;
BEGIN { use_ok('Shell::GetEnv') };

use strict;
use warnings;

use Env::Path;



if ( Env::Path->PATH->Whence( 'env' ) )
{
    plan tests => 2;
}
else
{
    plan skip_all => "'env' command not in path";
}


$ENV{SHELL_GETENV_TEST} = 1;
my $env = Shell::GetEnv->new( 'sh',  ". t/testenv.sh", { Startup => 0 } );

# test DiffsOnly, but only if env accepts -u
SKIP:
{
    # cheat and redirect stream i/o using the object. depends upon
    # Redirect => 1, which is the default.
    # THIS IS NOT APPROVED CODE.
    $env->_stream_redir();
    my $env_bad = system( 'env', '-u SHELL_GETENV_TEST' );
    $env->_stream_reset();

    skip "env doesn't support -u flag", 1 if $env_bad;
      

    my $envstr = $env->envs( EnvStr => 1, DiffsOnly => 1 );
    chomp( my $res = `env $envstr $^X -e 'print \$ENV{SHELL_GETENV}'` );
    is( $res ,'sh', "envstr: DiffsOnly " );
}

{
    my $envstr = $env->envs( EnvStr => 1);
    chomp( my $res = `env -i $envstr $^X -e 'print ! exists \$ENV{SHELL_GETENV_TEST}'` );
    is( $res ,'1', "envstr: unset" );
}

