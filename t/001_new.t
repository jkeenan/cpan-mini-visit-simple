# -*- perl -*-

# t/001_new.t - check module loading and create testing directory

use Carp;
use File::Temp qw( tempdir );
use Path::Class qw( dir );
use Test::More qw(no_plan); # tests =>  3;

BEGIN { use_ok( 'CPAN::Mini::Visit::Simple' ); }

my $self;

$self = CPAN::Mini::Visit::Simple->new({});
isa_ok ($self, 'CPAN::Mini::Visit::Simple');

my $phony_minicpan = '/foo/bar';
eval {
    $self = CPAN::Mini::Visit::Simple->new({
        minicpan => $phony_minicpan,
    });
};
like($@, qr/Directory $phony_minicpan not found/,
    "Got expected error message for non-existent minicpan directory" );

my $tdir = tempdir();
my $id_dir = dir($tdir, qw/authors id/);
eval {
    $self = CPAN::Mini::Visit::Simple->new({
        minicpan => $tdir,
    });
};
like($@, qr/Absence of $id_dir implies no valid minicpan/,
    "Got expected error message for malformed minicpan repository" );

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

