use ExtUtils::MakeMaker;

WriteMakefile (
   NAME         => 'Test::Extreme',
   DISTNAME     => 'Test-Extreme',
   VERSION_FROM => 'lib/Test/Extreme.pm',
   AUTHOR       => 'Asim Jalis',
   ABSTRACT     => 'A perlish unit testing framework',
   PREREQ_PM	=> { 'Carp' => 0, 'Exporter' => 0, },
);
