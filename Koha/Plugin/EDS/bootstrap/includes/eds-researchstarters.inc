[% IF researchstarters.size %]
	[% rsitemdata = '' %]
	[% rsitemtitle = '' %]
	[% researchStarter = researchstarters.0.Records.0 %] 
	[% rsactive = '' %]
	[% rsheading = 'Related' %]
	[% IF researchStarter.ResultId==1 %]
		[% rsactive = 'active' %]
		[% rsheading = 'Research Starter' %] 
	[% END %]
	[% rsImage = researchStarter.ImageInfo.0.Target %]
	[% FOR rsItem IN researchStarter.Items %]

		[% IF rsItem.Group == 'Ab' %]
			[% rsitemdata = rsItem.Data %]
		[% END %]
		
		[% IF rsItem.Label == 'Title' %]
			[% rsitemtitle = rsItem.Data %]
		[% END %]
		
		[% IF rsItem.Group == 'Src' %]
			[% rsitemsrc = rsItem.Data %]
		[% END %]
	[% END %]

	[% IF rsitemtitle == '' %]
		[% rsitemtitle = 'Login to gain access to this result.' %]
	[% END %]

	<script>
	var researchStartersInc='';
	researchStartersInc+='<div class="item empcontainer" style="min-height:175px">\
			<div class="span1">\</div>\
			<div  class="span10">\
				<img style="height:130px;float:left;margin-right:10px;" src="[% rsImage %]">\
				<h4><a href="/plugin/Koha/Plugin/EDS/opac/eds-detail.pl?q=Retrieve?an=[% researchStarter.Header.An %]|dbid=[%researchStarter.Header.DbId%]&resultid=1&fulltext=html" target="_blank">[% rsheading %]: [% rsitemtitle %]</a></h4>\
				<small> [% rsitemdata %]</small> <a href="/plugin/Koha/Plugin/EDS/opac/eds-detail.pl?q=Retrieve?an=[% researchStarter.Header.An %]|dbid=[%researchStarter.Header.DbId%]&resultid=1&fulltext=html" target="_blank">[% EDSLANG.eds_researchstarters_INC_more %]</a>\
				<sub>[% rsitemsrc %]</sub>\
			</div>\
			<div class="span1">\</div>\
		</div>';
	

	</script>


	<div class="placardtab" style="display:none;"><div><div id="research-starters" width="100%" data-heading="[% researchstarters.0.Label %]"></div></div></div>
	<script>
	
	var rsTrackJQuery = setInterval(function(){try{PlacardTabs('research-starters');clearInterval(rsTrackJQuery);
		jQuery('#research-starters').html(researchStartersInc);
	}catch (err) {}}, 10);
	
	</script>
[% END %]