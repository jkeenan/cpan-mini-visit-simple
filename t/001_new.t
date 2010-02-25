# -*- perl -*-

# t/001_new.t

use 5.010;
use Carp;
use File::Path qw( make_path );
use File::Spec;
use File::Temp qw( tempdir );
use Test::More tests => 13;

BEGIN { use_ok( 'CPAN::Mini::Visit::Simple' ); }

my ( $self, $phony_minicpan, $tdir, $id_dir );
my ( $real_minicpan, $real_id_dir );

$self = CPAN::Mini::Visit::Simple->new();
isa_ok ($self, 'CPAN::Mini::Visit::Simple');

$self = CPAN::Mini::Visit::Simple->new({});
isa_ok ($self, 'CPAN::Mini::Visit::Simple');

$real_minicpan = $self->get_minicpan;
ok( ( -d $real_minicpan ),
    "Top minicpan directory exists: $real_minicpan" );

$real_id_dir = $self->get_id_dir;
ok( ( -d $real_id_dir ),
    "'authors/id/' directory exists: $real_id_dir" );

$phony_minicpan = '/foo/bar';
eval {
    $self = CPAN::Mini::Visit::Simple->new({
        minicpan => $phony_minicpan,
    });
};
like($@, qr/Directory $phony_minicpan not found/,
    "Got expected error message for non-existent minicpan directory" );

{
    $tdir = tempdir();
    $id_dir = File::Spec->catdir($tdir, qw/authors id/);
    eval {
        $self = CPAN::Mini::Visit::Simple->new({
            minicpan => $tdir,
        });
    };
    like($@, qr/Absence of $id_dir implies no valid minicpan/,
        "Got expected error message for malformed minicpan repository" );
}

{
    $tdir = tempdir();
    $id_dir = File::Spec->catdir($tdir, qw/authors id/);
    make_path($id_dir, { mode => 0711 });
    ok( -d $id_dir, "'authors/id' directory created for testing" );
    $author_dir = File::Spec->catdir($id_dir, qw( A AA AARDVARK ) );
    make_path($author_dir, { mode => 0711 });
    ok( -d $author_dir, "'author's directory created for testing" );

    my @source_list = qw(
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
}
