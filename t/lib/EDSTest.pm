package EDSTest;

# Helpers for testing the installed EDS plugin from a koha-testing-docker shell

use Modern::Perl;
use CGI;
use File::Temp qw( tempfile );
use FindBin    qw( $Bin );

use C4::Auth;
use C4::Context;
use Koha::Plugins;
use Koha::Plugin::EDS;

use constant GENERATED_FILES => qw( js/EDSScript.js opac/eds-methods.pl );

# What a browser sends for a page load, a jQuery ajax call and a fetch() call
use constant PAGE_HEADERS => (
    'Accept'         => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Sec-Fetch-Mode' => 'navigate',
);
use constant XHR_HEADERS => (
    'Accept'           => 'application/json, text/javascript, */*; q=0.01',
    'X-Requested-With' => 'XMLHttpRequest',
    'Sec-Fetch-Mode'   => 'cors',
);
use constant FETCH_HEADERS => (
    'Accept'         => '*/*',
    'Sec-Fetch-Mode' => 'cors',
);

# A configure save for a site that authenticates to EBSCO with a user id and password
our %SETTINGS = (
    edsusername       => 'testuser',
    edspassword       => 'testpass',
    edsprofileid      => 'edsapi',
    edscustomerid     => 'testcustomer',
    cataloguedbid     => '-',
    catalogueanprefix => '-',
    defaultsearch     => 'koha',
    logerrors         => 'no',
    iprange           => '-',
    cookieexpiry      => '-',
    defaultparams     => '-',
    autocomplete_mode => '-',
    autocomplete      => 'no',
);

=head1 FUNCTIONS

=head2 plugin_dir

The installed plugin's Koha/Plugin/EDS directory, found the way EDS.pm finds it.

=cut

sub plugin_dir {
    my $pluginsdir = C4::Context->config('pluginsdir');
    my @pluginsdir = ref($pluginsdir) eq 'ARRAY' ? @{$pluginsdir} : $pluginsdir;
    my ($dir)      = grep { -f "$_/Koha/Plugin/EDS.pm" } @pluginsdir;
    return "$dir/Koha/Plugin/EDS";
}

=head2 slurp

    my $content = EDSTest::slurp( $path, $layer );

Reads a file as UTF-8, or with the given I/O layer.

=cut

