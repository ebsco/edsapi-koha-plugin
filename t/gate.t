#!/usr/bin/perl

# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# Koha is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Koha; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

use Modern::Perl;

use Test::NoWarnings;
use Test::More tests => 7;

use FindBin qw( $Bin );
use lib "$Bin/lib";
use Cache::Memcached::Fast;
use File::Temp qw( tempfile );
use JSON       qw( decode_json );

use C4::Context;
use EDSTest;

my $guard     = EDSTest::configure();
my $anonymous = EDSTest::anonymous_session();
my %browser   = ( CGISESSID => $anonymous->id, sessionToken => 'browser-token', guest => 'y' );
my %page      = EDSTest::PAGE_HEADERS;
my %xhr       = EDSTest::XHR_HEADERS;
my $search    = 'q=Search?query-1=AND,history';

# A response the gate wrote itself, without loading Koha or calling EBSCO
sub refused_early {
    my ($response) = @_;
    return !@{ $response->{calls} } && !$response->{headers}->{'x-frame-options'};
}

subtest 'JSON scripts' => sub {
    plan tests => 9;

    my $response = EDSTest::run_script( 'eds-raw.pl', { query => $search, headers => \%xhr } );
    is( $response->{status}, 403, 'A call without the OPAC session cookie is refused' );
    ok( refused_early($response), '... before Koha or EBSCO' );
    like( decode_json( $response->{body} )->{error}, qr/only available from the catalog/, '... with a JSON error' );

    $response = EDSTest::run_script( 'eds-raw.pl', { query => $search, cookies => \%browser, headers => \%page } );
    is( $response->{status}, 403, 'Opening the JSON script as a page is refused' );

    $response = EDSTest::run_script(
        'eds-cite.pl',
        { query => 'an=1001&dbid=tdb', cookies => \%browser, headers => { Accept => 'text/html,*/*;q=0.8' } }
    );
    is( $response->{status}, 403, 'So is following a link to it from a client that sends no fetch metadata' );
    ok( refused_early($response), '... before Koha or EBSCO' );

    $response = EDSTest::run_script(
        'eds-raw.pl',
        { query => $search, cookies => { %browser, CGISESSID => q{} }, headers => \%xhr }
    );
    is( $response->{status}, 403, 'An empty session cookie is no session cookie' );

    $response = EDSTest::run_script(
        'eds-ac.pl',
        { query => 'type=auth', cookies => \%browser, headers => { Accept => '*/*' } }
    );
    is( $response->{status}, 200, 'A fetch() from a browser that sends no fetch metadata gets through' );
    is( decode_json( $response->{body} )->{AuthToken}, 'test-auth-token', '... and gets its answer' );
};

subtest 'pages' => sub {
    plan tests => 11;

    my $response = EDSTest::run_script( 'eds-search.pl', { query => $search, headers => \%page } );
    is( $response->{status}, 302, 'A page view without cookies is sent back once' );
    is(
        $response->{headers}->{location}->[0], "eds-search.pl?$search&eds_cookie_check=1",
        '... to the same page, marked as a cookie check'
    );
    my $check = $response->{cookies}->{EDS_COOKIE_CHECK};
    like( $check, qr/^[0-9a-f]{16}$/, '... with a cookie to bring back' );
    ok( refused_early($response), '... before Koha or EBSCO' );

    $response = EDSTest::run_script(
        'eds-search.pl',
        { query => "$search&eds_cookie_check=1", cookies => { EDS_COOKIE_CHECK => $check }, headers => \%page }
    );
    is( $response->{status}, 200, 'Coming back with the cookie gets the page' );
    like( $response->{body}, qr/TEMPLATE FILE: eds-results\.tt/, '... the results page' );

    $response = EDSTest::run_script( 'eds-search.pl', { query => "$search&eds_cookie_check=1", headers => \%page } );
    is( $response->{status}, 403, 'Coming back without it is refused' );
    like( $response->{body}, qr/needs cookies/, '... with an explanation' );
    ok( refused_early($response), '... before Koha or EBSCO' );

    $response = EDSTest::run_script( 'eds-detail.pl', { headers => \%page } );
    is(
        $response->{headers}->{location}->[0], 'eds-detail.pl?eds_cookie_check=1',
        'A page without a query string is sent back the same way'
    );

    $response = EDSTest::run_script(
        'eds-detail.pl',
        { query => 'q=Retrieve?an=1001|dbid=tdb', cookies => \%browser, headers => \%page }
    );
    is( $response->{status}, 200, 'A page view with the OPAC session cookie goes straight through' );
};

