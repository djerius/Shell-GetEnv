#!perl

use Test2::V0;
use Test::TempDir::Tiny;

use IO::File;
use File::Spec::Functions qw[ catfile ];

use Time::Out qw( timeout );
my $timeout_time = $ENV{TIMEOUT_TIME} || 10;

use Shell::GetEnv;

my $dir = tempdir();

subtest 'redirect to filenames' => sub {

    my %opt = (
        startup => 0,
        verbose => 0,
        stderr  => catfile( $dir, 'stderr' ),
        stdout  => catfile( $dir, 'stdout' ),
    );

    my $env = timeout $timeout_time => sub {
        Shell::GetEnv->new( 'sh', "echo >&2 stderr", "echo stdout", \%opt, );
    };

    my $err = $@;
    ok( !$err, "run subshell" )
      or diag( "unexpected time out: $err\n",
        "please check $opt{stdout} and $opt{stderr} for possible clues\n" );

    for my $stream ( qw[ stdout stderr ] ) {

        subtest $stream => sub {

            my $file = $opt{$stream};

            ok( -f $file && -s _, "output file exists and is not empty" );

            my $content
              = do { local $/; my $fh = IO::File->new( $file ); <$fh> };

            is( $content, "$stream\n", "output file has correct content" );
          }
    }
};

subtest 'redirect to scalar' => sub {

    my %output = (
        stdout => undef,
        stderr => undef
    );

    my %opt = (
        startup => 0,
        verbose => 0,
        stdout  => \$output{stdout},
        stderr  => \$output{stderr},
    );

    my $env =    #timeout $timeout_time => sub {
      Shell::GetEnv->new( 'sh', "echo >&2 stderr",
        "echo stdout", ". t/testenv.sh", \%opt, );
    # };

    my $err = $@;
    ok( !$err, "run subshell" )
      or diag( "unexpected time out: $err\n",
        "please check $opt{STDOUT} and $opt{STDERR} for possible clues\n" );

    for my $stream ( qw[ stdout stderr ] ) {

        subtest $stream => sub {
            is( $output{$stream}, "$stream\n",
                "output variable has correct content" );
        };
    }
};


done_testing;
