# This is -*- perl -*-

use Net::DNS::ZoneFile;
use Test::More tests => 8;

ok(defined Net::DNS::ZoneFile->parse(\q{}), 
   'Empty zone');

ok(defined Net::DNS::ZoneFile->parse(\q{$ORIGIN acme.com.}), 
   'Simple $ORIGIN clause');

ok(defined Net::DNS::ZoneFile->parse(\q{$ORIGIN acme.com. ; comment}), 
   'Simple $ORIGIN clause with comments');

ok(defined Net::DNS::ZoneFile->parse(\q{$ORIGIN acme.com}), 
   'Simple $ORIGIN clause with no trailing dot');

ok(defined Net::DNS::ZoneFile->parse(\q{$ORIGIN acme.com ; comment}), 
   'Simple $ORIGIN clause with comments and no dot');

ok(defined Net::DNS::ZoneFile->parse(\q{$ORIGIN . ; comment}), 
   'Simple $ORIGIN clause with comments and just a dot');

ok(defined Net::DNS::ZoneFile->parse(\q{$ORIGIN .}), 
   'Simple $ORIGIN clause with just a dot');

ok(!defined Net::DNS::ZoneFile->parse(\q{$ORIGIN}),
   '$ORIGIN token alone in the file');


