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
use Test::More tests => 5;

use FindBin qw( $Bin );
use lib "$Bin/lib";

use EDSTest;

my $guard     = EDSTest::configure();
my $anonymous = EDSTest::anonymous_session();
my %request   = (
    cookies => { CGISESSID => $anonymous->id, sessionToken => 'browser-token', guest => 'y' },
    headers => {EDSTest::PAGE_HEADERS},
);
my $robots = qr{<meta name="robots" content="noindex, nofollow" />};

like(
    EDSTest::run_script( 'eds-search.pl', { %request, query => 'q=Search?query-1=AND,:{history}' } )->{body}, $robots,
    'The results page asks crawlers not to index it or follow its links'
);
like( EDSTest::run_script( 'eds-search.pl', \%request )->{body}, $robots, 'So does the advanced search page' );
like(
    EDSTest::run_script( 'eds-detail.pl', { %request, query => 'q=Retrieve?an=1001|dbid=tdb' } )->{body}, $robots,
    'So does the detail page'
);
like(
    EDSTest::run_script( 'pfi-search.pl', { %request, query => 'q=Search?query-1=AND,:{JN+a*}|sort=title' } )->{body},
    $robots, 'So do the publication results'
);

$anonymous->delete;
$anonymous->flush;
