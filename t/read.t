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
    @	IN	SOA	dns1.acme.com.		hostmaster.acme.com. (

	2002040300   ; Serial Number
 	    172800   ; Refresh	48 hours
	      3600   ; Retry	 1 hours
	   1728000   ; Expire	20  days
	    172800 ) ; Minimum	48 hours
;
				IN 	NS		dns1.acme.com.
				IN	NS		dns2.acme.com.
;
1	IN	PTR	cha-01.hsrp.acme.com.
2	IN	PTR	cha-00-fe3-0-0.dist.acme.com.
3	IN	PTR	cha-01-fe3-1-0.dist.acme.com.
10	IN 	PTR 	rs6s1.coyote.cha.acme.com.
11	IN 	PTR 	rs7s2.coyote.cha.acme.com.
12	IN 	PTR 	rs8s3.coyote.cha.acme.com.
13	IN 	PTR 	rs9s4.coyote.cha.acme.com.
29	IN 	PTR 	ld01.coyote.cha.acme.com.
30	IN 	PTR 	ld02.coyote.cha.acme.com.
31	IN      PTR     cdv-ccs3.coyote.cha.acme.com.
46	IN	PTR	rs28s3.coyote.cha.acme.com.
48	IN	PTR	rs8s1.coyote.cha.acme.com.
49	IN	PTR	rs9s2.coyote.cha.acme.com.
50	IN 	PTR 	mail.acme.com.
51	IN 	PTR 	rs1s2.coyote.cha.acme.com.
52	IN 	PTR 	rs2s3.coyote.cha.acme.com.
53	IN 	PTR 	rs3s4.coyote.cha.acme.com.
54	IN 	PTR 	rs4s1.coyote.cha.acme.com.
55	IN 	PTR 	rs5s2.coyote.cha.acme.com.
56	IN 	PTR 	relay.acme.com.
57	IN 	PTR 	rs1s2-b.coyote.cha.acme.com.
58	IN 	PTR 	rs2s3-b.coyote.cha.acme.com.
59	IN 	PTR 	rs3s4-b.coyote.cha.acme.com.
60	IN 	PTR 	rs4s1-b.coyote.cha.acme.com.
61	IN 	PTR 	rs5s2-b.coyote.cha.acme.com.
62	IN	PTR	rs8s1-b.coyote.cha.acme.com.
63	IN	PTR	rs9s2-b.coyote.cha.acme.com.
66	IN 	PTR 	autoadministracion.acme.com.
70	IN 	PTR 	rs10s3.coyote.cha.acme.com.
73	IN	PTR	pp0.coyote.cha.acme.com.
74	IN	PTR	pp1.coyote.cha.acme.com.
75	IN	PTR	rs99s1.coyote.cha.acme.com.
77	IN      PTR     pop.acme.com.
78	IN      PTR     postman.acme.com.
79	IN      PTR     mcimap.acme.com.
80	IN 	PTR 	aliasstore.acme.com.
82	IN      PTR     rs14s2.coyote.cha.acme.com.
83	IN	PTR	rs14s3.coyote.cha.acme.com.
84	IN      PTR     rs15s3.coyote.cha.acme.com.
85	IN      PTR     rs16s2.coyote.cha.acme.com.
86	IN	PTR	rs16s3.coyote.cha.acme.com.
87	IN	PTR	rs4s4.coyote.cha.acme.com.
88	IN	PTR	rs19s2.coyote.cha.acme.com.
89	IN	PTR	rs10s4.coyote.cha.acme.com.
90	IN      PTR     pop.acme.com.
91	IN	PTR	rs11s1.coyote.cha.acme.com.
92	IN	PTR	pp2.coyote.cha.acme.com.
97	IN      PTR     rs3s1.coyote.cha.acme.com.
98	IN      PTR     rs4s2.coyote.cha.acme.com.
99	IN      PTR     rs5s3.coyote.cha.acme.com.
100	IN      PTR     rs6s4.coyote.cha.acme.com.
101	IN      PTR     rs4s4.coyote.cha.acme.com.
102	IN      PTR     radius-05.coyote.cha.acme.com.
103	IN      PTR     rs10s4.coyote.cha.acme.com.
105	IN      PTR     rs1s4.coyote.cha.acme.com.
106	IN      PTR     rs7s4.coyote.cha.acme.com.
112	IN	PTR	rs10s2.coyote.cha.acme.com.
113	IN      PTR     rs7s1.coyote.cha.acme.com.
120	IN      PTR     rs5s4.coyote.cha.acme.com.
122	IN	PTR	webmethods.acme.com.
123	IN	PTR	www.acme.com.
124	IN	PTR	rs22s2.coyote.cha.acme.com.
125	IN	PTR	rs22s5.coyote.cha.acme.com.
126	IN      PTR     rs21s1.coyote.cha.acme.com.
127	IN      PTR     rs21s2.coyote.cha.acme.com.
129	IN      PTR     rs22s3.coyote.cha.acme.com.
130	IN      PTR     rs11s4.coyote.cha.acme.com.
131	IN      PTR     prepagojre.acme.com.
132	IN	PTR	rs13s5.coyote.cha.acme.com.
133	IN	PTR	domreg.acme.com.
135	IN	PTR	rs22s1.coyote.cha.acme.com.
136	IN	PTR	rs16s4.coyote.cha.acme.com.
137	IN	PTR	rs13s3.coyote.cha.acme.com.
138	IN	PTR	rs22s4.coyote.cha.acme.com.
139	IN	PTR	rs14s4.coyote.cha.acme.com.
143	IN	PTR	rs15s5.coyote.cha.acme.com.
143	IN      PTR     rs15s6.coyote.cha.acme.com.
144	IN      PTR     rs8s4.coyote.cha.acme.com.
145	IN      PTR     rs10s1.coyote.cha.acme.com.
146	IN	PTR	rs15s6.coyote.cha.acme.com.
150	IN	PTR	rs22s7.coyote.cha.acme.com.
151	IN	PTR	rs15s1.coyote.cha.acme.com.
152	IN 	PTR 	rs5s1.coyote.cha.acme.com. 
153	IN      PTR     rs6s3.coyote.cha.acme.com.
154	IN      PTR     rs20s1.coyote.cha.acme.com.
155	IN      PTR     rs20s2.coyote.cha.acme.com.
156	IN      PTR     rs20s3.coyote.cha.acme.com.
157	IN      PTR     rs20s4.coyote.cha.acme.com.
158	IN	PTR	rs22s6.coyote.cha.acme.com.
160	IN      PTR     rs3s2.coyote.cha.acme.com.
161	IN	PTR	rs13s6.coyote.cha.acme.com.
162	IN	PTR	rs14s6.coyote.cha.acme.com.
163	IN	PTR	rs15s7.coyote.cha.acme.com.
164	IN      PTR     rs16s6.coyote.cha.acme.com.
165	IN      PTR     rs16s7.coyote.cha.acme.com.
166	IN      PTR     ayuda-02.acme.com.
167	IN      PTR     rs13s2.coyote.cha.acme.com.
168	IN      PTR     rs9s3.coyote.cha.acme.com.
169	IN      PTR     correo.acme.com.
170	IN      PTR     rs15s4.coyote.cha.acme.com.
171	IN      PTR     rs13s1.coyote.cha.acme.com.
172	IN	PTR	rs15s2.coyote.cha.acme.com.
173	IN	PTR	rs4s3.coyote.cha.acme.com.
174	IN      PTR     rm5s1.coyote.cha.acme.com.
175	IN      PTR     rm5s2.coyote.cha.acme.com.
176	IN 	PTR 	rs6s2.coyote.cha.acme.com.
178	IN 	PTR 	rs7s3.coyote.cha.acme.com.
180	IN 	PTR 	rs1s1.coyote.cha.acme.com.
181	IN	PTR	rs18s3.coyote.cha.acme.com.
182	IN	PTR	rs18s4.coyote.cha.acme.com.
183	IN 	PTR 	rs2s1.coyote.cha.acme.com.
184	IN 	PTR 	rs2s2.coyote.cha.acme.com.
185	IN 	PTR 	rs2s4.coyote.cha.acme.com.
186	IN 	PTR 	rs3s3.coyote.cha.acme.com.
187	IN 	PTR 	rs13s4.coyote.cha.acme.com.
189	IN 	PTR 	rs14s5.coyote.cha.acme.com.
190	IN 	PTR 	rs9s1.coyote.cha.acme.com.
191	IN 	PTR 	rs10s2.coyote.cha.acme.com.
192	IN	PTR	estadisticas-mcis.acme.com.
193	IN 	PTR 	rs8s2.coyote.cha.acme.com.
194	IN	PTR	rs14s3.coyote.cha.acme.com.
195	IN 	PTR 	boss.acme.com.
196	IN 	PTR 	s06.admin.acme.com.
197	IN 	PTR 	s08.admin.acme.com.
198	IN	PTR	rs16s5.coyote.cha.acme.com.
199	IN	PTR	rs16s5-b.coyote.cha.acme.com.
200	IN	PTR     ovnnm01.ops.acme.com.
200	IN 	PTR 	rm1s1.coyote.cha.acme.com.
201	IN 	PTR 	rm4s2.coyote.cha.acme.com.
202	IN 	PTR 	rm4s4.coyote.cha.acme.com.
203	IN 	PTR 	rm4s3.coyote.cha.acme.com.
204	IN	PTR	rm5s4.coyote.cha.acme.com.
204	IN 	PTR 	rm4s1.coyote.cha.acme.com.
205	IN 	PTR 	rm5s4.coyote.cha.acme.com.
205	IN	PTR	rm1s1.coyote.cha.acme.com.
206	IN 	PTR 	rm5s3.coyote.cha.acme.com.
208	IN      PTR     boss.acme.com.
209	IN 	PTR 	s07.admin.acme.com.
210	IN 	PTR 	atencionalcliente.acme.com.
211	IN      PTR	prueba1.colocation.cha.acme.com.
212	IN      PTR     prueba2.colocation.cha.acme.com.
213	IN	PTR	rm4s5.coyote.cha.acme.com.
213	IN	PTR	rm4s6.coyote.cha.acme.com.
214	IN	PTR	rm5s5.coyote.cha.acme.com.
215	IN	PTR	rm5s6.coyote.cha.acme.com.
216	IN 	PTR 	rm6s2.coyote.cha.acme.com.
217	IN 	PTR 	rm6s3.coyote.cha.acme.com.
218	IN 	PTR 	rm6s1.coyote.cha.acme.com.
219	IN	PTR	tec-01.netmgmt.acme.com.
220	IN 	PTR 	ws1.admin.true.net.
221	IN	PTR	rs19s1.coyote.cha.acme.com.
222	IN	PTR	hp9000.coyote.cha.acme.com.
223	IN	PTR	dbs-01.netmgmt.acme.com.
225	IN 	PTR 	cdv-ccs2.coyote.cha.acme.com.
226	IN 	PTR 	cdv-pcm1-h01.coyote.cha.acme.com.
227	IN 	PTR 	cdv-pcm1-h02.coyote.cha.acme.com.
230	IN      PTR     cdv-ccs1.coyote.cha.acme.com.
232	IN	PTR	pp2-b.coyote.cha.acme.com.
233	IN	PTR	pp2-c.coyote.cha.acme.com.
234	IN	PTR	pp2-d.coyote.cha.acme.com.
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


