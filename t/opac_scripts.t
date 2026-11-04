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

# The OPAC scripts run as CGI processes, sent what a browser on an OPAC page sends, with EBSCO's API
# answered from t/data. These pin what a patron gets today, so changes in front of the scripts
# can show they leave it alone.

use Modern::Perl;

use Test::NoWarnings;
use Test::More tests => 10;

use FindBin qw( $Bin );
use lib "$Bin/lib";
use JSON qw( decode_json );

use t::lib::TestBuilder;
use EDSTest;

my $guard = EDSTest::configure();
my $json  = JSON->new;              # t/data is read as characters

# eds-raw.pl double encodes non-ASCII labels, so the field codes are what gets compared
my @field_codes = map { $_->{FieldCode} }
    @{ $json->decode( EDSTest::data('edsinfo.json') )->{AvailableSearchCriteria}->{AvailableSearchFields} };
my $export = $json->decode( EDSTest::data('exportformat.json') );

my $anonymous   = EDSTest::anonymous_session();
my %browser     = ( CGISESSID              => $anonymous->id );
my %eds_session = ( %browser, sessionToken => 'browser-token', guest => 'y' );
my %page        = EDSTest::PAGE_HEADERS;
my %xhr         = EDSTest::XHR_HEADERS;
my %fetch       = EDSTest::FETCH_HEADERS;

my @new_session =
    ( 'POST /authservice/rest/uidauth', 'POST /edsapi/rest/endsession', 'POST /edsapi/rest/createsession' );

sub template_file {
    my ($response) = @_;
    my ($file)     = $response->{body} =~ /<!-- TEMPLATE FILE: (\S+) -->/;
    return $file // q{};
}

subtest 'eds-raw.pl?q=knownitems' => sub {
    plan tests => 7;

    my $response =
        EDSTest::run_script( 'eds-raw.pl', { query => 'q=knownitems', cookies => \%eds_session, headers => \%xhr } );
    is( $response->{status}, 200, 'Status 200' );
    is_deeply(
        [ map { $_->{FieldCode} } @{ decode_json( $response->{body} ) } ], \@field_codes,
        'The cached search fields are returned'
    );
    is_deeply( [ EDSTest::call_paths($response) ], [], 'EBSCO is not called when the browser has an EDS session' );
    is( $response->{cookies}->{sessionToken}, 'browser-token', 'The EDS session cookie is kept' );

    $response =
        EDSTest::run_script( 'eds-raw.pl', { query => 'q=knownitems', cookies => \%browser, headers => \%xhr } );
    is_deeply(
        [ map { $_->{FieldCode} } @{ decode_json( $response->{body} ) } ], \@field_codes,
        'Without an EDS session the search fields are returned too'
    );
    is_deeply( [ EDSTest::call_paths($response) ], \@new_session, '... after an EDS session is created' );
    is( $response->{cookies}->{sessionToken}, 'test-session-token', '... and set as a cookie' );
};

subtest 'eds-raw.pl search' => sub {
    plan tests => 6;

    my $query    = 'q=Search?query-1=AND,history';
    my $response = EDSTest::run_script( 'eds-raw.pl', { query => $query, cookies => \%eds_session, headers => \%xhr } );
    is( $response->{status}, 200, 'Status 200' );
    is(
        decode_json( $response->{body} )->{SearchResult}->{Statistics}->{TotalHits}, 2,
        'The EDS search response is returned'
    );
    is_deeply(
        [ EDSTest::call_paths($response) ], [ 'POST /authservice/rest/uidauth', 'GET /edsapi/rest/Search' ],
        'An auth token is fetched, then the search runs in the browser\'s EDS session'
    );
    is( $response->{calls}->[-1]->{query}, 'query-1=AND,history', 'The query is passed to EDS' );

    $response = EDSTest::run_script( 'eds-raw.pl', { query => $query, cookies => \%browser, headers => \%xhr } );
    is_deeply(
        [ EDSTest::call_paths($response) ], [ @new_session, 'GET /edsapi/rest/Search' ],
        'Without an EDS session one is created before the search'
    );
    is( $response->{cookies}->{guest}, 'y', 'An anonymous visitor is an EDS guest' );
};

subtest 'eds-raw.pl?q=getip' => sub {
    plan tests => 2;

    # The plugin's configure page opens this in a window, with no OPAC cookies
    my $response = EDSTest::run_script( 'eds-raw.pl', { query => 'q=getip', headers => \%page } );
    is( $response->{status}, 200, 'Status 200' );
    like( $response->{body}, qr/^\s*127\.0\.0\.1\s*$/, 'The client address is returned' );
};

