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
#* DATE MODIFIED: 28/06/2014
#* LAST CHANGE DESCRIPTION: Added Advanced Search
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
use C4::Auth qw(:DEFAULT get_session ParseSearchHistoryCookie);
#use C4::Auth;
use C4::Koha;
use C4::Output;
use HTML::Entities;
use LWP;
use IO::File;
use JSON qw/decode_json encode_json/;
use Try::Tiny;
use POSIX qw/ceil/;

#legacy from template... may not be required.
use C4::Languages qw(getAllLanguages);
use C4::Search;
use C4::Biblio;  # GetBiblioData
use C4::Tags qw(get_tags);
use C4::Branch; # GetBranches
use C4::SocialData;
use C4::Ratings;
#use POSIX qw(ceil floor strftime);
use URI::Escape;
use Business::ISBN;
use Cwd            qw( abs_path );
use File::Basename qw( dirname );


require 'eds-methods.pl';

my $PluginDir = dirname(abs_path($0));
$PluginDir =~s /EDS\/opac/EDS/;
#leaving this in as alternate code.
#my $PluginDir = C4::Context->config("pluginsdir");
#$PluginDir = $PluginDir.'/Koha/Plugin/EDS';

my $cgi = new CGI;
#my $format = $cgi->param("format") || 'html';

my $EDSInfo =  decode_json(EDSGetInfo(0));
my $EDSConfig = decode_json(EDSGetConfiguration());

