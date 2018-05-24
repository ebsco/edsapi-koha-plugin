#!/usr/bin/perl -w

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
use Try::Tiny;
use Net::IP;

our $apiType = 'rest';
my $input = new CGI;
my $dbh   = C4::Context->dbh;

my ( $edsusername, $edsprofileid, $edspassword, $edscustomerid, $defaultsearch, $cookieexpiry, $cataloguedbid, $catalogueanprefix, $authtoken, $logerrors, $iprange, $edsinfo, $lastedsinfoupdate, $defaultparams, $defaultEDSQuery, $SessionToken, $GuestTracker, $autocomplete, $autocomplete_mode)="";

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
		when('iprange') {$iprange=$r->{plugin_value};}
		when('authtoken') {$authtoken=$r->{plugin_value};}
		when('autocomplete') {$autocomplete=$r->{plugin_value};}
		when('autocomplete_mode') {$autocomplete_mode=$r->{plugin_value};}
		when('defaultparams') {$defaultparams=$r->{plugin_value};}
		when('edsinfo') {$edsinfo=$r->{plugin_value};$edsinfo = Encode::encode('UTF-8', $edsinfo);}
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
        template_name   => "eds-raw.tt",
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
	$GuestTracker=CheckIPAuthentication();
	$SessionToken=CreateSession();
}
1;


#EBSCO API START
sub CallREST
{
	my ($method, $uri, $body, $auth, $sess) = @_;
	my $req = HTTP::Request->new( $method, $uri );
	$req->header( 'Content-Type' => 'application/json' );
	$req->header( 'Accept-Encoding' => 'gzip, deflate' );
	$req->header( 'x-authenticationToken' => $auth );
	$req->header( 'x-sessionToken' => $sess );
	#if($body != ''){$req->content( $body );}
	$req->content( $body );
	my $lwp = LWP::UserAgent->new;
	my $response = $lwp->request( $req );
	return $response->decoded_content(charset => 'none');
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
	#use Data::Dumper; die Dumper 'gtracker='.$GuestTracker.' cookie='.$input->cookie('guest');

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

	#$GuestTracker = CheckIPAuthentication();

	#ask for SessionToken from EDSAPI
	$uri = 'http://eds-api.ebscohost.com/edsapi/rest/createsession';
	$json = '{"Profile":"'.$edsprofileid.'","Guest":"'.$GuestTracker.'","Org":"'.$edscustomerid.'"}';

	$response =  CallREST('POST',$uri,$json, $authtoken, '');

	try{
		$SessionToken = decode_json( $response );
	}catch{
		$authtoken = CreateAuth();
		$response =  CallREST('POST',$uri,$json, $authtoken, '');
		$SessionToken = decode_json( $response );
	};

	if($SessionToken->{ErrorNumber}==104){
		$authtoken = CreateAuth();
		$response =  CallREST('POST',$uri,$json, $authtoken, '');
		$SessionToken = decode_json( $response )
	}
		$SessionToken = $SessionToken->{SessionToken};
		#if($GuestTracker eq 'n'){
		#$GuestTracker='set';}

	return $SessionToken;
}

sub GetSession
{
	#use Data::Dumper; die Dumper 'gtracker='.$GuestTracker.' cookie='.$input->cookie('guest');
	if($input->cookie('guest') eq ''){
		return $SessionToken;
	}elsif($GuestTracker ne $input->cookie('guest')){
		if(CheckIPAuthentication() ne 'n'){
			return CreateSession();
		}else{
			return $SessionToken;
		}
	}else{
		return $SessionToken;
	}




#	if($GuestTracker eq 'n'){
#		return CreateSession();
#	}else{
#		if($GuestTracker eq 'y' and ($input->cookie('guest') eq 'set') ){
#			return CreateSession();
#		}else{
#			return $SessionToken;
#		}
#	}

}

sub EDSGetConfiguration
{
	my $JSONConfig = '{"defaultsearch":"'.$defaultsearch.'","logerrors":"'.$logerrors.'","iprange":"'.$iprange.'","cookieexpiry":"'.$cookieexpiry.'","cataloguedbid":"'.$cataloguedbid.'","catalogueanprefix":"'.$catalogueanprefix.'","defaultparams":"'.$defaultparams.'","autocomplete": "'.$autocomplete.'", "autocomplete_mode": "'.$autocomplete_mode.'", "edsusername":"'.$edsusername.'", "edsprofileid":"'.$edsprofileid.'", "edspassword":"'.$edspassword.'"}';
    # when('edsusername') {$edsusername=$r->{plugin_value};}
    # when('edsprofileid') {$edsprofileid=$r->{plugin_value};}
    # when('edspassword') {$edspassword=$r->{plugin_value};}
	return $JSONConfig;
}