subtest 'eds-search.pl' => sub {
    plan tests => 12;

    my $response = EDSTest::run_script(
        'eds-search.pl',
        { query => 'q=Search?query-1=AND,:{history}&default=1', cookies => \%browser, headers => \%page }
    );
    is( $response->{status},      200,              'Status 200' );
    is( template_file($response), 'eds-results.tt', 'The results page is shown' );
    like( $response->{body}, qr/A <span class="term">history<\/span> of testing/, 'The first record is listed' );
    like( $response->{body}, qr/Second record about/,                             'The second record is listed' );
    like(
        $response->{body}, qr/eds-search\.pl\?q=Search\?[^"]*addfacetfilter\(SourceType%3aBooks\)/,
        'Facet links point back to eds-search.pl'
    );
    is_deeply(
        [ EDSTest::call_paths($response) ], [ @new_session, @new_session[ 1, 2 ], 'GET /edsapi/rest/Search' ],
        'An EDS session is created twice, then the search runs'
    );
    like(
        $response->{calls}->[-1]->{query}, qr/^query-1=AND,:history&autosuggest=y/,
        'The profile defaults are added to the query'
    );
    is( $response->{cookies}->{QueryTerm},    'history',            'The search term is kept for the next page' );
    is( $response->{cookies}->{ResultTotal},  2,                    'The hit count is kept for the next page' );
    is( $response->{cookies}->{sessionToken}, 'test-session-token', 'The EDS session is set as a cookie' );

    $response = EDSTest::run_script( 'eds-search.pl', { cookies => \%browser, headers => \%page } );
    is( template_file($response), 'eds-advsearch.tt', 'Without a query the advanced search page is shown' );
    ok( !grep( { $_->{path} =~ /Search/ } @{ $response->{calls} } ), '... and nothing is searched' );
};

subtest 'eds-detail.pl' => sub {
    plan tests => 4;

    my $response = EDSTest::run_script(
        'eds-detail.pl',
        { query => 'q=Retrieve?an=1001|dbid=tdb', cookies => \%eds_session, headers => \%page }
    );
    is( $response->{status},      200,             'Status 200' );
    is( template_file($response), 'eds-detail.tt', 'The detail page is shown' );
    like( $response->{body}, qr/A history of testing/, 'The record is shown' );
    is_deeply(
        [ EDSTest::call_paths($response) ], [ 'POST /authservice/rest/uidauth', 'GET /edsapi/rest/Retrieve' ],
        'The record is retrieved in the browser\'s EDS session'
    );
};

subtest 'pfi-search.pl' => sub {
    plan tests => 4;

    my $response = EDSTest::run_script(
        'pfi-search.pl',
        { query => 'q=Search?query-1=AND,:{JN+a*}|sort=title', cookies => \%browser, headers => \%page }
    );
    is( $response->{status},      200,              'Status 200' );
    is( template_file($response), 'pfi-results.tt', 'The publication results page is shown' );
    like( $response->{body}, qr/Second record about/, 'The records are listed' );
    is( $response->{calls}->[-1]->{path}, '/edsapi/publication/Search', 'The publication API is searched' );
};

subtest 'eds-ac.pl?type=auth' => sub {
    plan tests => 4;

    my $response =
        EDSTest::run_script( 'eds-ac.pl', { query => 'type=auth', cookies => \%eds_session, headers => \%fetch } );
    is( $response->{status},                           200,               'Status 200' );
    is( decode_json( $response->{body} )->{AuthToken}, 'test-auth-token', 'The autocomplete token is returned' );
    is_deeply( [ EDSTest::call_paths($response) ], ['POST /authservice/rest/uidauth'], 'Only the token is requested' );
    like( $response->{calls}->[0]->{content}, qr/"Options":\["autocomplete"\]/, '... for autocomplete' );
};

subtest 'eds-cite.pl' => sub {
    plan tests => 3;

    my $response = EDSTest::run_script(
        'eds-cite.pl',
        { query => 'an=1001&dbid=tdb', cookies => \%eds_session, headers => \%xhr }
    );
    is( $response->{status}, 200, 'Status 200' );
    is_deeply( decode_json( $response->{body} ), $export, 'The RIS export is returned' );
    is(
        $response->{calls}->[-1]->{query}, 'an=1001&dbid=tdb&format=ris',
        'The record is exported as RIS'
    );
};

subtest 'logged in patron' => sub {
    plan tests => 4;

    my $patron = t::lib::TestBuilder->new->build_object(
        { class => 'Koha::Patrons', value => { flags => 0, password_expiration_date => undef, login_attempts => 0 } } );
    my $session = EDSTest::patron_session($patron);

    my $response = EDSTest::run_script(
        'eds-search.pl',
        { query => 'q=Search?query-1=AND,:{history}', cookies => { CGISESSID => $session->id }, headers => \%page }
    );
    is( template_file($response),      'eds-results.tt', 'The results page is shown' );
    is( $response->{cookies}->{guest}, 'n',              'A logged in patron is not an EDS guest' );
    like( $response->{calls}->[-2]->{content}, qr/"Guest":"n"/, '... when the EDS session is created' );

    $response = EDSTest::run_script(
        'eds-raw.pl',
        { query => 'q=Search?query-1=AND,history', cookies => { CGISESSID => $session->id }, headers => \%xhr }
    );
    is( $response->{cookies}->{guest}, 'n', 'The JSON search knows the patron too' );

    $session->delete;
    $session->flush;
    $patron->delete;
};

$anonymous->delete;
$anonymous->flush;
