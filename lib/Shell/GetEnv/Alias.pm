package Shell::GetEnv::Alias;

use strict;
use warnings;

our $VERSION = '0.11_01';

sub read_alias {
    # most generic function: file contents can be evaluated 
    # in shell directly to create aliases
    my ( $file ) = @_;
    open my $fh, '<', $file;
    my @data = <$fh>;
    close $fh;
    return \@data;
}

sub read_alias_zsh {
    # zsh supports *global* and *suffix* aliases; we expect input to
    # be divided into global, suffix, and regular alias sections
    # (with global aliases duplicated in regular section)
    my ( $file ) = @_;
    my @data;
    open my $fh, '<', $file;
    my $section = "";
    my %global;
    while ( <$fh> ) {
        if ( /^--g/ ) {
            $section = "global";
        } elsif ( /^--s/ ) {
            $section = "suffix";
        } elsif ( /^---/ ) {
            $section = "regular";
        } elsif ( ! /^\S+='/ && !/^\S+=\S+$/ ) {
            # continuation line of multi-line alias definition?
            push @data, $_;
        } elsif ($section eq 'global') {
            chomp;
            $global{$_}++;
        } elsif ($section eq 'suffix') {
            push @data, "alias -s $_";
        } else {
            my ( $name, $val ) = split /=/, $_, 2;
            if ( $global{$name} ) {
                push @data, "alias -g $_";
            } else {
                push @data, "alias $_";
            }
        }
    }
    close $fh;
    return \@data;
}

sub read_alias_prepend {
    # for alias output that does not include  alias  keyword, so it
    # must prepend  alias  to each line of input
    my ( $file ) = @_;
    my @data;
    open my $fh, '<', $file;
    while ( <$fh> ) {
        if ( /^\S+='/ ) {
            push @data, "alias $_";
        } else {
            push @data, $_;
        }
    }
    close $fh;
    return \@data;
}

sub read_alias_csh {
    # alias output is tab separated name/value pairs
    my ( $file ) = @_;
    my @data;
    open my $fh, '<', $file;
    while ( <$fh> ) {
        my ($name,$val) = split /\t/, $_, 2;
        while ( $val =~ m/\\$/ ) {
            $val =~ s/\\$/\\\\/;
            $val .= <$fh>;
        }
        chomp $val;
        if ( $val !~ /'/ ) {
            $val = "'$val'";
        } elsif ( $val !~ /"/ ) {
            $val = qq{"$val"};
        } else {
            $val =~ s/'/\\'/g;
            $val = qq{'$val'};   # this might not be good enough
        }
        push @data, "alias $name $val\n";
    }
    close $fh;
    return \@data;    
}

sub _encode {
    # since Perl 5.18, all assignments to %ENV are stringified
    # so we have to come up with a bytestring encoding of our
    # alias commands
    my $msg = join( "\x{FB}\x{FA}", @_ );
    "\x{FF}\x{FE}\x{FD}\x{FC}" . unpack( "H*", $msg );
}

sub _decode {
    my ( $alias ) = @_;
    if ( ref($alias) && ref($alias) eq 'ARRAY' ) {
        return $alias;
    } elsif ( $alias =~ /^\x{FF}\x{FE}\x{FD}\x{FC}/ ) {
        my $msg = substr( $alias, 4 );
        $msg =~ s/(..)/chr hex $1/ge;
        return [ split /\x{FB}\x{FA}/, $msg ];
    } else {
	require Carp;
        Carp::carp( __PACKAGE__, " decode_alias: input not encoded alias" );
        return $alias;
    }
}


1;

__END__


=head1 NAME

Shell::GetEnv::Alias - parse alias information from subshell

=head1 SYNOPSIS

   # from, e.g., ksh
   $ alias -p > file

   # read alias information from file
   use Shell::GetEnv::Alias;
   $aliases = Shell::GetEnv::Alias::read_alias($file);

=head1 DESCRIPTION

B<Shell::GetEnv::Alias> is used by B<Shell::GetEnv> to parse alias
information from a subshell. When alias information is to be
preserved, B<Shell::GetEnv> will make alias information available
in a file, and B<Shell::GetEnv::Alias> will be used to read the
file and produce a set of shell commands that will replicate the
aliases in another shell (of the same type).

Note that nothing is exportable from this module.


=head1 FUNCTIONS


=over

=item B<read_alias>

Used for shells with alias output in a form that is already
useful, so performs no processing on the output. This is
the case for C<bash> and C<ksh>.

=item B<read_alias_csh>

Used for C<csh> and C<tcsh>, where alias output separates
alias names and values with tabs, and which need to have the
C<alias> keyword preprended to the name value pairs to
make them useful in another script.

=item B<read_alias_prepend>

Used for C<dash> and C<sh>, where alias output does not
include the C<alias> keyword and the command must be
prepended to each line of output.

=item B<read_alias_zsh>

For C<zsh>, which also recognizes B<global> and B<suffix> aliases.
The input is expected to contain several sections corresponding 
to different types of aliases, and this function makes sense of 
the different sections so that the aliases can be 
replicated in a new zsh.

=back

=head1 AUTHOR

Marty O'Brien E<lt>mob@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2018 Smithsonian Astrophysical Observatory

This software is released under the GNU General Public License.  You
may find a copy at

          http://www.gnu.org/licenses

=cut

TODO: test some edge cases:
    alias names with spaces or other unexpected characters
    alias values with newlines
    alias values with quotes

