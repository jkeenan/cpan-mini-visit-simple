# -*- perl -*-

# t/00_identify_distros.t - check module loading and create testing directory

use CPAN::Mini::Visit::Simple;
use Carp;
use File::Path qw( make_path );
use File::Spec;
use File::Temp qw( tempdir );
use IO::CaptureOutput qw( capture );
use Test::More tests => 23;

my ( $self, $rv, @list, $phony_minicpan, $tdir, $id_dir );

$self = CPAN::Mini::Visit::Simple->new({});
isa_ok ($self, 'CPAN::Mini::Visit::Simple');

eval {
    $self->identify_distros({
        list => {},
    });
};
like($@, qr/Value of 'list' must be array reference/,
    "Got expected error message for bad 'list' value -- must be array ref" );

eval {
    $self->identify_distros({
        list => [],
    });
};
like($@, qr/Value of 'list' must be non-empty/,
    "Got expected error message for bad 'list' value -- must be non-empty array ref" );

@list = qw(
    /home/user/minicpan/authors/id/A/AA/AARDVARK/Alpha-Beta-0.01-tar.gz
    /home/user/minicpan/authors/id/A/AA/AARDVARK/Gamma-Delta-0.02-tar.gz
    /home/user/minicpan/authors/id/A/AA/AARDVARK/Epsilon-Zeta-0.03-tar.gz
);
ok( $self->identify_distros({ list => \@list, }),
    "identify_distros() returned true value" );
{
    my ($stdout, $stderr);
    capture(
        sub { $self->say_list(); },
        \$stdout,
        \$stderr,
    );
    my $seen = 0;
    foreach my $el (@list) {
        $seen++ if $stdout =~ m/$el/;
    }
    is( $seen, scalar(@list), "All distro names seen on STDOUT" );
}

$self = CPAN::Mini::Visit::Simple->new({});
$phony_minicpan = '/foo/bar';
eval {
    $self->identify_distros({
        start_dir => $phony_minicpan,
    });
};
like($@, qr/Directory $phony_minicpan not found/,
    "Got expected error message for bad 'start_dir' value" );

{
    $tdir = tempdir();
    ok( -d $tdir, "tempdir directory created for testing" );
    $id_dir = File::Spec->catdir($tdir, qw/authors id/);
    make_path($id_dir, { mode => 0711 });
    ok( -d $id_dir, "'authors/id' directory created for testing" );
    my $phony_start_dir = File::Spec->catdir($tdir, qw/foo bar/);
    make_path($phony_start_dir, { mode => 0711 });
    ok( -d $phony_start_dir, "'start_dir' directory created for testing" );
    $self = CPAN::Mini::Visit::Simple->new({
        minicpan  => $tdir,
    });
    isa_ok ($self, 'CPAN::Mini::Visit::Simple');
    eval {
        $self->identify_distros({
            start_dir => $phony_start_dir,
        });
    };
    like($@, qr/Directory $phony_start_dir must be subdirectory of $id_dir/,
        "Got expected error message for 'start_dir' that is not subdir of authors/id/" );
}

{
    $tdir = tempdir();
    ok( -d $tdir, "tempdir directory created for testing" );
    $id_dir = File::Spec->catdir($tdir, qw/authors id/);
    make_path($id_dir, { mode => 0711 });
    ok( -d $id_dir, "'authors/id' directory created for testing" );
    my $start_dir = File::Spec->catdir($id_dir, qw/foo bar/);
    make_path($start_dir, { mode => 0711 });
    ok( -d $start_dir, "'start_dir' directory created for testing" );
    $self = CPAN::Mini::Visit::Simple->new({
        minicpan  => $tdir,
    });
    isa_ok ($self, 'CPAN::Mini::Visit::Simple');
    $self->identify_distros({
        start_dir => $start_dir,
    });
    is( $self->{'start_dir'}, $start_dir,
        "'start_dir' assigned as expected" );
}

$self = CPAN::Mini::Visit::Simple->new({});
say STDERR "\nScanning your actual minicpan repository; this may take a minute";
$self->identify_distros();
ok( defined $self->{'start_dir'}, "'start_dir' assigned" );
ok( defined $self->{'list'}, "'list' assigned" );

$self = CPAN::Mini::Visit::Simple->new({});
eval {
    $self->identify_distros( { pattern => [] } );
};
like($@, qr/'pattern' is a regex, which means it must be a SCALAR ref/,
    "Got expected error message when wrong type of value supplied to 'pattern'" );

{
    $self = CPAN::Mini::Visit::Simple->new({});
    my $start_dir = $self->{id_dir} . q{/J/JK/JKEENAN};
    ok(
        $self->identify_distros( { start_dir => $start_dir, } ),
        "'identify_distros() returned true value"
    );

    my ($stdout, $stderr);
    capture(
        sub { $self->say_list(); },
        \$stdout,
        \$stderr,
    );
    my @expected = qw(
        ExtUtils-ModuleMaker-PBP
        ExtUtils-ModuleMaker
        List-Compare
    );
    my $seen = 0;
    foreach my $el (@expected) {
        $seen++ if $stdout =~ m/$el/;
    }
    is( $seen, scalar(@expected), "All distro names seen on STDOUT" );
}

{
    $self = CPAN::Mini::Visit::Simple->new({});
    my $start_dir = $self->{id_dir} . q{/J/JK/JKEENAN};
    my $pattern = qr/ExtUtils-ModuleMaker/;
    my %distro_args = (
            start_dir => $start_dir,
            pattern   => $pattern,
    );
    ok( $self->identify_distros( \%distro_args ),
        "'identify_distros() returned true value" );
    my ($stdout, $stderr);
    capture(
        sub { $self->say_list(); },
        \$stdout,
        \$stderr,
    );
    my @expected = qw(
        ExtUtils-ModuleMaker-PBP
        ExtUtils-ModuleMaker
    );
    my $seen = 0;
    foreach my $el (@expected) {
        $seen++ if $stdout =~ m/$el/;
    }
    is( $seen, scalar(@expected), "All distro names seen on STDOUT" );
}

