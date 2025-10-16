#!/usr/bin/perl -w

use strict;
use warnings;
use LWP::Simple;
use CGI;
use JSON qw/decode_json encode_json/;

do './eds-methods.pl';

print "Content-type: text/html\n\n";

my $q = CGI->new;
my $ua = LWP::UserAgent->new;
my $type = $q->param('type');
our $EDSConfig = decode_json(EDSGetConfiguration());

# auth to API
if ($type eq "auth"){
    do 'Koha/Plugin/EDS/opac/eds-methods.pl';
    my $api_response = EDSAuthForAutocomplete($EDSConfig);

# req from API
} elsif ($type eq "req"){
    my $contents = get($q->param('u') . "token=&term=&idx=filters=");
}
