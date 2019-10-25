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
#* DATE MODIFIED: 12/Jan/2015
#* LAST CHANGE DESCRIPTION: FIXED: Return default html if param q is not defined.
#=============================================================================================
#*/
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


use strict;
use warnings;
use CGI;
use C4::Auth;    # get_template_and_user
use C4::Output;
use LWP;
use IO::File;
use JSON;
use URI::Escape;
use HTML::Entities;
use Cwd            qw( abs_path );
use File::Basename qw( dirname );
use Try::Tiny;

my $input = new CGI;
my $dbh   = C4::Context->dbh;

do 'eds-methods.pl';
if($input->param("api") eq 'pub'){our $apiType="publication";}
our $EDSConfig = decode_json(EDSGetConfiguration());
#{if($EDSConfig->{logerrors} eq 'no'){no warnings;local $^W = 0;}
{no warnings;local $^W = 0;


my $pluginsdir = C4::Context->config("pluginsdir");
my @pluginsdir = ref($pluginsdir) eq 'ARRAY' ? @$pluginsdir : $pluginsdir;
my ($PluginDir) = grep { -f $_ . "/Koha/Plugin/EDS.pm" } @pluginsdir;
$PluginDir = $PluginDir . '/Koha/Plugin/EDS/' . C4::Context->preference('opacthemes');

my ( $template, $borrowernumber, $cookie ) = get_template_and_user(
    {
        template_name   => $PluginDir."/modules/eds-raw.tt",
        type            => "opac",
        query           => $input,
		is_plugin           => 1,
        authnotrequired => ( C4::Context->preference("OpacPublic") ? 1 : 0 ),
        flagsrequired   => { borrow => 1 },
    }
);

#manage guest mode.
my $GuestTracker='y';
if($borrowernumber ne undef){
	$GuestTracker='n';
}

my $api_response;

if($input->param("q") eq 'config'){
	$api_response = EDSGetConfiguration();
}elsif($input->param("q") eq 'getip'){
	$api_response = GetLocalIP();
}else{
	# Send Known Items
	if($input->param("q") eq 'knownitems'){
		my $EDSInfo;
		try{
			$EDSInfo =  decode_json(EDSGetInfo(0));
			$api_response = encode_json($EDSInfo->{AvailableSearchCriteria}->{AvailableSearchFields});
		}catch{
			EDSSearch('info');
			$EDSInfo =  decode_json(EDSGetInfo(1));
			$api_response = encode_json($EDSInfo->{AvailableSearchCriteria}->{AvailableSearchFields});
		};
	}else{
		if(defined $input->param("q")){
			$api_response = EDSSearch($input->param("q"),$GuestTracker);
		}else{ 
			$api_response = '<html><head><link rel="stylesheet" type="text/css" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.1/css/bootstrap.min.css" /><script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.2/jquery.min.js"></script><script type="text/javascript" src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.1/js/bootstrap.min.js"></script></head><body></body></html>';
		}
	}	
}

$template->param(
	api_response		=> $api_response,
	plugin_dir		=>$PluginDir,
);

my $EDSConfig = decode_json(EDSGetConfiguration());
my $CookieExpiry = '+'.$EDSConfig->{cookieexpiry}.'m';
if($EDSConfig->{cookieexpiry} eq ' '){ # dont set expiry
	$CookieExpiry='';
}

my $SessionManager = decode_json(EDSGetSessionToken());
my $SessionToken = $input->cookie(
                            -name => 'sessionToken',
                            -value => $SessionManager->{sessiontoken},
                            -expires => $CookieExpiry
                );
my $GuestMode = $input->cookie(
                            -name => 'guest',
                            -value => $SessionManager->{guest},
                            -expires => $CookieExpiry
                );
$cookie = [$cookie, $SessionToken, $GuestMode];

output_html_with_http_headers $input, $cookie, $template->output;
}#end no warnings
