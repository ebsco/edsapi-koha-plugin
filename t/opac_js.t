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
use utf8;

use Test::NoWarnings;
use Test::More tests => 4;

use FindBin qw( $Bin );
use lib "$Bin/lib";
use CGI;
use JSON;

use t::lib::Mocks;
use C4::Context;
use Koha::Cache::Memory::Lite;
use Koha::Database;
use EDSTest;

my $schema     = Koha::Database->new->schema;
my $plugin     = Koha::Plugin::EDS->new( { enable_plugins => 1 } );
my $plugin_dir = EDSTest::plugin_dir();
my $json       = JSON->new;
my $edsinfo    = $json->decode( EDSTest::data('edsinfo.json') );

# The hook output for an OPAC page whose query string is $query
sub opac_js {
    my ($query) = @_;

    local $ENV{REQUEST_METHOD} = 'GET';
    local $ENV{QUERY_STRING}   = $query // q{};

    # CGI.pm reuses the first query string it parsed in a process
    CGI::initialize_globals();
    Koha::Cache::Memory::Lite->flush();
    C4::Context->interface('opac');
    return $plugin->opac_js;
}

sub inlined_language_strings {
    my ($output)  = @_;
    my ($strings) = $output =~ /var edsLang = (\{.*?\});\n/ or return;
    return $json->decode($strings);
}

subtest 'opac_js() tests' => sub {
    plan tests => 12;

    $schema->storage->txn_begin;
    t::lib::Mocks::mock_preference( 'OPACLanguages', 'en,de-DE,fr-FR' );
    $plugin->store_data( { edsinfo => EDSTest::data('edsinfo.json'), defaultsearch => 'koha' } );

    my $output = opac_js();
    like( $output, qr/var defaultSearch="koha";/, 'The default search is set' );

    my ($search_fields) = $output =~ /var edsSearchFields = (\[.*?\]);/;
    is_deeply(
        $json->decode( $search_fields // '[]' ), $edsinfo->{AvailableSearchCriteria}->{AvailableSearchFields},
        'The search fields from the cached EDS info are inlined'
    );
    like( $output, qr/"Titre \\u003cé>"/, 'A < in a label is escaped' );
    unlike( $output, qr/Titre </, 'No raw < from a label reaches the page' );

    my $strings = inlined_language_strings($output);
    is( scalar keys %{ $strings // {} }, 26,                         'All the language strings are inlined' );
    is( $strings->{eds_switch_text},     'Switch to Discovery',      'English is used by default' );
    is( $strings->{pfi_atoz_bar},        'Browse by Journal Title:', 'A string keeps its trailing colon' );

    like(
        $output, qr{<script src="/plugin/Koha/Plugin/EDS/js/EDSScript\.js">},
        'EDSScript.js is loaded from the plugin path'
    );
    my $script_tags = () = $output =~ /<script/g;
    is( $script_tags, 2, 'Without custom JS there is only the inline block and EDSScript.js' );

    is(
        inlined_language_strings( opac_js('language=de-DE') )->{eds_switch_text}, 'Wechsel zu Discovery',
        'The OPAC language picks its language file'
    );
    is(
        inlined_language_strings( opac_js('language=fr-FR') )->{eds_switch_text}, 'Switch to Discovery',
        'A language without a file falls back to default.inc'
    );

    $plugin->store_data( { edsinfo => 'Update Required' } );
    unlike( opac_js(), qr/edsSearchFields/, 'Nothing is inlined when the cached EDS info is not JSON' );

    $schema->storage->txn_rollback;
};

subtest 'custom JS' => sub {
    plan tests => 6;

    $schema->storage->txn_begin;
    $plugin->store_data( { edsinfo => EDSTest::data('edsinfo.json'), defaultsearch => 'koha' } );

    my $custom_dir  = "$plugin_dir/js/custom";
    my $custom_file = "$custom_dir/custom.js";
    my $had_dir     = -d $custom_dir;
    my $saved       = -f $custom_file ? EDSTest::slurp($custom_file) : undef;
    mkdir $custom_dir unless $had_dir;
    my $guard = EDSTest::Guard->new(
        sub {
            if ( defined $saved ) {
                EDSTest::spew( $custom_file, $saved );
            } else {
                unlink $custom_file;
                rmdir $custom_dir unless $had_dir;
            }
        }
    );

    EDSTest::spew( $custom_file, qq{window.edsCustom = 1;\nvar tag = "</script>";\n} );
    my $output = opac_js();
    like( $output, qr/window\.edsCustom = 1;/,   'The custom JS is inlined' );
    like( $output, qr{var tag = "<\\/script>";}, 'A closing script tag in the custom JS is escaped' );
    my $script_tags = () = $output =~ /<script/g;
    is( $script_tags, 3, 'The custom JS gets its own script block' );
    ok(
        index( $output, 'window.edsCustom' ) > index( $output, 'EDSScript.js' ),
        'The custom JS comes after EDSScript.js'
    );

    EDSTest::spew( $custom_file, "  \n" );
    $output      = opac_js();
    $script_tags = () = $output =~ /<script/g;
    is( $script_tags, 2, 'A blank custom.js adds nothing' );

    unlink $custom_file;
    $output      = opac_js();
    $script_tags = () = $output =~ /<script/g;
    is( $script_tags, 2, 'No custom.js adds nothing' );

    $schema->storage->txn_rollback;
};

subtest 'no language files' => sub {
    plan tests => 2;

    $schema->storage->txn_begin;
    $plugin->store_data( { edsinfo => EDSTest::data('edsinfo.json'), defaultsearch => 'koha' } );

    my $lang_dir = "$plugin_dir/bootstrap/includes/lang";
    rename $lang_dir, "$lang_dir.off" or die "$lang_dir: $!";
    my $guard = EDSTest::Guard->new( sub { rename "$lang_dir.off", $lang_dir } );

    my $output = opac_js();
    unlike( $output, qr/var edsLang/, 'Nothing is inlined, so EDSScript.js fetches the language file itself' );
    like( $output, qr/EDSScript\.js/, 'EDSScript.js is still loaded' );

    $schema->storage->txn_rollback;
};
