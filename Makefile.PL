use ExtUtils::MakeMaker;
my $EUMM_VERSION = eval $ExtUtils::MakeMaker::VERSION;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Shell::GetEnv',
    VERSION_FROM      => 'lib/Shell/GetEnv.pm', # finds $VERSION
    PREREQ_PM         => {
			  File::Temp => 0,
			  File::Spec => 0,
			  Env::Path  => 0,
			  Test::More => 0,
			  Expect     => 0,
			  IO::File   => 0,
			  YAML::Tiny => 0,
			  Data::Dumper => 0,
			 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Shell/GetEnv.pm', # retrieve abstract from module
       AUTHOR         => 'Diab Jerius <dj@>') : ()),
    ( $EUMM_VERSION >= 6.31 ? (
        LICENSE         => 'gpl',
    ) : ()),
);
