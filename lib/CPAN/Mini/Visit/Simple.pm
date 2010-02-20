package CPAN::Mini::Visit::Simple;
use 5.010;
use strict;
use warnings;

our $VERSION = '0.001';
$VERSION = eval $VERSION; ## no critic

use Carp;
use CPAN::Mini ();
use File::Find;
use Data::Dumper;$Data::Dumper::Indent=1;
use Path::Class qw/ dir file /;
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

    my $id_dir = dir($data{minicpan}, qw/authors id/);
    croak "Absence of $id_dir implies no valid minicpan"
        unless -d $id_dir;
    $data{id_dir} = $id_dir->stringify;

    my $self = bless \%data, $class;
    return $self;
}

sub identify_distros {
    my ($self, $args) = @_;

    if ( defined $args->{list} ) {
        croak "Value of 'list' must be array reference"
            unless reftype($args->{list}) eq 'ARRAY';
        croak "Value of 'list' must be non-empty"
            unless scalar(@{$args->{list}});
        $self->{list} = $args->{list};
    }
    if ( ! exists $self->{list} ) {
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
    }
}

1;

=head1 NAME

CPAN::Mini::Visit::Simple - Lightweight traversal of a minicpan repository

=head1 SYNOPSIS

  use CPAN::Mini::Visit::Simple;
  blah blah blah


=head1 DESCRIPTION

This is a variant on David Golden's App-CPAN-Mini-Visit.

=head1 USAGE

=head1 BUGS

=head1 SUPPORT

=head1 AUTHOR

    James E Keenan
    CPAN ID: jkeenan
    Perl Seminar NY
    jkeenan@cpan.org
    http://thenceforward.net/perl/modules/CPAN-Mini-Visit-Simple/

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).  App-CPAN-Mini-Visit.

=cut


