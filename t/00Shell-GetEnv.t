use Test::More tests => 26;
BEGIN { use_ok('Shell::GetEnv') };

use strict;
use warnings;

use Env::Path;

my %source = ( 
   tcsh => 'source',
   csh  => 'source',
   sh   => '.',
   ksh  => '.',
   bash => '.' );

my $path = Env::Path->PATH;
for my $shell ( qw( bash csh sh ksh tcsh ) )
{
  SKIP:
  {
      # make sure the shell exists
      skip "Can't find shell $shell\n", 5, unless $path->Whence( $shell );

      my %opt;#( Verbose => 0, Echo => 0, Redirect => 1, Debug => 1);

      for my $startup ( 0, 1 )
      {
	  $ENV{SHELL_GETENV_TEST} = 1;
    
	  $opt{Startup} = $startup;

	  my $env = Shell::GetEnv->new( $shell, 
					$source{$shell} . " t/testenv.$shell",
					\%opt
				      );

	  my $envs = $env->envs;
	  ok( ! exists $envs->{SHELL_GETENV_TEST},
	      "$shell: startup=$startup; unset" );
	  ok(  $envs->{SHELL_GETENV} eq $shell,
	       "$shell: startup=$startup;   set" );
      }


    SKIP:
    {
	eval 'use Expect';
	skip "Expect module not available", 1, if $@;

	local $opt{Expect} = 1;

	my $env = Shell::GetEnv->new( $shell, 
				      $source{$shell} . " t/testenv.$shell",
				      \%opt
				    );

	my $envs = $env->envs;
	ok(  $envs->{SHELL_GETENV} eq $shell,  "$shell: expect;  set" );

    }

  }

}
