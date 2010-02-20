use 5.010;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'CPAN::Mini::Visit::Simple',
    VERSION_FROM => 'lib/CPAN/Mini/Visit/Simple.pm', # finds \$VERSION
    AUTHOR       => 'James E Keenan (jkeenan@cpan.org)',
    ABSTRACT     => 'Lightweight traversal of a minicpan repository',
    PREREQ_PM    => {
                     'CPAN::Mini'   => 0,
                     'File::Find'   => 0,
                     'File::Path'   => 2.06,
                     'File::Spec'   => 0,
                     'File::Temp'   => 0.14,
                     'IO::CaptureOutput' => 0,
#                     'Path::Class'  => 0,
                     'Scalar::Util' => 0,
                     'Test::Simple' => 0.44,
                    },
);
