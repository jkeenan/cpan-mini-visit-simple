package CPAN::Mini::Visit::Simple;
use 5.010;
use strict;
use warnings;

our $VERSION = '0.001';
$VERSION = eval $VERSION; ## no critic

use Carp;
use CPAN::Mini ();
use File::Find;
use Path::Class::Dir;
use Scalar::Util qw/ reftype /;

=head1 NAME

CPAN::Mini::Visit::Simple - Lightweight traversal of a minicpan repository

=head1 SYNOPSIS

    use CPAN::Mini::Visit::Simple;
    $self = CPAN::Mini::Visit::Simple->new({});
    $self->identify_distros();

=head1 DESCRIPTION

This Perl extension is a variant on David Golden's App-CPAN-Mini-Visit.  It
can be used in the following circumstances:


=head1 SUBROUTINES

=head2 C<new()>

=cut 

=over 4

=item * Purpose

CPAN::Mini::Visit::Simple constructor.  While it cannot verify that you have a
complete minicpan repository on disk, it does check that the most essential
directories are present.

=item * Arguments

    $self = CPAN::Mini::Visit::Simple->new({
        minicpan => $phony_minicpan,    # optional
    });

Optional single hash reference.  That hash should have a C<minicpan> element
whose value is the absolute path to your minicpan repository.

If called with no arguments, the constructor will use the value of the
C<local> key-value pair in your F<.minicpanrc> file.

=item * Return Value

CPAN::Mini::Visit::Simple object.

=back

=cut

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

    my $id_dir = Path::Class::Dir->new($data{minicpan}, qw/authors id/);
    croak "Absence of $id_dir implies no valid minicpan"
        unless -d $id_dir;
    $data{id_dir} = $id_dir->stringify;

    my $self = bless \%data, $class;
    return $self;
}

=head2 C<identify_distros()>

=cut 

=over 4

=item * Purpose

Prepare the list of distributions in the minicpan repository which will be
visited.

=item * Arguments

May be called in any of the following two mutually exclusive ways:

=over 4

=item 1 No arguments

    $self->identify_distros();

Will add all distributions found in the minicpan repository to the list of
distributions to be visited.

=item 2 Single hash reference

You may provide a hash reference with B<one> of several elements.  These
elements are mutually exclusive and are listed in descending order of
priority.

=over 4

=item * C<list>

    $minicpan_id_dir = '/home/user/minicpan/authors/id';
    $rv = $self->identify_distros( {
      list => [ 
        "$minicpan_id_dir/D/DR/DROLSKY/Alzabo-0.92.tar.gz",
        "$minicpan_id_dir/D/DR/DROLSKY/DateTime-0.53.tar.gz",
        "$minicpan_id_dir/D/DR/DROLSKY/Params-Validate-0.95.tar.gz",
      ],
    } );

If a C<list> element is used, its value must be a reference to an array
holding an exact list of the minicpan distributions to be visited.

=item * C<start_dir>

    $rv = $self->identify_distros( {
      start_dir   => "$minicpan_id_dir/D/DR/DROLSKY",
    } );

If a C<list> element is not provided but a C<start_dir> element is provided,
its value must be an absolute path to a directory inside the minicpan
repository that is below the F<authors/id/> directory.  The list of
distributions to be visited will consist of all distributions below that point
in the minicpan.

=item * C<pattern>

    $rv = $self->identify_distros( {
      pattern   => qr/Moose/,
    } );

If a C<list> element is provided but a C<pattern>
element is provided, its value must be a compiled regular expression.  The
list of distributions to be visited will consist of all distributions in the
minicpan whose paths match that pattern.

=item * Combination of C<start_dir> and C<pattern>

    $rv = $self->identify_distros( {
      start_dir   => "$minicpan_id_dir/D/DR/DROLSKY",
      pattern   => qr/Moose/,
    } );

You may provide B<both> a C<start_dir> element and a C<pattern>
element.  In this case, the C<start_dir> element takes precedence, I<i.e.,>
the list of distributions to be visited will consist of all distributions
below the C<start_dir> which also match the C<pattern>.

=back

=back

=item * Return Value

Returns true value -- though this is not particularly meaningful.  The list of
distributions to be visited will be stored inside the object and can be
accessed by other methods.

=back

=cut

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

=head2 C<say_list()>

=cut 

=over 4

=item * Purpose

Prints to STDOUT a list of distributions to be visited.

=item * Arguments

    $self->say_list();

None.

=item * Return Value

Implicitly returns true value.

=cut

sub say_list {
    my ($self) = @_;
    say $_ for @{$self->{list}};
}

1;

=head1 BUGS

Report bugs at
F<https://rt.cpan.org/Public/Bug/Report.html?Queue=CPAN-Mini-Visit-Simple>.

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

perl(1).  App-CPAN-Mini-Visit.  CPAN-Mini.

=cut

__END__
=head2 C<new()>

=cut 

=over 4

=item * Purpose

=item * Arguments

=item * Return Value

=cut