sub EDSSearch
{
	my ($EDSQuery, $GuestStatus) = @_;
	if($input->param("default") eq 1){
		$EDSQuery=$EDSQuery.EDSDefaultQueryBuilder();
	}


	if(CheckIPAuthentication() ne 'n'){ # Apply guest status from caller if not IP authenticated.
		$GuestTracker = $GuestStatus;
	}

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
	my $uri = 'http://eds-api.ebscohost.com/edsapi/'.$apiType.'/'.$EDSQuery;
	$uri=~s/\|/\&/g;
	#	use Data::Dumper; die Dumper $uri;
	my $response;
	if($EDSQuery eq "info"){
		$response =  CallREST('GET',$uri,'', CreateAuth(), CreateSession());
	}else{
		$response =  CallREST('GET',$uri,'', GetAuth(), GetSession());
	}
	if(index($response,'ErrorNumber')!=-1){ # TODO: check for 104 or 109 error and request accordingly
		#use Data::Dumper; die Dumper $response;
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
	my $defaultEDSQuery = "";
	my $EDSInfoData = decode_json($edsinfo);

	my @AutoSuggests = @{$EDSInfoData->{AvailableSearchCriteria}->{AvailableDidYouMeanOptions}};
	foreach my $AutoSuggest (@AutoSuggests){
		# $input->param("default")
		if ($AutoSuggest->{Id} eq "AutoCorrect" && $input->param("nocorrect") eq 1){
			$defaultEDSQuery = lc $defaultEDSQuery.'|autocorrect=n';
			$input->delete("nocorrect");
		} else {
			$defaultEDSQuery = lc $defaultEDSQuery.'|'.$AutoSuggest->{Id}.'='.$AutoSuggest->{DefaultOn};
		}
	}

	my @ExpanderDefaults = @{$EDSInfoData->{AvailableSearchCriteria}->{AvailableExpanders}};
	foreach my $ExpanderDefault (@ExpanderDefaults){
		if($ExpanderDefault->{DefaultOn} eq 'y'){
			$defaultEDSQuery = $defaultEDSQuery.'|expander='.$ExpanderDefault->{Id};
		}
	}

	if($apiType eq "rest"){
		my @AvailableSearchModes = @{$EDSInfoData->{AvailableSearchCriteria}->{AvailableSearchModes}};
		foreach my $AvailableSearchMode (@AvailableSearchModes){
			if($AvailableSearchMode->{DefaultOn} eq 'y'){
				$defaultEDSQuery = $defaultEDSQuery.'|searchmode='.$AvailableSearchMode->{Mode};
			}
		}
	}
	if($apiType eq "rest"){
		my @AvailableLimiters = @{$EDSInfoData->{AvailableSearchCriteria}->{AvailableLimiters}};
		foreach my $AvailableLimiter (@AvailableLimiters){
			if($AvailableLimiter->{DefaultOn} eq 'y'){
				if($AvailableLimiter->{Type} eq 'select'){
					$defaultEDSQuery = $defaultEDSQuery.'|limiter='.$AvailableLimiter->{Id}.':'.'y';
				}
			}
		}
	}
	if($apiType eq "rest"){
		if(defined $EDSInfoData->{AvailableSearchCriteria}->{AvailableRelatedContent}){
			my @AvailableRelatedContents = @{$EDSInfoData->{AvailableSearchCriteria}->{AvailableRelatedContent}};
			foreach my $AvailableRelatedContent (@AvailableRelatedContents){
				if($AvailableRelatedContent->{DefaultOn} eq 'y'){
					if($AvailableRelatedContent->{Type} eq 'emp'){
						$defaultEDSQuery = $defaultEDSQuery.'|action='.$AvailableRelatedContent->{AddAction};
					}
					if($AvailableRelatedContent->{Type} eq 'rs'){
						$defaultEDSQuery = $defaultEDSQuery.'|action='.$AvailableRelatedContent->{AddAction};
					}
				}
			}
		}
	}

	$defaultEDSQuery = $defaultEDSQuery.'|resultsperpage='.$EDSInfoData->{ViewResultSettings}->{ResultsPerPage};
	$defaultEDSQuery = $defaultEDSQuery.'|view='.$EDSInfoData->{ViewResultSettings}->{ResultListView};
	$defaultEDSQuery = $defaultEDSQuery.'|includeimagequickview='.$EDSInfoData->{ViewResultSettings}->{IncludeImageQuickView}->{DefaultOn};

	return $defaultEDSQuery;

}

sub CheckIPAuthentication
{
	my $GuestForIP = 'y';
	if($edsusername eq "-"){#Guest= no automatically if IP// Keep to support IP restricted sites.
		$GuestTracker='n';
		$GuestForIP = 'n';
	}
	if($GuestTracker ne "n"){ # User has not logged in or authtoken is not IP. Do a local IP check.
		if(length($iprange) > 4){ # Check local IP range if specified.
			my @allowedIPs = split /,/, $iprange;
			my $localIP      = Net::IP->new($ENV{'REMOTE_ADDR'});
			foreach my $allowedIP (@allowedIPs){
				my $currentRange = Net::IP->new($allowedIP);
				my $ipMatch = $currentRange->overlaps($localIP) ? 1 : 0;
				#use Data::Dumper; die Dumper 'IPMatch='.$ipMatch.'/rangeip='.$allowedIP.'/localip='.$localIP;
				if($ipMatch==1){
					$GuestTracker='n';
					$GuestForIP = 'n';
					last; # exit foreach
				}
			}
		}
	}
	#use Data::Dumper; die Dumper 'GuestForIP='.$GuestForIP;
	return $GuestForIP;
}

sub GetLocalIP
{
	return $ENV{'REMOTE_ADDR'};
}

sub CartSendLinks
{
	my ($template_res,@bibs) = @_;
	my $EDSConfig = decode_json(EDSGetConfiguration());
	foreach my $biblionumber (@bibs) { # SM: EDS
		if($biblionumber =~m/\|/){
			if(!($biblionumber =~m/$EDSConfig->{cataloguedbid}/)){
				$biblionumber =~s/\|/\&dbid\=/g;
				$template_res =~s/\|/\&dbid\=/g;
				$template_res =~s/\/cgi\-bin\/koha\/opac-detail\.pl\?biblionumber\=$biblionumber/\/plugin\/Koha\/Plugin\/EDS\/opac\/eds-detail.pl\?q\=Retrieve\?an\=$biblionumber/;
			}
		}else{
			$template_res =~s/\|$EDSConfig->{cataloguedbid}//;
		}
	}
	$template_res =~s/\&dbid/\|dbid/g;
	return $template_res;
}

sub ProcessEDSCartItems
{
	my ($biblionumber, $eds_data, $record, $dat) = @_;

	my $EDSConfig = decode_json(EDSGetConfiguration());

	if(!($biblionumber =~m/$EDSConfig->{cataloguedbid}/)){
		$eds_data = decode_json(uri_unescape($eds_data));

		my @eds_dataItems =@{$eds_data->{Records}};
		foreach my $edsDataItem (@eds_dataItems){
			if(exists $edsDataItem->{$biblionumber}){
				$record = $edsDataItem->{$biblionumber};
				last;
			}
		}

		my $recordJSON = "{";
		my $recordXML = '<?xml version="1.0" encoding="UTF-8"?>
					<record
						xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
						xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd"
						xmlns="http://www.loc.gov/MARC21/slim">
						 <leader>000000000000000000000000</leader>
						';

		#Title
		try{
				my $EDSRecordTitle = $record->{Record}->{RecordInfo}->{BibRecord}->{BibEntity}->{Titles}[0]->{TitleFull};
				$recordXML .= '  <datafield tag="245" ind1="0" ind2="0">
									<subfield code="a" label="Titles">'.$EDSRecordTitle.'</subfield>
								  </datafield>
								  ';
				$recordJSON .= '"title":"'.$EDSRecordTitle.'",';
		}catch{};

		#Subject
		try{
				my $EDSRecordSubjects = $record->{Record}->{RecordInfo}->{BibRecord}->{BibEntity}->{Subjects};
				foreach my $EDSRecordSubject (@{$EDSRecordSubjects}){
					$recordXML .= '  <datafield tag="611" ind1="0" ind2="0">
									<subfield code="a" label="Subject">'.$EDSRecordSubject->{SubjectFull}.'</subfield>
								  </datafield>
								  ';
				}
		}catch{};

		#Author
		try{
				my $EDSRecordAuthors = $record->{Record}->{RecordInfo}->{BibRecord}->{BibRelationships}->{HasContributorRelationships};
				foreach my $EDSRecordAuthor (@{$EDSRecordAuthors}){
					$recordXML .= '  <datafield tag="100" ind1="0" ind2="0">
									<subfield code="a" label="Subject">'.$EDSRecordAuthor->{PersonEntity}->{Name}->{NameFull}.'</subfield>
								  </datafield>
								  ';
					$recordJSON .= '"author":"'.$EDSRecordAuthor->{PersonEntity}->{Name}->{NameFull}.'",';
				}
		}catch{};


		#URL
		try{
				my $EDSRecordURL = $record->{Record}->{PLink};
				$recordXML .= '  <datafield tag="856" ind1="0" ind2="0">
									<subfield code="u" label="Accession Number">'.$EDSRecordURL.'</subfield>
									<subfield code="y" label="Accession Number">'.$EDSRecordURL.'</subfield>
									<subfield code="z" label="Accession Number">'.$EDSRecordURL.'</subfield>
								  </datafield>
								  ';
		}catch{};

		#Document Type - TODO needs work.
		try{
				my $EDSRecordType = $record->{Record}->{Header}->{PubType};
				$recordXML .= '  <datafield tag="006" ind1="0" ind2="0">
									<subfield code="a" label="Accession Number">'.$EDSRecordType.'</subfield>
								  </datafield>
								  ';
				$recordXML .= '  <datafield tag="007" ind1="0" ind2="0">
									<subfield code="a" label="Accession Number">'.$EDSRecordType.'</subfield>
								  </datafield>
								  ';
				$recordXML .= '  <datafield tag="008" ind1="0" ind2="0">
									<subfield code="a" label="Accession Number">'.$EDSRecordType.'</subfield>
								  </datafield>
								  ';
		}catch{};

		#Identifiers: ISSN/ISBN
		try{
				my $EDSRecordIdentifiers = $record->{Record}->{RecordInfo}->{BibRecord}->{BibRelationships}->{IsPartOfRelationships}[0]->{BibEntity}->{Identifiers};

				foreach my $EDSRecordIdentifier (@{$EDSRecordIdentifiers}){
					if($EDSRecordIdentifier->{Type} =~m/issn/){
						$recordJSON .= '"issn":"'.$EDSRecordIdentifier->{Value}.'",';
						$recordXML .= '  <datafield tag="022" ind1="0" ind2="0">
										<subfield code="a" label="ISSN">'.$EDSRecordIdentifier->{Value}.'</subfield>
									  </datafield>
									  ';
					}elsif($EDSRecordIdentifier->{Type} =~m/isbn/){
						$recordJSON .= '"isbn":"'.$EDSRecordIdentifier->{Value}.'",';
						$recordXML .= '  <datafield tag="020" ind1="0" ind2="0">
										<subfield code="a" label="ISSN">'.$EDSRecordIdentifier->{Value}.'</subfield>
									  </datafield>
									  ';
					}
				}
		}catch{};

		#Dates
		try{
				my $EDSRecordDate = $record->{Record}->{RecordInfo}->{BibRecord}->{BibRelationships}->{IsPartOfRelationships}[0]->{BibEntity}->{Dates}[0];
				$recordJSON .= '"copyrightdate":"'.$EDSRecordDate->{Y}.'",';
				$recordXML .= '<datafield tag="260" ind1=" " ind2=" ">
									<subfield code="c">'.$EDSRecordDate->{Y}.'</subfield>
								</datafield>
								  ';
		}catch{};



		#Accession Number
		try{
				my $EDSRecordAN = $record->{Record}->{Header}->{DbId}.'.'.$record->{Record}->{Header}->{An};
				$recordJSON .= '"biblioitemnumber":"'.$EDSRecordAN.'"';
				$recordXML .= '  <datafield tag="999" ind1="0" ind2="0">
									<subfield code="c" label="Accession Number">'.$EDSRecordAN.'</subfield>
									<subfield code="d" label="Accession Number">'.$EDSRecordAN.'</subfield>
								  </datafield>
								  ';
		}catch{};


		$recordJSON .= "}";
		$recordXML .= '</record>';
		$recordXML=~s/\&/and/g; # avoid error when converting to marc
		$dat = from_json($recordJSON); # used instead of decode_json and encode('utf-8',$recordJSON) first.

		$record = eval { MARC::Record::new_from_xml( $recordXML, "utf8", C4::Context->preference('marcflavour') ) };
		return ($record,$dat);
	}else{return ($record,$dat);}
}


}#end no warnings
