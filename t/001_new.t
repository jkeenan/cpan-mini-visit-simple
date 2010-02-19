# -*- perl -*-

# t/001_new.t - check module loading and create testing directory

use Carp;
use File::Path qw( make_path );
use File::Temp qw( tempdir );
use Path::Class qw( dir );
use Test::More qw(no_plan); # tests =>  3;

BEGIN { use_ok( 'CPAN::Mini::Visit::Simple' ); }

my ( $self, $phony_minicpan, $tdir, $id_dir );

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
    $id_dir = dir($tdir, qw/authors id/);
    eval {
        $self = CPAN::Mini::Visit::Simple->new({
            minicpan => $tdir,
        });
    };
    like($@, qr/Absence of $id_dir implies no valid minicpan/,
        "Got expected error message for malformed minicpan repository" );
}

eval {
    $self = CPAN::Mini::Visit::Simple->new({
        list => {},
    });
};
like($@, qr/Value of 'list' must be array reference/,
    "Got expected error message for bad 'list' value -- must be array ref" );

eval {
    $self = CPAN::Mini::Visit::Simple->new({
        list => [],
    });
};
like($@, qr/Value of 'list' must be non-empty/,
    "Got expected error message for bad 'list' value -- must be non-empty array ref" );

eval {
    $self = CPAN::Mini::Visit::Simple->new({
        start_dir => $phony_minicpan,
    });
};
like($@, qr/Directory $phony_minicpan not found/,
    "Got expected error message for bad 'start_dir' value" );

{
    $tdir = tempdir();
    ok( -d $tdir, "tempdir directory created for testing" );
    $id_dir = dir($tdir, qw/authors id/);
    make_path($id_dir, { mode => 0711 });
    ok( -d $id_dir, "'authors/id' directory created for testing" );
    my $phony_start_dir = dir($tdir, qw/foo bar/);
    make_path($phony_start_dir, { mode => 0711 });
    ok( -d $phony_start_dir, "'start_dir' directory created for testing" );
    eval {
        $self = CPAN::Mini::Visit::Simple->new({
            minicpan  => $tdir,
            start_dir => $phony_start_dir,
        });
    };
    like($@, qr/Directory $phony_start_dir must be subdirectory of $id_dir/,
        "Got expected error message for 'start_dir' that is not subdir of authors/id/" );
}

{
    $tdir = tempdir();
    ok( -d $tdir, "tempdir directory created for testing" );
    $id_dir = dir($tdir, qw/authors id/);
    make_path($id_dir, { mode => 0711 });
    ok( -d $id_dir, "'authors/id' directory created for testing" );
    my $start_dir = dir($id_dir, qw/foo bar/);
    make_path($start_dir, { mode => 0711 });
    ok( -d $start_dir, "'start_dir' directory created for testing" );
    $self = CPAN::Mini::Visit::Simple->new({
        minicpan  => $tdir,
        start_dir => $start_dir,
    });
    isa_ok ($self, 'CPAN::Mini::Visit::Simple');
}

