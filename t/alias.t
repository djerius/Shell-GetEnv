#!perl
use strict;
use warnings;

use Test::More;
use Env::Path;
use IO::File;

use File::Spec::Functions qw[ catfile ];
use Test::TempDir::Tiny;

use Time::Out qw( timeout );
my $timeout_time = $ENV{TIMEOUT_TIME} || 10;

use Env::Path;

plan tests => 182;


use Shell::GetEnv;

my %opt = ( Startup => 0,
            Verbose => 1,
            Alias => 1
    );

my %source = (
              bash => '.',
              csh  => 'source',
              dash => '.',
              ksh  => '.',
              sh   => '.',
              tcsh => 'source',
              zsh   => '.',
    );

my $path = Env::Path->PATH;

my %ENVc = %ENV;
%ENV = ();
@ENV{qw(HOME PATH SHELL TERM TMPDIR)} =
    @ENVc{qw(HOME PATH SHELL TERM TMPDIR)};
$ENV{ Shell::GetEnv::alias_var() } = 6;
$ENV{SHELL_GETENV_TEST} = 1;

foreach my $shell (qw(bash sh csh dash ksh tcsh zsh)) {
    my $source = $source{$shell};
    my $label = $shell;
  SKIP:
    {
        skip "Can't find shell $shell", 10  unless $path->Whence( $shell );

        # Alias => 0   ; new alias can be set and used in the shell
        # but $ENV{"Shell::GetEnv::ALIASES"} is not set

        $ENV{FOO} = 19;

        my $env = eval {
            timeout $timeout_time =>
                sub {
                    Shell::GetEnv->new( $shell, "$source t/testalias.$shell",
                                        {%opt, Alias => 0} );
                }; };
        my $err = $@;
        ok ( ! $err, "$label\[1]: ran subshell" )
            or diag( "$label\[1]: unexpected time out: $err\n",
                     "STDOUT:\n",
                     eval { IO::File->new( $opt{STDOUT}, 'r' )->getlines },
                     "STDERR:\n",
                     eval { IO::File->new( $opt{STDERR}, 'r' )->getlines },
            );

      SKIP:
        {
            skip "failed subprocess run", 4  if $err;

            my $status = $env->status;
            is( $status, 0, "$label\[1]: subshell exit code 0" );

            $env->import_envs;
            my $foo = $ENV{"FOO"};
            is( $foo, 42, "$label\[1]: alias set \$FOO env var" );

            my $alias = Shell::GetEnv::_aliases();
            is ( ref($alias), 'ARRAY', "$label\[1]: retrieved aliases")
                or $alias = [];

            ok ( @$alias == 0, "$label\[1]: no aliases found with Alias => 0" );
        }
        

        # Alias => 1 : update $ENV{"Shell::GetEnv::ALIASES"}

        $ENV{FOO} = 61;

        $env = eval {
            timeout $timeout_time =>
                sub {
                    Shell::GetEnv->new( $shell, "$source t/testalias.$shell",
                                        {%opt, Alias => 1} );
                }; };
        $err = $@;
        ok ( ! $err, "$label\[2]: ran subshell" )
            or diag( "$label\[2]: unexpected time out: $err\n",
                     "STDOUT:\n",
                     eval { IO::File->new( $opt{STDOUT}, 'r' )->getlines },
                     "STDERR:\n",
                     eval { IO::File->new( $opt{STDERR}, 'r' )->getlines },
            );

      SKIP:
        {
            skip "failed subprocess run", 4  if $err;

            my $status = $env->status;
            is( $status, 0, "$label\[2]: subshell exit code 0" );

            $env->import_envs;
            my $foo = $ENV{"FOO"};
            is( $foo, 42, "$label\[2]: alias set \$FOO env var" );

            my $alias = $env->_aliases;
            is ( ref($alias), 'ARRAY', "$label\[2]: retrieved aliases")
                or $alias = [];

            ok ( 0 != grep(/setfoo/,@$alias), 
                 "$label\[2]: setfoo alias retrieved" );
        }
    }
}

# next thing to try:
#   $opt{Alias} = 0: set alias in one script, execute alias on next script fails
#   $opt{Alias} = 1: set alias in one script, execute alias on next script ok

