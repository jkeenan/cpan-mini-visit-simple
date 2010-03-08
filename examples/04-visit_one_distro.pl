#!/usr/local/bin/perl
use strict;
use warnings;
use feature qw( :5.10 );
use Carp;
use Cwd;
use File::Basename;
use File::Copy;
use File::Find;
use File::Temp qw( tempdir );
use CPAN::Mini::Visit::Simple;

=head1 NAME

03-visit_one_distro.pl - Use the C<get_id_dir()>, C<identify_distros_from_derived_list()> and C<visit()> methods

=head1 SYNOPSIS

    perl visit_one_distro.pl

=head1 DESCRIPTION

This program illustrates how to use the CPAN::Mini::Visit::Simple
C<get_id_dir()>, C<identify_distros_from_derived_list()> and C<visit()>
methods.

We want to conduct a visit to Adam Kennedy's Params-Util distribution.  The
first step is to put that distribution on the list of distributions to be
examined.  We do that with the C<identify_distros_from_derived_list()> method.

Params-Util contains XS code in the file F<List.xs>.  F<make> compiles that
code into first a C source code file F<List.c> and then into a C object file.
Internally, F<make> calls the Perl 5 core program F<xsubpp> to parse the XS
code.  F<xsubpp>, in turn, is a wrapper around a call to a subroutine in the
Perl 5 core module ExtUtils::ParseXS.  The actual use case was to test out
different versions of ExtUtils::ParseXS and to see whether they resulted in
different C source code files.

As you can see by reading the source code and inline comments, quite a bit of
hackery was needed to achieve this objective.  However, that hackery was
neatly encapsulated in the code reference which was the value for the
C<action> element in the hash passed by reference to the C<visit()> method.

=cut

my $starting_dir = cwd();
my $self = CPAN::Mini::Visit::Simple->new();
my $id_dir = $self->get_id_dir();

my $rv = $self->identify_distros_from_derived_list( {
    list => [ "$id_dir/A/AD/ADAMK/Params-Util-1.00.tar.gz", ],
} );

$rv = $self->visit( {
    quiet => 1,
    action => sub {
        my $distro = shift @_;
        my $gitlib = q{/Users/jimk/gitwork/extutils-parsexs/lib};
        my $exit_code = _perform_comparison_builds($distro, $gitlib);
    },
} );

sub _perform_comparison_builds {
    my ($distro, $gitlib) = @_;
    my $first_exit_code = _perform_one_build($distro);
    carp "$distro did not build" if $first_exit_code;
    my $tdir1 = tempdir ( CLEANUP => 1 );
    my @first_c_files = ();
    find(
        {
            wanted => sub { push @first_c_files, $File::Find::name if (-f $_) }
        },
        '.'
    );
    foreach my $f (@first_c_files) {
        copy $f => qq|$tdir1/| . basename ($f)
            or die "Unable to copy $f: $!";
    }
    system(qq{make clean});

    my $second_exit_code = _perform_one_build($distro, $gitlib);
    carp "$distro did not build" if $second_exit_code;
    my $tdir2 = tempdir ( CLEANUP => 1 );
    my @second_c_files = ();
    find(
        {
            wanted => sub { push @second_c_files, $File::Find::name if (-f $_) }
        },
        '.'
    );
    foreach my $f (@second_c_files) {
        copy $f => qq|$tdir2/| . basename ($f)
            or die "Unable to copy $f: $!";
    }

    my @copied_first_files = glob("$tdir1/*.c");
    foreach my $g (@copied_first_files) {
        my $base = basename($g);
        say STDERR "Trying to diff $base ...";
        my $revised = qq|$tdir2/$base|;
        if ( -f $revised ) {
            system( qq{ diff -Bw $g $revised } );
        }
    }
}

sub _perform_one_build {
    my ($distro, $gitlib) = @_;
    my $tdir = cwd();
    say STDERR "Studying $distro in $tdir";
    return unless (-f 'Makefile.PL' or -f 'Build.PL');
    my ($bfile, $bprogram, $builder, $exit_code);
    if (-f 'Build.PL') {
        # This part not yet developed properly.
        # I'll need to make sure that on the second build ./Build points to
        # proper directory.
        $bfile = q{Build.PL};
        $bprogram = q{./Build};
        $builder = q{MB};
    }
    else {
        # Hack to get EUMM to DWIM:
        # By shift-ing $gitlib onto @INC, in running Makefile.PL perl first
        # uses modules found in $gitlib.  My devel version of EUPXS is, of
        # course, found there, as is an unaltered version of xsubpp.
        # EUMM begins at the 0th-element of @INC in its
        # search for XSUBPPDIR, so it stores $gitlib/ExtUtils in that
        # attribute and uses the version of xsubpp there to compile.
        #
        # XSUBPPDIR = /Users/jimk/gitwork/extutils-parsexs/lib/ExtUtils
        # XSUBPP = $(XSUBPPDIR)$(DFSEP)xsubpp
        # XSUBPPRUN = $(PERLRUN) $(XSUBPP)
        # XSPROTOARG =
        # XSUBPPDEPS = /usr/local/lib/perl5/5.10.1/ExtUtils/typemap $(XSUBPP)
        # XSUBPPARGS = -typemap /usr/local/lib/perl5/5.10.1/ExtUtils/typemap
        # XSUBPP_EXTRA_ARGS = 
        # 
        # Note that we're still using the default 'typemap' associated with
        # the installed perl.
        #
        # PROBLEM:  The call to 'xsubpp' performed by 'make' needs to be
        # something like:
        # /usr/local/bin/perl/ -I$gitlib $(XSUBPP) so that we read the variant
        # ParseXS.pm.
        # XSUBPPPARENTDIR = /Users/jimk/gitwork/extutils-parsexs/lib
        # XSUBPP = $(XSUBPPDIR)$(DFSEP)xsubpp
        # XSUBPPRUN = $(PERLRUN) -I$(XSUBPPPARENTDIR) $(XSUBPP)
        #
        # SOLUTION:  Hack up a version of ExtUtils::MM_Unix to permit an
        # assignment to XSUBPPPARENTDIR.  Place this version in that same
        # directory!

        $bfile = defined $gitlib
            ? qq{-I$gitlib Makefile.PL}
            : q{Makefile.PL};
        $bprogram = q{make};
        $builder = q{EUMM};
    }
    $exit_code = system(qq{$^X $bfile && $bprogram});
}
