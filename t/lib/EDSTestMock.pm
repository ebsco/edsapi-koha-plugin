package EDSTestMock;

# Loaded into the OPAC scripts through PERL5OPT by EDSTest::run_script, so they get canned EBSCO
# responses from t/data instead of calling eds-api.ebscohost.com, and every call is logged.

use strict;
use warnings;
use HTTP::Response;
use LWP::UserAgent;

my %response_file = (
    uidauth       => 'auth.json',
    ipauth        => 'auth.json',
    endsession    => 'endsession.json',
    createsession => 'createsession.json',
    search        => 'search.json',
    retrieve      => 'retrieve.json',
    info          => 'edsinfo.json',
    exportformat  => 'exportformat.json',
);

{
    no warnings 'redefine';
    *LWP::UserAgent::request = sub {
        my ( $ua, $request ) = @_;

        my $uri = $request->uri;
        my ($endpoint) = $uri->path =~ m{/([^/]+)\z};
        $endpoint = lc( $endpoint // q{} );

        if ( open my $log, '>>', $ENV{EDS_TEST_CALLS} ) {
            print {$log} join( "\t", $request->method, $uri->path, $uri->query // q{}, $request->content // q{} ), "\n";
            close $log;
        }

        my $body = '{"ErrorNumber":"999","ErrorDescription":"Not mocked"}';
        if ( my $file = $response_file{$endpoint} ) {
            open my $fh, '<', "$ENV{EDS_TEST_DATA}/$file" or die "$file: $!";
            $body = do { local $/; <$fh> };
            close $fh;
        }

        my $response = HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'application/json; charset=utf-8' ], $body );
        $response->request($request);
        return $response;
    };
}

1;
