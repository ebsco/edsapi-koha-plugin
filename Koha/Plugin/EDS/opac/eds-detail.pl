#!/usr/bin/perl -w

#/*
#=============================================================================================
#* WIDGET NAME: Koha EDS Integration Plugin
#* DESCRIPTION: Integrates EDS with Koha
#* KEYWORDS: Koha, ILS, Integration, API, EDS
#* CUSTOMER PARAMETERS: None
#* EBSCO PARAMETERS: None
#* URL: N/A
#* AUTHOR & EMAIL: Alvet Miranda - amiranda@ebsco.com
#* DATE ADDED: 31/10/2013
#* DATE MODIFIED: 10/02/2014
#* LAST CHANGE DESCRIPTION: FIXED: added no warnings
#=============================================================================================
#*/
#
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

use C4::Context;
use CGI;
use C4::Auth;
use C4::Koha;
use C4::Output;
use HTML::Entities;
use LWP;
use IO::File;
use JSON;
use Try::Tiny;
use POSIX qw/ceil/;
use Cwd            qw( abs_path );
use File::Basename qw( dirname );

require 'eds-methods.pl';

my $EDSConfig = decode_json(EDSGetConfiguration());
{no warnings;local $^W = 0;

my $PluginDir = dirname(abs_path($0));
$PluginDir =~s /EDS\/opac/EDS/;

my $cgi = new CGI;

my $template_name;
my $template_type = "basic";
$template_name = $PluginDir.'/modules/eds-detail.tt';

# load the template
my ( $template, $borrowernumber, $cookie ) = get_template_and_user(
    {   template_name   => $template_name,
        query           => $cgi,
        type            => "opac",
		is_plugin           => 1,
        authnotrequired => 1,
    }
);

#manage guest mode.
my $GuestTracker=$cgi->cookie('guest');
if($GuestTracker eq ''){
	$GuestTracker='y';
}else{
	if($borrowernumber){
		if($GuestTracker ne 'set'){$GuestTracker='n';}
	}else{
		if($GuestTracker eq 'set'){$GuestTracker='y';}
	}
}

my $format = $cgi->param("format") || 'html';


my $EDSInfo =  decode_json(EDSGetInfo(0));
my $EDSConfig = decode_json(EDSGetConfiguration());
my $CookieExpiry = '+'.$EDSConfig->{cookieexpiry}.'m';
if($EDSConfig->{cookieexpiry} eq ' '){ # dont set expiry
	$CookieExpiry='';
}



my $EDSQuery = $cgi->param("q");
$EDSQuery =~s/\|/\&/g;



my $EDSResponse;
my @EDSResults;
my $EDSSearchQuery;
my $EDSSearchQueryWithOutPage;
my @EDSFacets;
my @EDSFacetFilters;
my @EDSQueries;
my @EDSLimiters;
if($cgi->param("q")){
	$EDSResponse = decode_json(EDSSearch($EDSQuery,$GuestTracker));
	EDSProcessResults();
}

sub EDSProcessResults
{	#process Search Results
	foreach my $Result ($EDSResponse->{Record}){
		foreach my $Items ($Result->{Items}){
			try{
				my @Items = @{$Items};
				foreach my $Item (@Items){
					$Item = EDSProcessItem($Item,1);
				}
			}catch{
			}
		}
	}
}


	# Pager template params
	$template->param(
		DETAILED_RECORD   => $EDSResponse->{Record},
	    listResults            => 1,
		plugin_dir		=>$PluginDir,
		instancepath	=>$EDSConfig->{instancepath},
		themelang		=>$EDSConfig->{themelangforplugin},
	);
	
	# Social Networks
if ( C4::Context->preference( "SocialNetworks" ) ) {
    $template->param( current_url => $ENV{'HTTP_HOST'}.$ENV{'REQUEST_URI'} );
    $template->param( SocialNetworks => 1 );
}

my $OpacBrowseResults = C4::Context->preference("OpacBrowseResults");
$template->{VARS}->{'OpacBrowseResults'} = $OpacBrowseResults;
$template->{VARS}->{'busc'} = $cgi->cookie("ReturnToResults");	


my $SessionManager = decode_json(EDSGetSessionToken());

my $SessionToken = $cgi->cookie(
                            -name => 'sessionToken',
                            -value => $SessionManager->{sessiontoken},
                            -expires => $CookieExpiry
                );
my $GuestMode = $cgi->cookie(
                            -name => 'guest',
                            -value => $SessionManager->{guest},
                            -expires => $CookieExpiry
                );
$cookie = [$cookie, $SessionToken, $GuestMode];

my $content_type = ( $format eq 'rss' or $format eq 'atom' ) ? $format : 'html';
output_with_http_headers $cgi, $cookie, $template->output, $content_type;

}#end no warnings