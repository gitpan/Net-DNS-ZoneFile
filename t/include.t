# This is -*- perl -*-

use Net::DNS::ZoneFile;
use Net::DNS::RR;
use IO::File;

use Test::More tests => 15;

END {
    unlink "./ok.com";
    unlink "./i/ok.com";
    rmdir "./i";
}

ok(mkdir("./i", 0755), "Creation of test directory");

my $fh;

my $zone = q{
its 10 IN A 10.0.0.1
};

my %head = ('.'		=> qq{\$ORIGIN ok.com.\n\$INCLUDE ok.com\n},
	    'i/'	=> qq{\$ORIGIN ok.com.\n\$INCLUDE ok.com\n},
	    './'	=> qq{\$ORIGIN ok.com.\n\$INCLUDE ok.com\n},
	    './i/'	=> qq{\$ORIGIN ok.com.\n\$INCLUDE ok.com\n},
	    );

my $rr = new Net::DNS::RR "its.ok.com. 10 IN A 10.0.0.1";

for my $n (qw{ ok.com i/ok.com }) {
    ok(($fh = new IO::File ">$n"), "Creation of test file $n");
    ok($fh->print($zone), "Population of test zone $n");
    ok($fh->close, "Close of file for zone $n");
}

# $Net::DNS::ZoneFile::Debug = 1;

while (my ($root, $data) =  each %head) {
    my $rr_set = Net::DNS::ZoneFile->parse(\$data, $root);
    ok(defined $rr_set, "Zone parse on $root");
    ok($rr_set->[0]->string eq $rr->string, "RR comparison");
}



