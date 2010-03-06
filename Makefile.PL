use 5.010;
use ExtUtils::MakeMaker 6.56;
# Require a version of EU:MM sufficient to have 'BUILD_REQUIRES'
# so that we get the modern File::Path::make_path() in our tests.

eval { require CPAN::Mini; };
die "No CPAN::Mini" if "$@";
my $config_file = CPAN::Mini->config_file({});
unless ( defined $config_file and -e $config_file ) {
    die "CPAN::Mini config file not located: $!";
}

WriteMakefile(
    NAME         => 'CPAN::Mini::Visit::Simple',
    VERSION_FROM => 'lib/CPAN/Mini/Visit/Simple.pm',
    AUTHOR       => 'James E Keenan (jkeenan@cpan.org)',
    ABSTRACT     => 'Lightweight traversal of a minicpan repository',
    PREREQ_PM    => {
                     'CPAN::Mini'   => 0,
                     'File::Find'   => 0,
                     'File::Spec'   => 0,
                     'File::Temp'   => 0.14,
                     'Path::Class'  => 0.15,
                     'Scalar::Util' => 0,
                    },
    BUILD_REQUIRES  => {
                     'File::Path'   => 2.06,
                     'IO::CaptureOutput' => 0,
                     'Test::Simple' => 0.44,
                    },
);
