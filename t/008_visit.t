# -*- perl -*-

# t/008_visit.t

use 5.010;
use CPAN::Mini::Visit::Simple;
use Carp;
use File::Spec;
use IO::CaptureOutput qw( capture );
use Test::More qw(no_plan); # tests => 30;

my ( $self, $rv );
my ( $real_id_dir, $start_dir );

$self = CPAN::Mini::Visit::Simple->new();
isa_ok ($self, 'CPAN::Mini::Visit::Simple');
$real_id_dir = $self->get_id_dir();
$start_dir = File::Spec->catdir( $real_id_dir, qw( J JK JKEENAN ) );
ok( ( -d $start_dir ), "'start_dir' exists: $start_dir" );

eval {
    $rv = $self->visit( {
        action  => sub {
            my $distro = shift @_;
            my $makefiles;
            my $buildfiles;
            if ( -f 'Makefile.PL' ) {
                $makefiles++;
            }
            if ( -f 'Build.PL' ) {
                $buildfiles++;
            }
        },
        action_args => [],
    } );
};
like($@,
    qr/Must have a list of distributions on which to take action/,
    "Got expected error message:  visit() called before identify_distros()" );

$rv = $self->identify_distros( {
    start_dir   => $start_dir,
} );

{
    my ($stdout, $stderr);
    capture(
        sub {
            $rv = $self->visit( {
                action  => sub {
                    my $distro = shift @_;
                    if ( -f 'Makefile.PL' ) {
                        say "$distro has Makefile.PL";
                    }
                    if ( -f 'Build.PL' ) {
                        say "$distro has Build.PL";
                    }
                },
            } );
        },
        \$stdout,
        \$stderr,
    );
    ok( $rv, "'visit()' returned true value" );
    like($stdout,
        qr/List-Compare-.*?\.tar\.gz has Makefile\.PL/s,
        "Got expected STDOUT"
    );
}

{
    my ($stdout, $stderr);
    capture(
        sub {
            $rv = $self->visit( {
                action  => sub {
                    my $distro = shift @_;
                    if ( -f 'Makefile.PL' ) {
                        say "$distro has Makefile.PL";
                    }
                    if ( -f 'Build.PL' ) {
                        say "$distro has Build.PL";
                    }
                },
                quiet => 1,
            } );
        },
        \$stdout,
        \$stderr,
    );
    ok( $rv, "'visit()' returned true value" );
    like($stdout,
        qr/List-Compare-.*?\.tar\.gz has Makefile\.PL/s,
        "Got expected STDOUT"
    );
}
my $pattern = qr/'visit\(\)' method requires 'action' subroutine reference/;

eval {
    $rv = $self->visit( { quiet => 1 } );
};
like( $@, qr/$pattern/,
    "Got expected error output:  No 'action' argument" );

eval {
    $rv = $self->visit( { action => 'not a reference' } );
};
like( $@, qr/$pattern/,
    "Got expected error output:  'action' argument not a reference" );

eval {
    $rv = $self->visit( { action => {} } );
};
like( $@, qr/$pattern/,
    "Got expected error output:  'action' argument not a code reference" );

{
    my ($stdout, $stderr);
    capture(
        sub {
            $rv = $self->visit( {
                action  => sub {
                    my $distro = shift @_;
                    if ( -f 'Makefile.PL' ) {
                        say "$distro has Makefile.PL";
                    }
                    if ( -f 'Build.PL' ) {
                        say "$distro has Build.PL";
                    }
                },
                action_args => [ 1 .. 3 ],
            } );
        },
        \$stdout,
        \$stderr,
    );
    ok( $rv, "'visit()' returned true value" );
    like($stdout,
        qr/List-Compare-.*?\.tar\.gz has Makefile\.PL/s,
        "Got expected STDOUT"
    );
}

$pattern = qr/'action_args' must be array reference/;

eval {
    $rv = $self->visit( {
        action  => sub {
            my $distro = shift @_;
            my $makefiles;
            my $buildfiles;
            if ( -f 'Makefile.PL' ) {
                $makefiles++;
            }
            if ( -f 'Build.PL' ) {
                $buildfiles++;
            }
        },
        action_args => 'not a reference',
    } );
};
like($@, qr/$pattern/,
    "Got expected error message:  'action_args' must be reference" );

eval {
    $rv = $self->visit( {
        action  => sub {
            my $distro = shift @_;
            my $makefiles;
            my $buildfiles;
            if ( -f 'Makefile.PL' ) {
                $makefiles++;
            }
            if ( -f 'Build.PL' ) {
                $buildfiles++;
            }
        },
        action_args => {},
    } );
};
like($@, qr/$pattern/,
    "Got expected error message:  'action_args' must be an array reference" );