$opt{Alias} = 0;
foreach my $shell (qw(sh bash csh dash ksh tcsh zsh)) {
    my $source = $source{$shell};
    my $label = $shell;
    my $script1 = "t/testalias.$shell";
    my $script2 = -f "t/testalias2.$shell"
        ? "t/testalias2.$shell" : "t/testalias2.all";
  SKIP: 
    {
        skip "Can't find shell $shell", 8  unless $path->Whence( $shell );
        $ENV{BAR} = "xyz";
        delete $ENV{ Shell::GetEnv::alias_var() };
        my $env1 = eval {
            timeout $timeout_time =>
                sub {
                    Shell::GetEnv->new( $shell, "$source $script1", \%opt );
            }; };
        my $err1 = $@;
        ok ( ! $err1, "$label\[3]: ran subshell" )
            or diag( "$label\[3]: unexpected time out: $err1\n",
                     "STDOUT:\n",
                     eval { IO::File->new( $opt{STDOUT}, 'r' )->getlines },
                     "STDERR:\n",
                     eval { IO::File->new( $opt{STDERR}, 'r' )->getlines },
            );
        skip "skip remaining $shell alias test", 7  if $err1;

        $env1->import_envs;
        is ( $env1->status, 0, "$label\[3]: subshell exit code 0" )
            or diag("STDERR:\n",
                    eval { IO::File->new( $opt{STDERR}, 'r' )->getlines });
        is ( $ENV{BAR}, "abc", "$label\[3]: \$ENV{BAR} reinit in shell" );
        my $alias1 = Shell::GetEnv::_aliases();
        ok ( 0 == @$alias1, "$label\[3]: aliases not exported" );

        # without aliases, this script will not update $ENV{BAR}
        my $env2 = eval {
            timeout $timeout_time =>
                sub {
                    Shell::GetEnv->new( $shell, "$source $script2", \%opt );
            }; };
        my $err2 = $@;
        ok ( ! $err2, "$label\[4]: ran 2nd subshell" )
            or diag( "$label\[4]: unexpected time out: $err2\n",
                     "STDOUT:\n",
                     eval { IO::File->new( $opt{STDOUT}, 'r' )->getlines },
                     "STDERR:\n",
                     eval { IO::File->new( $opt{STDERR}, 'r' )->getlines },
            );
        skip "skip remaining $shell alias test", 3  if $err2;

        $env2->import_envs;
        isnt ( $env2->status, 0, "$label\[4]: subshell failed to run alias" );
        is ( $ENV{BAR}, "abc", "$label\[4]: \$ENV{BAR} not updated" );
        my $alias2 = $env2->_aliases;
        ok ( 0 == @$alias2, "$label\[4]: aliases not exported" );
    }
}


$opt{Alias} = 1;
foreach my $shell (qw(sh bash csh dash ksh tcsh zsh)) {
    my $source = $source{$shell};
    my $label = $shell;
    my $script1 = "t/testalias.$shell";
    my $script2 = "t/testalias2.all";
  SKIP: 
    {
        skip "Can't find shell $shell", 8  unless $path->Whence( $shell );
        $ENV{BAR} = "xyz";
        delete $ENV{ Shell::GetEnv::alias_var() };
        my $env1 = eval {
            timeout $timeout_time =>
                sub {
                    Shell::GetEnv->new( $shell, "$source $script1", \%opt );
            }; };
        my $err1 = $@;
        ok ( ! $err1, "$label\[5]: ran subshell" )
            or diag( "$label\[5]: unexpected time out: $err1\n",
                     "STDOUT:\n",
                     eval { IO::File->new( $opt{STDOUT}, 'r' )->getlines },
                     "STDERR:\n",
                     eval { IO::File->new( $opt{STDERR}, 'r' )->getlines },
            );
        skip "skip remaining $shell alias test", 7  if $err1;

        $env1->import_envs;
        is ( $env1->status, 0, "$label\[5]: subshell exit code 0" );
        is ( $ENV{BAR}, "abc", "$label\[5]: \$ENV{BAR} reinit in shell" );
        my $alias1 = Shell::GetEnv::_aliases();
        ok ( 0 != @$alias1, "$label\[5]: aliases are exported" );

        # with aliases, this script will not update $ENV{BAR}
        my $env2 = eval {
            timeout $timeout_time =>
                sub {
                    Shell::GetEnv->new( $shell, "$source $script2", \%opt );
            }; };
        my $err2 = $@;
        ok ( ! $err2, "$label\[6]: ran 2nd subshell" )
            or diag( "$label\[6]: unexpected time out: $err2\n",
                     "STDOUT:\n",
                     eval { IO::File->new( $opt{STDOUT}, 'r' )->getlines },
                     "STDERR:\n",
                     eval { IO::File->new( $opt{STDERR}, 'r' )->getlines },
            );
        skip "skip remaining $shell alias test", 3  if $err2;

        $env2->import_envs;
        is ( $env2->status, 0, "$label\[6]: subshell successfully ran alias" );
        is ( $ENV{BAR}, "def", "$label\[6]: \$ENV{BAR} updated with alias" );
        my $alias2 = Shell::GetEnv::_aliases();
        ok ( 0 != @$alias2, "$label\[6]: aliases exported" );
    }
}

