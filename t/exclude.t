#!perl

use Test2::V0;

use Shell::GetEnv;

use Env::Path;
use File::Spec::Functions qw[ catfile ];
use Test::TempDir::Tiny;

use Time::Out qw( timeout );
my $timeout_time = $ENV{TIMEOUT_TIME} || 10;

my ( $env, $envs, %env0, $env1 );

$ENV{SHELL_GETENV_TEST} = 1;

my $dir = tempdir();

my %opt = (
    Startup => 0,
    Verbose => 1,
    STDERR  => catfile( $dir, 'stderr' ),
    STDOUT  => catfile( $dir, 'stdout' ),
);

$ENV{SHELL_GETENV_TEST} = 1;
$env = timeout $timeout_time =>
  sub { Shell::GetEnv->new( 'sh', ". t/env/sh", \%opt ) };

my $err = $@;
ok( !$err, "run subshell" )
  or diag( "unexpected time out: $err\n",
    "please check $opt{STDOUT} and $opt{STDERR} for possible clues\n" );

SKIP: {
    skip "failed subprocess run", 2 if $err;

    $envs = $env->envs();

    subtest 'exclude regexp' => sub {

        my %env0 = %$envs;
        $env1 = $env->envs( Exclude => qr/^SHELL_GETENV/ );

        is( delete( $env0{SHELL_GETENV} ), 'sh' );
        is( $env1,                         \%env0 ),;
    };

    subtest 'exclude scalar' => sub {

        my %env0 = %$envs;
        $env1 = $env->envs( Exclude => 'SHELL_GETENV' );

        is( delete( $env0{SHELL_GETENV} ), 'sh' );
        is( $env1,                         \%env0 );
    };

    subtest 'exclude code' => sub {

        my %env0 = %$envs;
        $env1 = $env->envs(
            Exclude => sub {
                my ( $var, $val ) = @_;
                return $var eq 'SHELL_GETENV' ? 1 : 0;
            } );

        is( delete( $env0{SHELL_GETENV} ), 'sh' );
        is( $env1,                         \%env0 );
    };

}

done_testing;

