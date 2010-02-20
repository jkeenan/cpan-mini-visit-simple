package CPAN::Mini::Visit::Simple;
use 5.010;
use strict;
use warnings;

our $VERSION = '0.001';
$VERSION = eval $VERSION; ## no critic

use Carp;
use CPAN::Mini ();
use File::Find;
use File::Spec;
use Scalar::Util qw/ reftype /;

sub new {
    my ($class, $args) = @_;
    my %data = ();
    if ( ! $args->{minicpan} ) {
        my %config = CPAN::Mini->read_config;
        if (  $config{local} ) {
            $data{minicpan} = $config{local};
        }
    }
    else {
        $data{minicpan} = $args->{minicpan};
    }
    croak "Directory $data{minicpan} not found"
        unless (-d $data{minicpan});

    my $id_dir = File::Spec->catdir($data{minicpan}, qw/authors id/);
    croak "Absence of $id_dir implies no valid minicpan"
        unless -d $id_dir;
    $data{id_dir} = $id_dir;

    my $self = bless \%data, $class;
    return $self;
}

sub identify_distros {
    my ($self, $args) = @_;

    if ( exists $args->{list} ) {
        croak "Value of 'list' must be array reference"
            unless reftype($args->{list}) eq 'ARRAY';
        croak "Value of 'list' must be non-empty"
            unless scalar(@{$args->{list}});
        $self->{list} = $args->{list};
        return 1;
    }

    if ( defined $args->{start_dir} ) {
        croak "Directory $args->{start_dir} not found"
            unless (-d $args->{start_dir} );
        croak "Directory $args->{start_dir} must be subdirectory of $self->{id_dir}"
            unless ( $args->{start_dir} =~ m/$self->{id_dir}/ );
        $self->{start_dir} = $args->{start_dir};;
    }
    else {
        $self->{start_dir} = $self->{minicpan};
    }

    if ( defined $args->{pattern} ) {
        croak "'pattern' is a regex, which means it must be a SCALAR ref"
            unless (reftype($args->{pattern}) eq 'SCALAR');
    }

    my $archive_re = qr{\.(?:tar\.(?:bz2|gz|Z)|t(?:gz|bz)|zip\.gz)$}i;
    my @found = ();
    find(
        {
            follow => 0,
            no_chdir => 1,
            preprocess => sub { my @files = sort @_; return @files },
            wanted => sub {
                return unless /$archive_re/;
                if ( defined $args->{pattern} ) {
                    return unless $_ =~ m/$args->{pattern}/;
                }
                push @found, $File::Find::name;
            },
        },
        $self->{start_dir},
    );
    $self->{list} = \@found;
    return 1;
}

sub say_list {
    my ($self) = @_;
    say $_ for @{$self->{list}};
}

1;

__END__
=head2 C<new()>

=cut 

=over 4

=item * Purpose

=item * Arguments

=item * Return Value

=cut

