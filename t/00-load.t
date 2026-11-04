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
use Test::More tests => 4;

use FindBin qw( $Bin );
use lib "$Bin/lib";

use Koha::Plugins;

BEGIN {
    use_ok('Koha::Plugin::EDS');
    use_ok('EDSTest');
}

subtest 'update_EDSScript_js() tests' => sub {
    plan tests => 4;

    my $plugin_dir = EDSTest::plugin_dir();
    {
        my $guard = EDSTest::configure();

        ok( -f "$plugin_dir/js/EDSScript.js",     'EDSScript.js is generated' );
        ok( -f "$plugin_dir/opac/eds-methods.pl", 'eds-methods.pl is generated' );
        like(
            EDSTest::slurp( "$plugin_dir/opac/eds-methods.pl", ':raw' ), qr/\$edsprofileid = "edsapi";/,
            'eds-methods.pl has the configured profile'
        );
    }
    my $methods =
        -f "$plugin_dir/opac/eds-methods.pl" ? EDSTest::slurp( "$plugin_dir/opac/eds-methods.pl", ':raw' ) : q{};
    unlike( $methods, qr/\$edsprofileid = "edsapi";/, 'the previous eds-methods.pl comes back after the test' );
};
