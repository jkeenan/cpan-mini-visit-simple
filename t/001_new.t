# -*- perl -*-

# t/001_new.t

use Carp;
use File::Path qw( make_path );
use File::Spec;
use File::Temp qw( tempdir );
use Test::More tests =>  5;

BEGIN { use_ok( 'CPAN::Mini::Visit::Simple' ); }

my ( $self, $phony_minicpan, $tdir, $id_dir );

$self = CPAN::Mini::Visit::Simple->new();
isa_ok ($self, 'CPAN::Mini::Visit::Simple');

$self = CPAN::Mini::Visit::Simple->new({});
isa_ok ($self, 'CPAN::Mini::Visit::Simple');

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

