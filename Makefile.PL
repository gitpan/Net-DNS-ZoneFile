use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'		=> 'Net::DNS::ZoneFile',
    'VERSION_FROM'	=> 'ZoneFile.pm', # finds $VERSION
    'PREREQ_PM'		=> { 
      Net::DNS::RR => 0,
      Test::More => 0,
      NetAddr::IP => 3.07,
    },
);
