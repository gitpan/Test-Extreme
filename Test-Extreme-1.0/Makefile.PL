use ExtUtils::MakeMaker;

WriteMakefile (
   NAME         => 'Test::Extreme',
   VERSION_FROM => 'Extreme.pm',
   AUTHOR       => 'Asim Jalis',
   ABSTRACT     => 'A Perlish unit testing framework',
   PREREQ_PM	=> { 'Carp' => 0, 'Exporter' => 0, },
);
