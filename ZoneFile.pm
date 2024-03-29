package Net::DNS::ZoneFile;

require 5.005_62;

use strict;
use warnings;
use IO::File;
use NetAddr::IP;
use Net::DNS::RR;

our $VERSION = '1.04';
our $Debug = 0;

# Preloaded methods go here.

sub read ($$;$$) {
    my $class = shift;		# Void
    my $name = shift;
    my $root = shift || '.';
    my $state = shift || { origin => '.', rr => [], ttl => 0, root => $root };

    my $fh = new IO::File $name, "r";

    return undef unless $fh;

    return $class->readfh($fh, $root, $state);
}

sub readfh ($$;$$) {
    my $class = shift;		# Void
    my $fh = shift;
    my $root = shift || '.';
    my $state = shift || { origin => '.', rr => [], ttl => 0, root => $root };

    return undef unless $fh;

    my $text = join('', grep { s/;.*$// || 1 } <$fh>);

    return $class->parse(\$text, $root, $state);
}

sub _parse ($$;$$) {
    my $class = shift;
    my $text = shift;
    my $root = shift || '.';
    my $state = shift || { origin => '.', rr => [], ttl => 0, root => $root };
    my $otext = undef;

    $text = $$text;

    our $SoaTTL = 0;
    our $Last = '.';

    while (length $text)
    {
	$text =~ s/;.*$//gm;		# Strip comments
	$text =~ s/[ \t]+/ /gsm;	# Fold whitespace

	do {
				# XXX - The s/// produces a warning that I
				# do not understand on my perl 5.6.0

	    no strict;
	    no warnings;
	
	    $text =~ s/^\s*\n//gsm; 	# Trim empty lines
	};

	warn "<$text> in iteration\n" if $Debug;


#  	if (defined $otext and $otext eq $text) {
#  	    warn "hung on file\n" if $Debug;
#  	    return undef;
#  	}

#  	$otext = $text;

	if ($text =~		# $ORIGIN
	    s/
	    \A\$ORIGIN \s+
            ([\-\d\w\.]+)(\s+;\s+)?([\d\s\w]+)?$
	    //mxi)
	{
	    return undef unless defined $1;

	    my $o = $1;

	    $SoaTTL = $state->{ttl} = 0;

	    if ($o =~ /\.$/) {
		$state->{origin} = $o;
	    } else {
		$state->{origin} = $o . "." . $state->{origin};
	    }

	    warn "# \$ORIGIN set to $state->{origin}\n" if $Debug;

	}
	elsif ($text =~		# $INCLUDE
	       s/
	       \A\$INCLUDE \s+ ([^\s]+) \s*$
	       //mxi)
	{
	    my $inc = $1;

	    substr($inc, 0, 0) = '/' unless $root =~ m!/$!;
	    substr($inc, 0, 0) = $root;

	    warn "root=$root on include $inc\n" if $Debug;

	    return undef unless defined $inc;

	    return undef unless $class->read($inc, $root, $state);
	}
	elsif ($text =~		# $TTL
	       s/
	       \A\$TTL \s+ (\d+)(;?[\d\s\w]+)?\s*$
	       //mxi)
	{

	    return undef unless defined $1;
	    $state->{ttl} = $1;

	}
	elsif ($text =~		# $GENERATE
	       s/
	       \A\$GENERATE \s+ 
	       (\d+) \s* - \s* (\d+) \s+ 
	       (|\*|\@|\.|([-\w\$\d]+(\.[-\w\$\d]+)*\.?)) \s+
	       ((IN|HESIOD|CHAOS) \s+)?
	       (\w+) \s+ 
	       ([-\w\$\d]+((\.[-\w\$\d]+)*)?\.) \s*$
	       //mxi)
	{
	    return undef if $2 < $1;
	    my $rr_template = join(' ', $3, $7 || 'IN', $8, $9);
	    for my $i (reverse $1 .. $2) {
		my $rr = $rr_template . "\n";
		$rr =~ s/\$/$i/g;
		substr($text, 0, 0) = $rr;
	    }
	}
	elsif ($text =~		# SOA
	       s/
               \A(|\*|\s*\@|\.|([-\w\d]+(\.[-\w\d]+)*\.?))
               \s+ ((\d+|IN|HESIOD|CHAOS) \s+)? ((\d+|IN|HESIOD|CHAOS) \s+)?
               (SOA) \s+ ([-\w\d]+(\.[-\w\d]+)*\.?) 
               \s+ ([-\w\d]+(\.[-\w\d]+)*\.) \s* \(
               \s* (\d+) \s+ (\d+) \s+ (\d+) \s+ (\d+) \s+ (\d+) \s* \) \s*$
	       //mxi)
	{
	    my $name	= $1;
	    my $type	= $8;
	    my $host	= $9;
	    my $admin	= $11;
	    my $d1	= $13;
	    my $d2	= $14;
	    my $d3	= $15;
	    my $d4	= $16;
	    my $d5	= $17;

	    my $ct1 = $5;
	    my $ct2 = $7;
	    my ($class,$ttl);
	    if (defined $ct1) {
		if ($ct1 =~ /^\d+$/) {
		    $ttl = $ct1;
		    return undef if defined($ct2) && $ct2 =~ /^\d+$/;
		    $class = $ct2 || 'IN';
		} else {
		    $class = $ct1;
		    return undef if defined($ct2) && $ct2 !~ /^\d+$/;
		    $ttl = defined($ct2) ? $ct2 : $d5;
		}
	    } else {
		$ttl = $d5;
		$class = 'IN';
	    }

	    $SoaTTL = $ttl;

	    $name = $Last if not length $name;
	    $name = $state->{origin} if $name =~ m/\s*\@$/;

	    if ($name !~ /\.$/)
	    {
		$name .= "." . $state->{origin} if $state->{origin} ne '.';
		$name .= "." if $state->{origin} eq '.';
	    }

	    $Last = $name;

#	    warn "# match SOA ", join(' ', $name, $ttl, $class, $type,
#					   $host, $admin, $d1, $d2, $d3, $d4,
#					   $d5), "\n";

	    my $rr = new Net::DNS::RR join(' ', $name, $ttl, $class, $type,
					   $host, $admin, $d1, $d2, $d3, $d4,
					   $d5);

	    return undef unless $rr;
	    push @{$state->{rr}}, $rr;
	}
	elsif ($text =~		# PTR, CNAME or NS
	       s/
 	       \A(|\*|\w+|\s*\@|\.|([-\w\d]+(\.[-\w\d]+)*\.?))
 	       \s+ ((\d+|IN|HESIOD|CHAOS)\s+)? ((\d+|IN|HESIOD|CHAOS)\s+)?
	       (PTR|NS|CNAME) \s+ ([-\w\d]+((\.[-\w\d]+)*)?\.?|\@) \s*$
	       //mxi)
	{
	    my $name	= $1;
	    my $type	= $8;
	    my $data	= $9;

 	    my $ct1 = $5;
 	    my $ct2 = $7;
 	    my ($class,$ttl);
 	    if (defined $ct1) {
 		if ($ct1 =~ /^\d+$/) {
 		    $ttl = $ct1;
 		    return undef if defined($ct2) && $ct2 =~ /^\d+$/;
 		    $class = $ct2 || 'IN';
 		} else {
 		    $class = $ct1;
 		    return undef if defined($ct2) && $ct2 !~ /^\d+$/;
 		    $ttl = defined($ct2) ? $ct2 : $state->{ttl} || $SoaTTL;
 		}
 	    } else {
 		$ttl = $state->{ttl} || $SoaTTL;
 		$class = 'IN';
 	    }
 
	    $name = $Last if not length $name;
	    $name = $state->{origin} if $name =~ m/\s*\@$/;
	    $data = $state->{origin} if $data =~ m/\s*\@$/;

	    if ($name !~ /\.$/)
	    {
		$name .= "." . $state->{origin} if $state->{origin} ne '.';
		$name .= "." if $state->{origin} eq '.';
	    }

	    if ($data !~ /\.$/)
	    {
		$data .= "." . $state->{origin} if $state->{origin} ne '.';
		$data .= "." if $state->{origin} eq '.';
	    }

	    $Last = $name;

	    my $rr = new Net::DNS::RR join(' ', $name, $ttl, $class,
					   $type, $data);

	    return undef unless $rr;

	    push @{$state->{rr}}, $rr;
	}
	elsif ($text =~		# MX
	       s/
 	       \A(|\*\.[\w\d\.]+|\*|\s*\@|\.|([-\w\d]+(\.[-\w\d]+)*\.?))
	       \s+ ((\d+|IN|HESIOD|CHAOS)\s+)? ((\d+|IN|HESIOD|CHAOS)\s+)?
	       (MX) \s+ (\d+) \s+ ([-\w\d]+((\.[-\w\d]+)*)?\.?) \s*$
	       //mxi)
	{
	    my $name	= $1;
	    my $type	= $8;
	    my $pref	= $9;
	    my $data	= $10;

	    my $ct1 = $5;
	    my $ct2 = $7;
	    my ($class,$ttl);
	    if (defined $ct1) {
		if ($ct1 =~ /^\d+$/) {
		    $ttl = $ct1;
		    return undef if defined($ct2) && $ct2 =~ /^\d+$/;
		    $class = $ct2 || 'IN';
		} else {
		    $class = $ct1;
		    return undef if defined($ct2) && $ct2 !~ /^\d+$/;
		    $ttl = defined($ct2) ? $ct2 : $state->{ttl} || $SoaTTL;
		}
	    } else {
		$ttl = $state->{ttl} || $SoaTTL;
		$class = 'IN';
	    }

	    $name = $Last if not length $name;
	    $name = $state->{origin} if $name =~ m/\s*\@$/;

	    if ($name !~ /\.$/)
	    {
		$name .= "." . $state->{origin} if $state->{origin} ne '.';
		$name .= "." if $state->{origin} eq '.';
	    }

	    if ($data !~ /\.$/)
	    {
		$data .= "." . $state->{origin} if $state->{origin} ne '.';
		$data .= "." if $state->{origin} eq '.';
	    }

	    $Last = $name;

	    my $rr = new Net::DNS::RR join(' ', $name, $ttl, $class,
					   $type, $pref, $data);

	    return undef unless $rr;
	    push @{$state->{rr}}, $rr;
	}
	elsif ($text =~		# TXT or HINFO or AAAA
	       s/
 	       \A(|\*|\s*\@|\.|([-\w\d]+(\.[-\w\d]+)*\.?)?)
  	       \s+ ((\d+|IN|HESIOD|CHAOS)\s+)? ((\d+|IN|HESIOD|CHAOS)\s+)?
 	       (TXT|HINFO|AAAA) \s+ (".+?"|[:\d\w]+) \s*$
	       //mxi)
	{
	    my $name	= $1;
	    my $type	= $8;
	    my $data	= $9;

	    my $ct1 = $5;
	    my $ct2 = $7;
	    my ($class,$ttl);
	    if (defined $ct1) {
		if ($ct1 =~ /^\d+$/) {
		    $ttl = $ct1;
		    return undef if defined($ct2) && $ct2 =~ /^\d+$/;
		    $class = $ct2 || 'IN';
		} else {
		    $class = $ct1;
		    return undef if defined($ct2) && $ct2 !~ /^\d+$/;
		    $ttl = defined($ct2) ? $ct2 : $state->{ttl} || $SoaTTL;
		}
	    } else {
		$ttl = $state->{ttl} || $SoaTTL;
		$class = 'IN';
	    }

	    $name = $Last if not length $name;
	    $name = $state->{origin} if $name =~ m/\s*\@$/;

	    $Last = $name;

	    my $rr = new Net::DNS::RR join(' ', $name, $ttl,
					   $class, $type, $data);

	    return undef unless $rr;
	    push @{$state->{rr}}, $rr;
	}
	elsif ($text =~		# A
	       s/
 	       \A(|\*|\*.[-\w\d\.]+|[-\w\d\.]+|\s*\@|\.|[-\w\d]+(((\.[-\w\d]+)*)\.?)?)
 	       \s+ ((\d+|IN|HESIOD|CHAOS)\s+)? ((\d+|IN|HESIOD|CHAOS)\s+)?
  	       (A) \s+ (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}) \s*$
	       //mxi)
	{
	    my $name	= $1;
	    my $type	= $9;
	    my $data	= NetAddr::IP->new($10);

	    my $ct1 = $6;
	    my $ct2 = $8;
	    my ($class,$ttl);
	    if (defined $ct1) {
		if ($ct1 =~ /^\d+$/) {
		    $ttl = $ct1;
		    return undef if defined($ct2) && $ct2 =~ /^\d+$/;
		    $class = $ct2 || 'IN';
		} else {
		    $class = $ct1;
		    return undef if defined($ct2) && $ct2 !~ /^\d+$/;
		    $ttl = defined($ct2) ? $ct2 : $state->{ttl} || $SoaTTL;
		}
	    } else {
		$ttl = $state->{ttl} || $SoaTTL;
		$class = 'IN';
	    }

	    return undef unless $data;

	    $name = $Last if not length $name;
	    $name = $state->{origin} if $name =~ m/\s*\@$/;

	    if ($name !~ /\.$/)
	    {
		$name .= "." . $state->{origin} if $state->{origin} ne '.';
		$name .= "." if $state->{origin} eq '.';
	    }

	    $Last = $name;

	    my $rr = new Net::DNS::RR join(' ', $name, $ttl, $class,
					   $type, $data->addr);

	    return undef unless $rr;
	    push @{$state->{rr}}, $rr;
	} elsif ($text =~ s/^$//gm) { 
	    # clear whitespace
	} else { 
	    warn "Failed to match: $text\n" if $Debug;
	    return undef; 
	}
    }

    return $state->{rr};

}

sub parse ($$;$$) {
    my $class = shift;
    my $rtext = shift;
    my $root = shift || '.';
    my $state = shift || { origin => '.', rr => [], ttl => 0, root => $root };

    return undef unless ref($rtext) eq 'SCALAR';
    my $text = $$rtext;
    return $class->_parse(\$text, $root, $state);
}

1;

__END__

=head1 NAME

Net::DNS::ZoneFile - Perl extension to convert a zone file to a collection of RRs

=head1 SYNOPSIS

  use Net::DNS::ZoneFile;

  my $rrset = Net::DNS::ZoneFile->read($filename[, $root]);

  print $_->string . "\n" for @$rrset;

  my $rrset = Net::DNS::ZoneFile->readfh($fh[, $root]);

  # OR

  my $rrset = Net::DNS::ZoneFile->parse($ref_to_myzonefiletext[, $root]);

=head1 DESCRIPTION

This module parses a zone file and returns a reference to an array of
C<Net::DNS::RR> objects containing each of the RRs given in the zone
in the case that the whole zone file was succesfully
parsed. Otherwise, undef is returned.

The zone file can be specified as a filename, using the
C<-E<gt>read()> method, or as a file handle, using the
C<-E<gt>readfh()> method. If you already have a scalar with the
contents of your zone file, the most efficient way to parse it is by
passing a reference to it to the C<-E<gt>parse()> method.

The optional C<$root> parameter, tells the module where to anchor
B<$INCLUDE> statements found in the zone data. It defaults to the
current directory.

In case of error, undef will be returned.

The primitives B<$ORIGIN> and B<$GENERATE> are understood automatically.

Note that the text passed to C<-E<gt>parse()> by reference, is copied
inside the function to avoid modifying the original text. If this is
not an issue, you can use C<-E<gt>_parse()> instead, which will
happily spare the performance penalty AND modify the input text.

=head2 EXPORT

None by default.


=head1 HISTORY

=over 8

=item 1.00

Original version; created by h2xs 1.1.1.4 with options

  -ACOXcfkn
	Net::DNS::ZoneFile
	-v
	1.00

This is actually, the second version. The first was trying to use
Parse::RecDescent, but the result was a piece of code much more
complex than what was really needed. This made me switch the
implementation to the current regexp engine, which provide faster and
more maintainable code.

=item 1.01

Calin Medianu pointed out that @ can be in the RHS. New tests were
written to this end and the code modified to treat this case in a
manner consistent with BIND/named. This version was not distributed
by mistake.

=item 1.02

Anton Berezin provided patches for some short-sighted assumptions and
bugs. Reduced the strictness of the whitespace requirements for
parsing SOA RRs.

=item 1.03

Added support for a reentrant $INCLUDE. Funs Kessen added support for
AAAA and HINFO.

=item 1.03_1

Funs Kessen submitted patches to make this module behave more like
BIND.

=item 1.04

Release of 1.03_1 as stable.

=back


=head1 AUTHOR

Luis E. Munoz <luismunoz@cpan.org>

=head1 SEE ALSO

perl(1).

=cut
