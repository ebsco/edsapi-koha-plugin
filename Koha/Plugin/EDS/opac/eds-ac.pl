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
    $ua->agent("Koha-EDS-Autocomplete/0.1");
    my $req = HTTP::Request->new(POST => 'https://eds-api.ebscohost.com/authservice/rest/uidauth');
    $req->content_type('application/json');
    $req->content('{"UserId":"'.$EDSConfig->{'edsusername'}.'","Password":"'.$EDSConfig->{'edspassword'}.'","Options":["autocomplete"],"InterfaceId":"'.$EDSConfig->{'edsprofileid'}.'"}');
    my $res = $ua->request($req);

    # handle req
    if ($res->is_success) {
        print $res->content;
    } else {
        print $res->status_line;
    }

# req from API
} elsif ($type eq "req"){
    my $contents = get($q->param('u') . "token=&term=&idx=filters=");
}
