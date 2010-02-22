# -*- perl -*-

# t/006_refresh_list.t

use 5.010;
use CPAN::Mini::Visit::Simple;
use Carp;
use File::Path qw( make_path );
use File::Spec;
use File::Temp qw( tempfile tempdir );
use Test::More qw(no_plan); # tests => 26;
#use Data::Dumper;$Data::Dumper::Indent=1;

my ( $self, @list, $tdir, $id_dir, $author_dir );
my ( @source_list, $output_list_ref, $refreshed_list_ref );

{
    $tdir = tempdir();
    $id_dir = File::Spec->catdir($tdir, qw/authors id/);
    make_path($id_dir, { mode => 0711 });
    ok( -d $id_dir, "'authors/id' directory created for testing" );
    $author_dir = File::Spec->catdir($id_dir, qw( A AA AARDVARK ) );
    make_path($author_dir, { mode => 0711 });
    ok( -d $author_dir, "'author's directory created for testing" );

    @source_list = qw(
        Alpha-Beta-0.01-tar.gz
        Gamma-Delta-0.02-tar.gz
        Epsilon-Zeta-0.03-tar.gz
    );
    foreach my $distro (@source_list) {
        my $fulldistro = File::Spec->catfile($author_dir, $distro);
        open my $FH, '>', $fulldistro
            or croak "Unable to open handle to $distro for writing";
        say $FH q{};
        close $FH or croak "Unable to close handle to $distro after writing";
        ok( ( -f $fulldistro ), "$fulldistro created" );
    }

    $self = CPAN::Mini::Visit::Simple->new({
        minicpan => $tdir,
    });
    isa_ok ($self, 'CPAN::Mini::Visit::Simple');

    ok( $self->identify_distros(),
        "identify_distros() returned true value" );

    $output_list_ref = $self->get_list_ref();

    my $remove = q{Epsilon-Zeta-0.03-tar.gz};
    my $removed_file = File::Spec->catfile($author_dir, $remove);
    is( unlink($removed_file), 1, "$removed_file deleted" );

    my $update = q{Epsilon-Zeta-0.04-tar.gz};
    my $updated_file = File::Spec->catfile($author_dir, $update);
    open my $FH, '>', $updated_file
        or croak "Unable to open handle to $update for writing";
    say $FH q{};
    close $FH or croak "Unable to close handle to $update after writing";
    ok( ( -f $updated_file ), "$updated_file created" );

    # We have now changed what is in our minicpan repository
    # but we have not yet changed our list of selected distros.
    # We need to refresh that list.  Then we will compare it to @output_list.

    $refreshed_list_ref = $self->refresh_list();

    TODO: {
        local $TODO = "Code not written";

    eval { $self->identify_distros_from_derived_list( { list => $refreshed_list_ref } ) };
    is($@, q{}, "No error code found");
#    ok( $self->identify_distros_from_derived_list( { list => $refreshed_list_ref } ),
#        "identify_distros_from_derived_list() returned true value" );
    }
}
