# This is -*- perl -*-

use Net::DNS::ZoneFile;
use Test::More tests => 3;

ok(defined Net::DNS::ZoneFile->parse(\q{$TTL 30}), 
   'Simple $TTL clause');

ok(defined Net::DNS::ZoneFile->parse(\q{$TTL 30 ; comment}), 
   'Simple $TTL clause with comments');

ok(!defined Net::DNS::ZoneFile->parse(\q{$TTL}),
   '$TTL token alone in the file');