subtest 'staff utilities' => sub {
    plan tests => 3;

    # The plugin's configure page opens these on the OPAC host from the staff interface
    my $response = EDSTest::run_script( 'eds-raw.pl', { query => 'q=getip', headers => \%page } );
    is( $response->{status}, 200, 'q=getip works without OPAC cookies' );

    $response = EDSTest::run_script( 'eds-raw.pl', { query => 'q=info', headers => \%page } );
    is( $response->{status}, 200, 'q=info works without OPAC cookies' );
    ok( grep( { $_ eq 'GET /edsapi/rest/info' } EDSTest::call_paths($response) ), '... and fetches the EDS info' );
};

subtest 'rate limits' => sub {
    plan tests => 8;

    my $memcached = Cache::Memcached::Fast->new(
        {
            servers   => [ split /\s*,\s*/, C4::Context->config('memcached_servers') ],
            namespace => C4::Context->config('memcached_namespace') . ':eds_gate:',
        }
    );
    my $visitor  = "gatetest$$";
    my $staff_ip = '192.0.2.1';
    my @keys     = ( "page:$visitor", "json:$visitor", "staff:$staff_ip" );
    my $cleanup  = EDSTest::Guard->new( sub { $memcached->delete($_) for @keys } );

    # Spend each budget up to its limit, so the next request is the first one over it
    $memcached->set( "page:$visitor",   30,  60 );
    $memcached->set( "json:$visitor",   120, 60 );
    $memcached->set( "staff:$staff_ip", 30,  60 );

    my $response = EDSTest::run_script(
        'eds-search.pl',
        { query => $search, cookies => { %browser, CGISESSID => $visitor }, headers => \%page }
    );
    is( $response->{status},                        429, 'The 31st page view in a minute is refused' );
    is( $response->{headers}->{'retry-after'}->[0], 60,  '... with Retry-After' );
    ok( refused_early($response), '... before Koha or EBSCO' );
    like( $response->{body}, qr/Too many requests/, '... with an explanation' );

    $response = EDSTest::run_script(
        'eds-raw.pl',
        { query => $search, cookies => { %browser, CGISESSID => $visitor }, headers => \%xhr }
    );
    is( $response->{status}, 429, 'The 121st JSON call in a minute is refused' );
    like( decode_json( $response->{body} )->{error}, qr/Too many requests/, '... with a JSON error' );

    $response =
        EDSTest::run_script( 'eds-raw.pl', { query => 'q=getip', headers => \%page, remote_addr => $staff_ip } );
    is( $response->{status}, 429, 'The staff utilities are limited per address' );

    $response = EDSTest::run_script( 'eds-raw.pl', { query => $search, cookies => \%browser, headers => \%xhr } );
    is( $response->{status}, 200, 'Other visitors are not affected' );
};

subtest 'without memcached' => sub {
    plan tests => 1;

    my $config = EDSTest::slurp( $ENV{KOHA_CONF} );
    $config =~ s{<memcached_servers>[^<]*</memcached_servers>}{<memcached_servers>127.0.0.1:1</memcached_servers>};
    my ( $fh, $koha_conf ) = tempfile( UNLINK => 1 );
    print {$fh} $config;
    close $fh;

    my $response = EDSTest::run_script(
        'eds-raw.pl',
        { query => 'q=knownitems', cookies => \%browser, headers => \%xhr, koha_conf => $koha_conf }
    );
    is( $response->{status}, 200, 'Requests are not limited when memcached cannot be reached' );
};

subtest 'outside a CGI request' => sub {
    plan tests => 2;

    my $gate = EDSTest::plugin_dir() . '/opac/gate.pl';

    # What the gate prints, in a separate perl so its exit can't end this test
    my $run_gate = sub {
        my (%env) = @_;
        local %ENV = ( PATH => $ENV{PATH}, KOHA_CONF => $ENV{KOHA_CONF}, %env );
        open my $fh, '-|', $^X, '-e', 'print scalar do $ARGV[0]', $gate or die "$gate: $!";
        my $output = do { local $/; <$fh> };
        close $fh;
        return $output;
    };

    # A persistent server compiles the scripts once, with no request in %ENV
    is(
        $run_gate->( SCRIPT_NAME => '/plugin/Koha/Plugin/EDS/opac/eds-raw.pl' ), 1,
        'The gate does nothing without a CGI request'
    );
    is(
        $run_gate->( GATEWAY_INTERFACE => 'CGI/1.1', SCRIPT_NAME => '/plugin/Koha/Plugin/EDS/opac/eds-methods.pl' ),
        1, 'The gate leaves scripts it does not know about alone'
    );
};

$anonymous->delete;
$anonymous->flush;
