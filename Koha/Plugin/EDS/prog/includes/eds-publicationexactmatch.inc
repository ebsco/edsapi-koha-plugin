[% IF publicationexactmatch.size %]
<script>
var publicationExactMatchInc='<div class="slidecontainer">';
var pubTitle="";
var pubData="";
var ftLinks="";

//	[% FOR empItems IN publicationexactmatch.0.PublicationRecords.0.Items %]

	//  [% IF empItems.Label == 'Title' %]
			pubTitle =' [% empItems.Data %]';
	//  [% ELSE %]			
			pubData+='<strong>[% empItems.Label %]</strong>: [% empItems.Data %], ';
	//  [% END %]
	
//	 [% END %]

//	[% FOR empFTHolding IN publicationexactmatch.0.PublicationRecords.0.FullTextHoldings %]
	ftLinks+='<li><a target="_blank" href="[% empFTHolding.URL %]">[% empFTHolding.Name.replace("\'","\\\'") %]</a></li>';
//	 [% END %]
//	 [% IF publicationexactmatch.0.PublicationRecords.0.FullTextHoldings.size %]
		ftLinks='<ul class="dropdown-menu" role="menu">'+ftLinks+'</ul>';
//	 [% END %]


publicationExactMatchInc+='<h4><a target="_blank" href="[% publicationexactmatch.0.PublicationRecords.0.PLink %]">'+pubTitle+'</a></h4>';

publicationExactMatchInc+='<form onsubmit="window.parent.SearchPublication(jQuery(\'#search-within-publication\').val());return false;" class="form-inline">\
	  <div class="form-group">\
		<div class="input-group">\
			<div class="input-group-btn">\
				<button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-expanded="false">Full Text Access <span class="caret"></span></button>\
				'+ftLinks+'\
			  </div>\
		  <input type="text" class="form-control" id="search-within-publication" placeholder="Search within Publication">\
		  <div class="input-group-addon glyphicon glyphicon-search" style="cursor:pointer" onclick="window.parent.SearchPublication(jQuery(\'#search-within-publication\').val());"></div>\
		</div>\
	  </div>\
	</form>';


publicationExactMatchInc+='<small>'+pubData+'</small>';

publicationExactMatchInc+='</div>\
<style>\
		.slidecontainer{\
			height:198px;\
			width:100%;\
			border: 1px solid #ccc;\
			padding:15px;\
		}\
	</style>';

function LoadPublicationExactMatch(){
	$('#publication-exactmatch').contents().find('body').html(publicationExactMatchInc);
	PlacardTabs('publication-exactmatch');
}

function SearchPublication(searchinTerm){
	window.location.href='/plugin/Koha/Plugin/EDS/opac/eds-search.pl?q=Search?query-1=AND,:{'+searchinTerm+'}|action=addfacetfilter('+encodeURIComponent('[% publicationexactmatch.0.PublicationRecords.0.Header.ResourceType %]:'+'[% publicationexactmatch.0.PublicationRecords.0.RecordInfo.BibRecord.BibEntity.Titles.0.TitleFull %]'.toLowerCase())+')&default=1';
}
</script>


 <tr class="placardtab" style="display:none;"><td colspan="5" class=""><iframe id="publication-exactmatch" data-heading="[% publicationexactmatch.0.Label %]" scrolling="no" frameborder="0" height="200" data-heading="[% publicationexactmatch.0.Label %]" width="100%" src="/plugin/Koha/Plugin/EDS/opac/eds-raw.pl" onload="LoadPublicationExactMatch()"></iframe></td></tr>
[% END %]