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
#* DATE MODIFIED: 30/06/2014
#* LAST CHANGE DESCRIPTION: FIXED: Added IP authentication
#*							reset authtoken and session token when clicking update info
#*							set guest=n if IP
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
use feature qw(switch);
use Encode;



my $input = new CGI;
my $dbh   = C4::Context->dbh;

my ( $edsusername, $edsprofileid, $edspassword, $edscustomerid, $defaultsearch, $cookieexpiry, $cataloguedbid, $catalogueanprefix, $authtoken, $logerrors, $edsinfo, $lastedsinfoupdate, $edsswitchtext, $kohaswitchtext, $edsselecttext, $edsselectinfo, $kohaselectinfo, $instancepath, $themelangforplugin, $defaultEDSQuery, $SessionToken, $GuestTracker)="";

my $PluginClass='Koha::Plugin::EDS';
my $table='plugin_data';

    my $sql = "SELECT plugin_key, plugin_value FROM plugin_data WHERE plugin_class = ? ";
    my $sth = $dbh->prepare($sql);
    $sth->execute( $PluginClass );
$sth->execute();
while ( my $r = $sth->fetchrow_hashref() ) {
given($r->{plugin_key}){
		when('edsusername') {$edsusername=$r->{plugin_value};}
		when('edsprofileid') {$edsprofileid=$r->{plugin_value};}
		when('edspassword') {$edspassword=$r->{plugin_value};}
		when('edscustomerid') {$edscustomerid=$r->{plugin_value};}
		when('defaultsearch') {$defaultsearch=$r->{plugin_value};}
		when('cookieexpiry') {$cookieexpiry=$r->{plugin_value};}
		when('cataloguedbid') {$cataloguedbid=$r->{plugin_value};}
		when('catalogueanprefix') {$catalogueanprefix=$r->{plugin_value};}
		when('logerrors') {$logerrors=$r->{plugin_value};}
		when('authtoken') {$authtoken=$r->{plugin_value};}
		when('edsswitchtext') {$edsswitchtext=$r->{plugin_value};}
		when('kohaswitchtext') {$kohaswitchtext=$r->{plugin_value};}
		when('edsselecttext') {$edsselecttext=$r->{plugin_value};}
		when('edsselectinfo') {$edsselectinfo=$r->{plugin_value};}
		when('kohaselectinfo') {$kohaselectinfo=$r->{plugin_value};}
		when('edsinfo') {$edsinfo=$r->{plugin_value};$edsinfo = Encode::encode('UTF-8', $edsinfo);}
		when('instancepath') {$instancepath=$r->{plugin_value};}
		when('themelangforplugin') {$themelangforplugin=$r->{plugin_value};}
		when('lastedsinfoupdate') {$lastedsinfoupdate=$r->{plugin_value};
			my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
			my @months = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
			my $dateString = $mday.'/'.$months[$mon].'/'.(1900+$year);
			if($dateString ne $lastedsinfoupdate){ # update info daily
				my $getInfo = EDSSearch('info');	
			}
		}
	}
}

die "The EDS plugin appears to be unconfigured.\n" unless $edsprofileid;

