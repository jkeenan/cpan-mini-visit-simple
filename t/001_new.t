# -*- perl -*-

# t/001_new.t - check module loading and create testing directory

use Carp;
use File::Path qw( make_path );
use File::Temp qw( tempdir );
use Path::Class::Dir;
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
    $id_dir = Path::Class::Dir->new($tdir, qw/authors id/);
    eval {
        $self = CPAN::Mini::Visit::Simple->new({
            minicpan => $tdir,
        });
    };
    like($@, qr/Absence of $id_dir implies no valid minicpan/,
        "Got expected error message for malformed minicpan repository" );
}