sub slurp {
    my ( $path, $layer ) = @_;
    open my $fh, '<' . ( $layer // ':encoding(UTF-8)' ), $path or die "$path: $!";
    my $content = do { local $/; <$fh> };
    close $fh;
    return $content;
}

=head2 spew

    EDSTest::spew( $path, $content, $layer );

Writes a file as UTF-8, or with the given I/O layer.

=cut

sub spew {
    my ( $path, $content, $layer ) = @_;
    open my $fh, '>' . ( $layer // ':encoding(UTF-8)' ), $path or die "$path: $!";
    print {$fh} $content;
    close $fh;
    return;
}

=head2 data

    my $json = EDSTest::data('edsinfo.json');

=cut

sub data {
    my ($name) = @_;
    return slurp("$Bin/data/$name");
}

=head2 configure

    my $guard = EDSTest::configure( { defaultsearch => 'eds' } );

Stores the settings a configure save stores, with t/data/edsinfo.json as the cached info, and
regenerates EDSScript.js and eds-methods.pl. The plugin's previous data and generated files
come back when the guard goes out of scope.

=cut

sub configure {
    my ($overrides) = @_;

    my $plugin_dir = plugin_dir();
    my $dbh        = C4::Context->dbh;
    my $saved_rows = $dbh->selectall_arrayref(
        q{SELECT plugin_key, plugin_value FROM plugin_data WHERE plugin_class = 'Koha::Plugin::EDS'});

    # The generated files are written as Latin-1, so keep their bytes as they are
    my %saved_files = map { $_ => ( -e "$plugin_dir/$_" ? slurp( "$plugin_dir/$_", ':raw' ) : undef ) } GENERATED_FILES;

    my %settings = ( %SETTINGS, %{ $overrides // {} } );
    my $plugin   = Koha::Plugin::EDS->new( { enable_plugins => 1 } );
    $plugin->store_data(
        { %settings, edsinfo => data('edsinfo.json'), lastedsinfoupdate => '4/Nov/2026', authtoken => q{} } );
    {
        # update_EDSScript_js reads its parameters in list context
        local $CGI::LIST_CONTEXT_WARN = 0;
        $plugin->update_EDSScript_js( CGI->new( { %settings, authtoken => q{}, lastedsinfoupdate => '4/Nov/2026' } ) );
    }

    return EDSTest::Guard->new(
        sub {
            $dbh->do(q{DELETE FROM plugin_data WHERE plugin_class = 'Koha::Plugin::EDS'});
            $dbh->do(
                q{INSERT INTO plugin_data (plugin_class, plugin_key, plugin_value) VALUES ('Koha::Plugin::EDS', ?, ?)},
                undef, @{$_}
            ) for @{$saved_rows};
            foreach my $file ( keys %saved_files ) {
                if ( defined $saved_files{$file} ) {
                    spew( "$plugin_dir/$file", $saved_files{$file}, ':raw' );
                } else {
                    unlink "$plugin_dir/$file";
                }
            }
        }
    );
}

=head2 anonymous_session

    my $session = EDSTest::anonymous_session();

The session an OPAC page gives a visitor who isn't logged in, as a browser has it before
it reaches the plugin.

=cut

sub anonymous_session {
    my $session = C4::Auth::get_session(q{});
    $session->param( 'ip',          '127.0.0.1' );
    $session->param( 'lasttime',    time() );
    $session->param( 'sessiontype', 'anon' );
    $session->param( 'interface',   'opac' );
    $session->flush;
    return $session;
}

=head2 patron_session

    my $session = EDSTest::patron_session($patron);

A logged in OPAC session for the patron, bound to 127.0.0.1 like run_script's requests.

=cut

sub patron_session {
    my ($patron) = @_;

    my $session = C4::Auth::get_session(q{});
    $session->param( 'number',    $patron->borrowernumber );
    $session->param( 'id',        $patron->userid );
    $session->param( 'ip',        '127.0.0.1' );
    $session->param( 'lasttime',  time() );
    $session->param( 'interface', 'opac' );
    $session->flush;
    return $session;
}

=head2 run_script

    my $response = EDSTest::run_script(
        'eds-raw.pl',
        {
            query   => 'q=knownitems',
            cookies => { CGISESSID => 'abc' },
            headers => { EDSTest::XHR_HEADERS },
        }
    );

Runs one of the plugin's OPAC scripts the way Apache's mod_cgi does: a new perl process in the
script's directory with the CGI environment, here with EBSCO answered from t/data by EDSTestMock.

Returns a hashref with status, headers (lowercased name => [ values ]), cookies (name => value
from Set-Cookie), body, calls (the EBSCO requests made, each a hashref with method, path, query
and content) and stderr.

=cut

sub run_script {
    my ( $script, $args ) = @_;
    $args //= {};

    my $opac_dir = plugin_dir() . '/opac';
    my $query    = $args->{query} // q{};
    my %headers  = %{ $args->{headers} // {} };
    my $cookies  = $args->{cookies} // {};
    my ( undef, $calls_file )  = tempfile( UNLINK => 1 );
    my ( undef, $stderr_file ) = tempfile( UNLINK => 1 );

    my $cookie_header = join '; ', map { "$_=$cookies->{$_}" } sort keys %{$cookies};
    my $script_name   = "/plugin/Koha/Plugin/EDS/opac/$script";

    my %env = (
        PATH              => '/usr/local/bin:/usr/bin:/bin',
        PERL5LIB          => join( ':', "$Bin/lib", grep { !ref $_ } @INC ),
        PERL5OPT          => '-MEDSTestMock',
        KOHA_CONF         => $args->{koha_conf} // $ENV{KOHA_CONF},
        EDS_TEST_CALLS    => $calls_file,
        EDS_TEST_DATA     => "$Bin/data",
        GATEWAY_INTERFACE => 'CGI/1.1',
        SERVER_PROTOCOL   => 'HTTP/1.1',
        SERVER_SOFTWARE   => 'Apache',
        SERVER_NAME       => 'localhost',
        SERVER_PORT       => 80,
        HTTP_HOST         => 'localhost',
        REQUEST_METHOD    => 'GET',
        SCRIPT_NAME       => $script_name,
        SCRIPT_FILENAME   => "$opac_dir/$script",
        REQUEST_URI       => $script_name . ( length $query ? "?$query" : q{} ),
        QUERY_STRING      => $query,
        REMOTE_ADDR       => $args->{remote_addr} // '127.0.0.1',
        ( length $cookie_header ? ( HTTP_COOKIE => $cookie_header ) : () ),
    );
    foreach my $name ( keys %headers ) {
        ( my $variable = 'HTTP_' . uc $name ) =~ tr/-/_/;
        $env{$variable} = $headers{$name};
    }

    my $pid = open( my $output_fh, '-|' ) // die "Can't fork: $!";
    unless ($pid) {
        chdir $opac_dir or die "$opac_dir: $!";
        %ENV = %env;
        open STDERR, '>', $stderr_file or die "$stderr_file: $!";
        exec $^X, $script or die "exec $script: $!";
    }
    binmode $output_fh;
    my $output = do { local $/; <$output_fh> };
    close $output_fh;

    my %response = ( status => 500, headers => {}, cookies => {}, body => $output );
    my ( $head, $body ) = split /\r?\n\r?\n/, $output // q{}, 2;
    if ( defined $body ) {
        foreach my $line ( split /\r?\n/, $head ) {
            my ( $name, $value ) = split /:\s*/, $line, 2;
            push @{ $response{headers}->{ lc $name } }, $value;
        }
        ( $response{status} ) = ( $response{headers}->{status}->[0] // '200' ) =~ /^(\d+)/;
        $response{body} = $body;
        foreach my $set_cookie ( @{ $response{headers}->{'set-cookie'} // [] } ) {
            my ( $name, $value ) = $set_cookie =~ /^([^=]+)=([^;]*)/ or next;
            $response{cookies}->{$name} = $value;
        }
    }

    $response{calls} = [
        map {
            my ( $method, $path, $call_query, $content ) = split /\t/, $_, 4;
            { method => $method, path => $path, query => $call_query, content => $content }
        } grep { length } split /\n/,
        slurp($calls_file)
    ];
    $response{stderr} = slurp($stderr_file);

    return \%response;
}

=head2 call_paths

    my @paths = EDSTest::call_paths($response);

The EBSCO requests a response made, as 'METHOD /path' strings.

=cut

sub call_paths {
    my ($response) = @_;
    return map { "$_->{method} $_->{path}" } @{ $response->{calls} };
}

package EDSTest::Guard;

# Runs a code ref when it goes out of scope

sub new {
    my ( $class, $code ) = @_;
    return bless { code => $code }, $class;
}

sub DESTROY {
    my ($self) = @_;
    $self->{code}->();
    return;
}

1;