{no warnings;local $^W = 0;

my $CookieExpiry = '+'.$cookieexpiry.'m';
if($cookieexpiry eq ' '){ # dont set expiry
	$CookieExpiry='';
}

my ( $template, $user, $cookie ) = get_template_and_user(
    {
        template_name   => "eds-raw.tmpl",
        type            => "opac",
        query           => $input,
		is_plugin		=>1,
        authnotrequired => ( C4::Context->preference("OpacPublic") ? 1 : 0 ),
        flagsrequired   => { borrow => 1 },
    }
);
#manage guest status.
$SessionToken = $input->cookie('sessionToken');
$GuestTracker = $input->cookie('guest');
if($SessionToken eq ""){
	$GuestTracker='y';
	$SessionToken=CreateSession($GuestTracker);
}
1;


#EBSCO API START
sub CallREST
{
	my ($method, $uri, $body, $auth, $sess) = @_;
	my $req = HTTP::Request->new( $method, $uri );
	$req->header( 'Content-Type' => 'application/json' );
	$req->header( 'x-authenticationToken' => $auth );
	$req->header( 'x-sessionToken' => $sess );
	#if($body != ''){$req->content( $body );}
	$req->content( $body );
	my $lwp = LWP::UserAgent->new;
	my $response = $lwp->request( $req );
	return $response->content;
}

sub CreateAuth
{
	#ask for AuthToken from EDSAPI
	my $uri = 'https://eds-api.ebscohost.com/authservice/rest/uidauth';
	my $json = '{"UserId":"'.$edsusername.'","Password":"'.$edspassword.'","InterfaceId":"KohaEDS"}';
	
	if($edsusername eq "-"){
		$uri = 'https://eds-api.ebscohost.com/authservice/rest/ipauth';
		$json = '{"InterfaceId":"KohaEDS"}';
	}
	
	
	my $response =  CallREST('POST',$uri,$json, '', '');
	$authtoken = decode_json( $response );
	$authtoken = $authtoken->{AuthToken};
	$dbh->do("UPDATE $table SET plugin_value = ? WHERE plugin_class= ? AND plugin_key= ? ", undef, $authtoken, $PluginClass, 'authtoken'); 
	return $authtoken;
}

sub GetAuth
{
	return $authtoken;
}

sub CreateSession
{
	#end session
	my $uri = 'http://eds-api.ebscohost.com/edsapi/rest/endsession'; 
	my $json = '{"sessiontoken":"'.$input->cookie('sessionToken').'"}';
	if($authtoken eq ''){
		$authtoken = CreateAuth();
	}
	my $response =  CallREST('POST',$uri,$json, $authtoken, '');
	
	if($edsusername eq "-"){#Guest= no automatically if IP
		$GuestTracker='n';
	}

	#ask for SessionToken from EDSAPI
	$uri = 'http://eds-api.ebscohost.com/edsapi/rest/createsession'; 
	$json = '{"Profile":"'.$edsprofileid.'","Guest":"'.$GuestTracker.'","Org":"'.$edscustomerid.'"}'; 

	
	$response =  CallREST('POST',$uri,$json, $authtoken, '');
	
	$SessionToken = decode_json( $response );
	if($SessionToken->{ErrorNumber}==104){
		$authtoken = CreateAuth();
		$response =  CallREST('POST',$uri,$json, $authtoken, '');
		$SessionToken = decode_json( $response )
	}
		$SessionToken = $SessionToken->{SessionToken};
		if($GuestTracker eq 'n'){
		$GuestTracker='set';}

	return $SessionToken;
}

sub GetSession
{
	if($GuestTracker eq 'n'){
		return CreateSession();
	}else{
		if($GuestTracker eq 'y' and ($input->cookie('guest') eq 'set') ){
			return CreateSession();
		}else{
			return $SessionToken;
		}
	}
}

sub EDSGetConfiguration
{
	my $JSONConfig = '{"defaultsearch":"'.$defaultsearch.'","logerrors":"'.$logerrors.'","cookieexpiry":"'.$cookieexpiry.'","cataloguedbid":"'.$cataloguedbid.'","catalogueanprefix":"'.$catalogueanprefix.'","edsswitchtext":"'.$edsswitchtext.'","kohaswitchtext":"'.$kohaswitchtext.'","edsselecttext":"'.$edsselecttext.'","edsselectinfo":"'.$edsselectinfo.'","themelangforplugin":"'.$themelangforplugin.'","instancepath":"'.$instancepath.'","kohaselectinfo":"'.$kohaselectinfo.'"}';
	return $JSONConfig;
}

sub EDSSearch
{	
	my ($EDSQuery, $GuestStatus) = @_;
	if($input->param("default") eq 1){
		$EDSQuery=$EDSQuery.EDSDefaultQueryBuilder();

	}
	$GuestTracker = $GuestStatus;
	if($EDSQuery =~m/\{.*?\}/){
		my $encodedTerm=$&;

		$encodedTerm=~s/{//g;
		$encodedTerm=~s/}//g;
		$encodedTerm=~s/\,/\\,/g;
		$encodedTerm=~s/:/\\\:/g;
		$encodedTerm=~s/\(/\\\(/g;
		$encodedTerm=~s/\)/\\\)/g;
		
		$EDSQuery =~s/\{.*?\}/$encodedTerm/;
	}
	$EDSQuery =~s/ /\+/g;
	my $uri = 'http://eds-api.ebscohost.com/edsapi/rest/'.$EDSQuery; 
	$uri=~s/\|/\&/g;
	#	use Data::Dumper; die Dumper $uri;
	my $response;
	if($EDSQuery eq "info"){
		$response =  CallREST('GET',$uri,'', CreateAuth(), CreateSession());
	}else{
		$response =  CallREST('GET',$uri,'', GetAuth(), GetSession());
	}
	if(index($response,'ErrorNumber')!=-1){ # TODO: check for 104 or 109 error and request accordingly
		$response =  CallREST('GET',$uri,'', CreateAuth(), CreateSession());
	}	

	if($EDSQuery eq "info"){
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
		my @months = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
		my $dateString = $mday.'/'.$months[$mon].'/'.(1900+$year);
		$response=~s/\"Label\"\:\"ISBN\"\}/\"Label\"\:\"ISBN\"\}\,\{\"FieldCode\"\:\"JN\"\,\"Label\"\:\"Journal Title\"\}/; #" Hack to add Journal Title search
		$dbh->do("UPDATE $table SET plugin_value = ? WHERE plugin_class= ? AND plugin_key= ? ", undef, $response, $PluginClass, 'edsinfo'); 
		$dbh->do("UPDATE $table SET plugin_value = ? WHERE plugin_class= ? AND plugin_key= ? ", undef, $dateString, $PluginClass, 'lastedsinfoupdate'); 
		return 'info stored';
	}else{
		return $response;
	}
}

sub EDSProcessItem
{
	my ($Item,$MakeLinks) = @_;
		#$Item->{Data}= decode_entities($Item->{Data}); # decoding manually. Using this displays the ? diamond.
		$Item->{Data} =~s/&lt;/</g;
		$Item->{Data} =~s/&gt;/>/g;
		$Item->{Data} =~s/&quot;/"/g; #"
		$Item->{Data} =~s/<highlight/<span class="term"/g;
		$Item->{Data} =~s/<br \/>/, /g;
		$Item->{Data} =~s/<\/highlight/<\/span/g;
		if($Item->{Group} eq 'URL'){
			$Item->{Data} =~s/<link/<a/g;
			$Item->{Data} =~s/linkWindow/target/g;
			$Item->{Data} =~s/linkTerm/href/g;				
			$Item->{Data} =~s/<\/link/<\/a/g;		
		}
		if(($Item->{Data}=~m/searchLink/) && $MakeLinks ){
			$Item->{Data}=~s/searchLink fieldCode/a href/g;
			$Item->{Data}=~s/\" term\=\"/\:/g; #"
			$Item->{Data}=~s/searchLink\>/a\>/g;		
			$Item->{Data}=~s/href\=\"/href=\"eds-search.pl\?q=Search\?query\-1\=AND\,/g; #"
			$Item->{Data}=~s/""/"/; #";
			$Item->{Data}=~s/\:/\:\{/g;
			$Item->{Data}=~s/\"\>/\}\"\>/g;#"
		}
	return $Item;
}

sub EDSGetInfo
{
	my ($getInfoAgain) = @_;
	if($getInfoAgain == 1){
		my $sql = "SELECT plugin_key, plugin_value FROM plugin_data WHERE plugin_key='edsinfo' AND plugin_class = ? ";
		my $sth = $dbh->prepare($sql);
		$sth->execute( $PluginClass );
		$sth->execute();
		while ( my $r = $sth->fetchrow_hashref() ) {
		given($r->{plugin_key}){
				when('edsinfo') {$edsinfo=$r->{plugin_value};$edsinfo = Encode::encode('UTF-8', $edsinfo);}
			}
		}
	}
	return $edsinfo;
}

sub EDSGetSessionToken
{
	my $JSONSession = '{"sessiontoken":"'.$SessionToken.'","guest":"'.$GuestTracker.'"}';
	return $JSONSession;
}

sub EDSDefaultQueryBuilder
{
	$defaultEDSQuery = "";
	my $EDSInfoData = decode_json($edsinfo);

	
	my @ExpanderDefaults = @{$EDSInfoData->{AvailableSearchCriteria}->{AvailableExpanders}};
	foreach my $ExpanderDefault (@ExpanderDefaults){
		if($ExpanderDefault->{DefaultOn} eq 'y'){
			$defaultEDSQuery = $defaultEDSQuery.'|expander='.$ExpanderDefault->{Id};
		}
	}
	my @AvailableSearchModes = @{$EDSInfoData->{AvailableSearchCriteria}->{AvailableSearchModes}}; 	
	foreach my $AvailableSearchMode (@AvailableSearchModes){
		if($AvailableSearchMode->{DefaultOn} eq 'y'){
			$defaultEDSQuery = $defaultEDSQuery.'|searchmode='.$AvailableSearchMode->{Mode};
		}
	}
	my @AvailableLimiters = @{$EDSInfoData->{AvailableSearchCriteria}->{AvailableLimiters}}; 	
	foreach my $AvailableLimiter (@AvailableLimiters){
		if($AvailableLimiter->{DefaultOn} eq 'y'){
			if($AvailableLimiter->{Type} eq 'select'){
				$defaultEDSQuery = $defaultEDSQuery.'|limiter='.$AvailableLimiter->{Id}.':'.'y';
			}
		}
	}
		
	$defaultEDSQuery = $defaultEDSQuery.'|resultsperpage='.$EDSInfoData->{ViewResultSettings}->{ResultsPerPage};	
	$defaultEDSQuery = $defaultEDSQuery.'|view='.$EDSInfoData->{ViewResultSettings}->{ResultListView};
		
	return $defaultEDSQuery;			
		
}
}#end no warnings