[% IF publicationexactmatch.size %]
<script>
var publicationExactMatchInc='<div class="empcontainer">';
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


publicationExactMatchInc+='<h3><a target="_blank" href="[% publicationexactmatch.0.PublicationRecords.0.PLink %]">'+pubTitle+'</a></h3>';

publicationExactMatchInc+='<form onsubmit="window.parent.SearchPublication(jQuery(\'#search-within-publication\').val());return false;" class="form-search">\
		<div class="input-prepend input-append">\
			<div class="btn-group">\
				<button class="btn dropdown-toggle" data-toggle="dropdown">Full Text Access <span class="caret"></span></button>\
				'+ftLinks+'\
			  </div>\
		  <input type="text" class="input-xlarge" id="search-within-publication" placeholder="Search within Publication">\
		  <span class="add-on" style="cursor:pointer" onclick="window.parent.SearchPublication(jQuery(\'#search-within-publication\').val());"><i class="icon-search"></i></span>\
		</div>\
	</form>';


publicationExactMatchInc+='<p><small>'+pubData+'</small></p>';

publicationExactMatchInc+='</div>';

function SearchPublication(searchinTerm){
	window.location.href='/plugin/Koha/Plugin/EDS/opac/eds-search.pl?q=Search?query-1=AND,:{'+searchinTerm+'}|action=addfacetfilter('+encodeURIComponent('[% publicationexactmatch.0.PublicationRecords.0.Header.ResourceType %]:'+'[% publicationexactmatch.0.PublicationRecords.0.RecordInfo.BibRecord.BibEntity.Titles.0.TitleFull %]'.toLowerCase())+')&default=1';
}
</script>


 <div class="placardtab" style="display:none;"><div><div id="publication-exactmatch" data-heading="[% publicationexactmatch.0.Label %]" data-heading="[% publicationexactmatch.0.Label %]" width="100%"></div></div></div>
  <script>
 
 var empTrackJQuery = setInterval(function(){try{jQuery().jquery;clearInterval(empTrackJQuery);
	jQuery('#publication-exactmatch').html(publicationExactMatchInc);
	PlacardTabs('publication-exactmatch');
}catch (err) {}}, 10);
 
 </script>
[% END %]