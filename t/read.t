# This is -*- perl -*-

use Net::DNS::ZoneFile;
use IO::File;

use Test::More tests => 3;

END {
    unlink "./read.txt";
}

#$Net::DNS::ZoneFile::Debug = 1;

my $zone = q{
; This is a real zone, changed to protect the innocent
;
$ORIGIN 10.10.10.in-addr.arpa.
;
    @	30 IN	SOA	dns1.acme.com.		hostmaster.acme.com. (

	2002040300   ; Serial Number
 	    172800   ; Refresh	48 hours
	      3600   ; Retry	 1 hours
	   1728000   ; Expire	20  days
	    172800 ) ; Minimum	48 hours
};

ok(defined Net::DNS::ZoneFile->parse(\$zone), "parse of the test zone");

die if $Net::DNS::ZoneFile::Debug;

my $fh = new IO::File "./read.txt", "w" or die "# Failed to create test file\n";

print $fh $zone;

$fh->close;

$fh = new IO::File "./read.txt" or die "# Failed to open test file\n";

ok(defined Net::DNS::ZoneFile->readfh($fh), 'readfh');

$fh->close;

ok(defined Net::DNS::ZoneFile->read("./read.txt"), 'read');