#{if($EDSConfig->{logerrors} eq 'no'){no warnings;local $^W = 0;}
{no warnings;local $^W = 0;


my $CookieExpiry = '+'.$EDSConfig->{cookieexpiry}.'m';
if($EDSConfig->{cookieexpiry} eq ' '){ # dont set expiry
	$CookieExpiry='';
}

my $EDSQuery = $cgi->param("q");
$EDSQuery =~s/\|/\&/g;

my ($template,$borrowernumber,$cookie);
my $lang = C4::Templates::getlanguage($cgi, 'opac');
# decide which template to use
my $template_name;
my $template_type = 'basic';
my @params = $cgi->param("limit");
my $search_desc = 1;
my $adv_search = 0;


my $format = $cgi->param("format") || '';
my $build_grouped_results = C4::Context->preference('OPACGroupResults');
if ($format =~ /(rss|atom|opensearchdescription)/) {
    $template_name = 'opac-opensearch.tmpl';
}
elsif (@params && $build_grouped_results) {
    $template_name = 'opac-results-grouped.tmpl';
}
elsif ((@params>=1) || ($cgi->param("q")) || ($cgi->param('multibranchlimit')) || ($cgi->param('limit-yr')) ) {
    $template_name = $PluginDir.'/modules/eds-results.tmpl';
}
else {
    $template_name = $PluginDir.'/modules/eds-advsearch.tmpl';
    $template_type = 'advsearch';
	$search_desc = 0;
	$adv_search = 1;
}
# load the template
($template, $borrowernumber, $cookie) = get_template_and_user({
    template_name => $template_name,
    query => $cgi,
    type => "opac",
	is_plugin => 1,
    authnotrequired => ( C4::Context->preference("OpacPublic") ? 1 : 0 ),
    }
);
if ($template_name eq 'opac-results.tmpl') {
   $template->param('COinSinOPACResults' => C4::Context->preference('COinSinOPACResults'));
}

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


# get biblionumbers stored in the cart
my @cart_list;

if($cgi->cookie("bib_list")){
    my $cart_list = $cgi->cookie("bib_list");
    @cart_list = split(/\//, $cart_list);
}

if ($format eq 'rss2' or $format eq 'opensearchdescription' or $format eq 'atom') {
    $template->param($format => 1);
    $template->param(timestamp => strftime("%Y-%m-%dT%H:%M:%S-00:00", gmtime)) if ($format eq 'atom'); 
    # FIXME - the timestamp is a hack - the biblio update timestamp should be used for each
    # entry, but not sure if that's worth an extra database query for each bib
}
if (C4::Context->preference("marcflavour") eq "UNIMARC" ) {
    $template->param('UNIMARC' => 1);
}
elsif (C4::Context->preference("marcflavour") eq "MARC21" ) {
    $template->param('usmarc' => 1);
}
	
$template->param( 'AllowOnShelfHolds' => C4::Context->preference('AllowOnShelfHolds') );
$template->param( 'OPACNoResultsFound' => C4::Context->preference('OPACNoResultsFound') );

$template->param(
    OpacStarRatings => C4::Context->preference("OpacStarRatings") );

#EDS config begins here
my $EDSResponse;
my @EDSResults;
my $EDSSearchQuery;
my $EDSSearchQueryWithOutPage;
my @EDSFacets;
my @EDSFacetFilters;
my @EDSQueries;
my @EDSLimiters;
my @EDSExpanders;
my $sort_by;
my %pager;
if($cgi->param("q")){
	$EDSResponse = decode_json(EDSSearch($EDSQuery,$GuestTracker));
	try{# uncomment the try block when debugging
		EDSProcessResults();
		#process query
		$EDSSearchQuery=$EDSResponse->{SearchRequestGet}->{QueryString};
		$EDSSearchQuery =~s/\&/\|/g;
		$EDSSearchQueryWithOutPage = $EDSSearchQuery;
		$EDSSearchQueryWithOutPage=~s/pagenumber\=\d+\|//; #TODO consider removing resultsperpage too.
		EDSProcessFacets();
		EDSProcessFilters();
		EDSProcessQueries();
		EDSProcessLimiters();
		EDSProcessExpanders();
		EDSProcessPages();
		} catch {
			#warn "no results";
			$template->param(
	     searchdesc     => 1,
	    total  => 0,);
		
	};
}
#use Data::Dumper; die Dumper $EDSResponse;
# Pager template params
	$template->param(
	     PAGE_NUMBERS     => \%pager,
		total            => $EDSResponse->{SearchResult}->{Statistics}->{TotalHits},
		SEARCH_RESULTS   => \@EDSResults,
		 query            => \@EDSQueries,
	    sort_by          => GetSearchParam('sort'),
		current_mode	=> GetSearchParam('searchmode'),
		current_view	=> GetSearchParam('view'),
	    sortable_indexes => $EDSInfo->{AvailableSearchCriteria}->{AvailableSorts},
		search_modes	=> $EDSInfo->{AvailableSearchCriteria}->{AvailableSearchModes},
		search_fields	=> $EDSInfo->{AvailableSearchCriteria}->{AvailableSearchFields},
		facets_loop      => \@EDSFacets,
	    filters          => \@EDSFacetFilters,
		limiters		 => \@EDSLimiters,
		advlimiters		=> $EDSInfo->{AvailableSearchCriteria}->{AvailableLimiters},
		search_string	 => $EDSSearchQueryWithOutPage,
		searchdesc		=> $search_desc,
		advsearch		=> $adv_search,
		cookieexpiry	=> $CookieExpiry,
		cataloguedbid	=> $EDSConfig->{cataloguedbid},
		catalogueanprefix=> $EDSConfig->{catalogueanprefix},
		plugin_dir		=>$PluginDir,
		instancepath	=>$EDSConfig->{instancepath},
		themelang		=>$EDSConfig->{themelangforplugin},
		expanders		=>$EDSInfo->{AvailableSearchCriteria}->{AvailableExpanders},
	);

my $casAuthentication = C4::Context->preference('casAuthentication');
$template->param(
    casAuthentication   => $casAuthentication,
);


my $returnToResults = $cgi->cookie(
                            -name => 'ReturnToResults',
                            -value => $EDSSearchQuery,
                            -expires => $CookieExpiry
                );
my $SearchQueryWithOutPage = $cgi->cookie(
                            -name => 'EDSSimpleQuery',
                            -value => $EDSSearchQueryWithOutPage,
                            -expires => $CookieExpiry
                );
my $ResultTotal = $cgi->cookie(
                            -name => 'ResultTotal',
                            -value => $EDSResponse->{SearchResult}->{Statistics}->{TotalHits},
                            -expires => $CookieExpiry
                );
my $QueryTerm = $cgi->cookie(
                            -name => 'QueryTerm',
                            -value => $EDSResponse->{SearchRequestGet}->{SearchCriteriaWithActions}->{QueriesWithAction}[0]->{Query}->{Term},
                            -expires => $CookieExpiry
                );
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
$cookie = [$cookie, $ResultTotal, $SearchQueryWithOutPage, $returnToResults, $QueryTerm, $SessionToken, $GuestMode];

my $session = get_session($cgi->cookie("CGISESSID")); 
$session->param('busc'=>'q=Search?'.$EDSSearchQuery.'&amp;listBiblios=1&amp;total='.$EDSResponse->{SearchResult}->{Statistics}->{TotalHits}); #to enable back for opac-details
				
my $content_type = ( $format eq 'rss' or $format eq 'atom' ) ? $format : 'html';
output_with_http_headers $cgi, $cookie, $template->output, $content_type;

sub GetSearchParam
{
	my $SearchParam = shift or return;
	my $ParamValue = '';
	my @QueryString = split('\|',$EDSSearchQuery);
	foreach my $QueryParam (@QueryString){
		if($QueryParam=~ m/$SearchParam/){
			$ParamValue = $QueryParam;
			$ParamValue =~s/$SearchParam\=//;
			return $ParamValue;
		}
	}
	return '';	 # if not parameter match.
}

sub EDSProcessResults
{	#process Search Results
	@EDSResults = @{$EDSResponse->{SearchResult}->{Data}->{Records}}; 
	foreach my $Result (@EDSResults){
		foreach my $Items ($Result->{Items}){
			try
			{
				my @Items = @{$Items};
				foreach my $Item (@Items){
					$Item = EDSProcessItem($Item);
					if(($Result->{Header}->{DbId} eq $EDSConfig->{cataloguedbid}) && ($Item->{Name} eq 'Title')){ 
						my $CatalogueRecordId=$Result->{Header}->{An};
						$CatalogueRecordId=~s/\w+\.//;
						$Item->{CatData} = GetCatalogueAvailability($CatalogueRecordId);
						$Item->{CatData} =~s/pl\?biblionumber\=/pl\?resultid\=$Result->{ResultId}\&biblionumber\=/;
						$Item->{CatData} =~s/(<a[^<]+?>)(.*?)(<\/a>)/$1$Item->{Data}$3/; # replace title for highlights
					}
				}
			}
			catch
			{}

		}
	}	
}

sub GetCatalogueAvailability
{
	my $DBId = shift or return;
	# search Koha
	my ($error, $results_hashref, $facets, $expanded_facet, $scan);
	my $query = 'biblionumber='.$DBId;
	my @sort_by='relevance_asc';
	my @servers='biblioserver';
	my $branches = GetBranches();
	my $itemtypes = GetItemTypes;
	eval {($error, $results_hashref, $facets) = getRecords($query,$query,\@sort_by,\@servers,'100',0,$expanded_facet,$branches,$itemtypes,'ccl',$scan,1);};
	my $hits = $results_hashref->{$servers[0]}->{"hits"};
	my @CatalogueResults = searchResults('opac', $query, $hits, '100', 0, $scan, $results_hashref->{$servers[0]}->{"RECORDS"});
	return $CatalogueResults[0]->{"XSLTResultsRecord"};
}




sub EDSProcessFacets
{	#process Facets
	@EDSFacets = @{$EDSResponse->{SearchResult}->{AvailableFacets}};
	foreach my $facet (@EDSFacets){
		foreach my $facetValues ($facet->{AvailableFacetValues}){
			my @facetValues = @{$facetValues};
			foreach my $facetValue (@facetValues){
				$facetValue->{AddAction} = 'eds-search.pl?q=Search?'.$EDSSearchQueryWithOutPage.'|action='.$facetValue->{AddAction};
			}
		}
	}
}

sub EDSProcessFilters
{
	try {	
		#process FacetsFilters
		@EDSFacetFilters = @{$EDSResponse->{SearchRequestGet}->{SearchCriteriaWithActions}->{FacetFiltersWithAction}};
	
		foreach my $facetFilter (@EDSFacetFilters){
			foreach my $facetFilterValues ($facetFilter->{FacetValuesWithAction}){
				my @facetFilterValues = @{$facetFilterValues};
				foreach my $facetFilterValue (@facetFilterValues){
					$facetFilterValue->{RemoveAction} = 'eds-search.pl?q=Search?'.$EDSSearchQueryWithOutPage.'|action='.$facetFilterValue->{RemoveAction};
				}
			}
		}
	} catch {
			#warn "no facet filters";
	};
}

sub EDSProcessQueries
{
	try {	
		#process Queries
		@EDSQueries = @{$EDSResponse->{SearchRequestGet}->{SearchCriteriaWithActions}->{QueriesWithAction}};
	
		foreach my $EDSQuery (@EDSQueries){
			foreach my $EDSQueryAction ($EDSQuery){
				$EDSQueryAction->{RemoveAction} = 'eds-search.pl?q=Search?'.$EDSSearchQueryWithOutPage.'|action='.$EDSQueryAction->{RemoveAction};
			}
		}
	} catch {
			#warn "no queries";
	};
}

sub EDSProcessLimiters #e.g. AiLC, Cat only etc.
{
	@EDSLimiters = @{$EDSInfo->{AvailableSearchCriteria}->{AvailableLimiters}};
	#use Data::Dumper; die Dumper @EDSLimiters;
	foreach my $Limiter (@EDSLimiters)
	{
		if($Limiter->{Type} eq 'select')
		{
			#if($Limiter->{DefaultOn} eq 'n')
			{
				#warn "no limiters";
				$Limiter->{Label} = '<input type="checkbox" readonly onchange="window.location.href=($(this).parent().attr(\'href\'));$(this).attr(\'disabled\',\'disabled\');"> '.$Limiter->{Label};		
				$Limiter->{AddAction} =~s/value/y/;
				$Limiter->{AddAction} = 'eds-search.pl?q=Search?'.$EDSSearchQueryWithOutPage.'|action='.$Limiter->{AddAction};

				try{
					my @EDSRemoveLimiters = @{$EDSResponse->{SearchRequestGet}->{SearchCriteriaWithActions}->{LimitersWithAction}};					
					foreach my $EDSRemoveLimiter (@EDSRemoveLimiters)
					{
						if($EDSRemoveLimiter->{Id} eq $Limiter->{Id}){
							$Limiter->{AddAction} =~s/y/n/;
							$Limiter->{AddAction} = 'eds-search.pl?q=Search?'.$EDSSearchQueryWithOutPage.'|action='.$EDSRemoveLimiter->{RemoveAction};
							$Limiter->{Label} =~s/readonly/readonly checked/;
						}
					}
				} catch {
					#warn 'no limiters';
				};
			}
		}
		
		if($Limiter->{Type} eq 'ymrange'){
			$Limiter->{AddAction} = 'eds-search.pl?q=Search?'.$EDSSearchQueryWithOutPage.'|action='.$Limiter->{AddAction};
					try{
					my @EDSRemoveLimiters = @{$EDSResponse->{SearchRequestGet}->{SearchCriteriaWithActions}->{LimitersWithAction}};				
						foreach my $EDSRemoveLimiter (@EDSRemoveLimiters)
						{	
							if($EDSRemoveLimiter->{Id} eq $Limiter->{Id}){
								$Limiter->{DateValue} = $EDSRemoveLimiter->{LimiterValuesWithAction}[0]->{Value};
							}
						}
					} catch {
						#warn 'no limiters';
					};
		}
	}	
}

sub EDSProcessExpanders #e.g. thesaurus, fulltext.
{
	@EDSExpanders = @{$EDSInfo->{AvailableSearchCriteria}->{AvailableExpanders}};
	foreach my $Expander (@EDSExpanders)
	{
		#warn "no limiters";
		$Expander->{Label} = '<input type="checkbox" readonly onchange="window.location.href=($(this).parent().attr(\'href\'));$(this).attr(\'disabled\',\'disabled\');" > '.$Expander->{Label};		
		#$Expander->{AddAction} =~s/value/y/;
		$Expander->{AddAction} = 'eds-search.pl?q=Search?'.$EDSSearchQueryWithOutPage.'|action='.$Expander->{AddAction};

			try{
			my @EDSRemoveExpanders = @{$EDSResponse->{SearchRequestGet}->{SearchCriteriaWithActions}->{ExpandersWithAction}};					
				foreach my $EDSRemoveExpander (@EDSRemoveExpanders)
				{
					if($EDSRemoveExpander->{Id} eq $Expander->{Id}){
						#$Expander->{AddAction} =~s/y/n/;
						$Expander->{AddAction} = 'eds-search.pl?q=Search?'.$EDSSearchQueryWithOutPage.'|action='.$EDSRemoveExpander->{RemoveAction};
						$Expander->{Label} =~s/readonly/readonly checked/;
					}
				}
			} catch {
				#warn 'no limiters';
			};
	}	
}



sub EDSProcessPages
{
	%pager = (
			'URL' => $EDSSearchQueryWithOutPage,
			'PageNumber' => 1,
			'ResultsPerPage' => 20,
			'TotalResults' => 1,
			'PageNumber' => 1,
			'ResultsPerPage' => 1,
		);
	$pager{'URL'}=$EDSSearchQueryWithOutPage;
	$pager{'TotalResults'} = $EDSResponse->{SearchResult}->{Statistics}->{TotalHits};
	
	
	
	my @PageFinder = split('\|',$EDSSearchQuery);
	foreach my $PageVal (@PageFinder){
		if($PageVal=~ m/pagenumber/){
			$pager{'PageNumber'} = $PageVal;
			$pager{'PageNumber'} =~s/pagenumber\=//;
		}
		if($PageVal=~ m/resultsperpage/){
			$pager{'ResultsPerPage'} = $PageVal;
			$pager{'ResultsPerPage'} =~s/resultsperpage\=//;
		}
	}
	$pager{'NoOfPages'} = ceil(int($pager{'TotalResults'})/int($pager{'ResultsPerPage'}));
	$pager{'NoOfPages'} = ($pager{'NoOfPages'}>$EDSInfo->{ApiSettings}->{MaxRecordJumpAhead})? ceil(int($EDSInfo->{ApiSettings}->{MaxRecordJumpAhead})/int($pager{'ResultsPerPage'})) : $pager{'NoOfPages'};
	$pager{'PagePrevious'}= $pager{'PageNumber'}-1;
	$pager{'PageNext'}= ($pager{'PageNumber'}<$pager{'NoOfPages'})? $pager{'PageNumber'}+1 : 0;
	
	$pager{'MaxPageNo'}=$pager{'PageNumber'}+1;
	while((int($pager{'MaxPageNo'}) % 10) != 0){
		$pager{'MaxPageNo'}++;
	}
	$pager{'MaxPageNo'} = ($pager{'MaxPageNo'}>$pager{'NoOfPages'})?$pager{'NoOfPages'} : $pager{'MaxPageNo'}++;
	$pager{'MinPageNo'}= $pager{'MaxPageNo'}-9;
	$pager{'MinPageNo'}=($pager{'MinPageNo'}<1)?1:$pager{'MinPageNo'};
}

}#end no warnings