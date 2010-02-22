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
use CPAN::Mini::Visit::Simple::Auxiliary qw(
    $ARCHIVE_REGEX
    dedupe_superseded
);
use Data::Dumper;$Data::Dumper::Indent=1;

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

sub identify_distros_from_derived_list {
    my ($self, $args) = @_;
    croak "Bad argument 'start_dir' provided to identify_distros_from_derived_list()"
        if exists $args->{start_dir};
    croak "Bad argument 'pattern' provided to identify_distros_from_derived_list()"
        if exists $args->{pattern};
    croak "identify_distros_from_derived_list() needs 'list' element"
        unless exists $args->{list}; 
    croak "Value of 'list' must be array reference"
        unless reftype($args->{list}) eq 'ARRAY';
    croak "Value of 'list' must be non-empty"
        unless scalar(@{$args->{list}});
    $self->{list} = dedupe_superseded( $args->{list} );
    return 1;
}

sub identify_distros {
    my ($self, $args) = @_;

    croak "Bad argument 'list' provided to identify_distros()"
        if exists $args->{list};

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

    my $found_ref = $self->_search_from_start_dir( $args );
    $self->{list} = dedupe_superseded( $found_ref );
    return 1;
}

sub _search_from_start_dir {
    my ($self, $args) = @_;
    my @found = ();
    find(
        {
            follow => 0,
            no_chdir => 1,
            preprocess => sub { my @files = sort @_; return @files },
            wanted => sub {
                return unless /$ARCHIVE_REGEX/;
                if ( defined $args->{pattern} ) {
                    return unless $_ =~ m/$args->{pattern}/;
                }
                push @found, $File::Find::name;
            },
        },
        $self->{start_dir},
    );
    return \@found;
}

sub say_list {
    my ($self, $args) = @_;
    if (not defined $args) {
        say $_ for @{$self->{list}};
    }
    else {
        croak "Argument must be hashref" unless reftype($args) eq 'HASH';
        croak "Need 'file' element in hashref" unless exists $args->{file};
        open my $FH, '>', $args->{file}
            or croak "Unable to open handle to $args->{file} for writing";
        say $FH $_ for @{$self->{list}};
        close $FH
            or croak "Unable to close handle to $args->{file} after writing";
    }
}

sub get_list {
    my ($self) = @_;
    return unless defined $self->{list};
    return @{$self->{list}};
}

sub get_list_ref {
    my ($self) = @_;
    return unless defined $self->{list};
    return $self->{list};
}

#    $refreshed_list_ref = $self->refresh_list();
#    $self->identify_distros( { list => $refreshed_list_ref } );

sub refresh_list {
    my ($self) = @_;
    # return undef if called no list previously created
    return unless defined $self->{list};
    # store old list for future recall
    $self->{old_list} = $self->{list};
    # we'll need to get list of all distros from presumably updated minicpan
    # and store in hash.
    # we'll then need to iterate over list and replace values for any distros
    # that have upped their version numbers
    my @refreshed_list;

    return \@refreshed_list;
}

1;
