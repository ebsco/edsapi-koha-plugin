[% IF researchstarters.size %]
<script>
var researchStartersInc='';

researchStartersInc +='<div id="carousel-example-generic" class="carousel slide" data-ride="carousel">\
<ol class="carousel-indicators">\
<li data-target="#carousel-example-generic" data-slide-to="0" class="active"></li>\
';

		researchStartersInc +='<li data-target="#carousel-example-generic" data-slide-to="[% rsitemscount %]"></li>';


researchStartersInc+='  </ol>\
<!-- Wrapper for slides -->\
<div class="carousel-inner" role="listbox">';


	researchStartersInc+='<div class="item [% rsactive %]">';

	researchStartersInc+=' <div class="slidecontainer row">\
		<div class="span1">\</div>\
		<div  class="span10">\
			<img style="height:130px;float:left;margin-right:10px;" src="[% rsImage %]">\
			<h4><a href="/plugin/Koha/Plugin/EDS/opac/eds-detail.pl?q=Retrieve?an=[% researchStarter.Header.An %]|dbid=[%researchStarter.Header.DbId%]&resultid=1&fulltext=html" target="_blank">[% rsheading %]: [% rsitemtitle %]</a></h4>\
			<small> [% rsitemdata %]</small> <a href="/plugin/Koha/Plugin/EDS/opac/eds-detail.pl?q=Retrieve?an=[% researchStarter.Header.An %]|dbid=[%researchStarter.Header.DbId%]&resultid=1&fulltext=html" target="_blank">[% EDSLANG.eds_researchstarters_INC_more %]</a>\
			<sub>[% rsitemsrc %]</sub>\
		</div>\
		<div class="span1">\</div>\
	</div>';
   	researchStartersInc+='</div>';
 

researchStartersInc+='  </div>\
	<!-- Controls -->\
  <a class="left carousel-control" role="button" href="javascript:void(0)" onClick="$(\'.carousel\').carousel(\'prev\')" data-slide="prev">\
&lsaquo;</a>\
  <a class="right carousel-control" role="button" href="javascript:void(0)" onClick="$(\'.carousel\').carousel(\'next\')" data-slide="next">\
&rsaquo;</a>\
</div>';

</script>


 <div class="placardtab" style="display:none;"><div><div id="research-starters" width="100%" data-heading="[% researchstarters.0.Label %]"></div></div></div>
 <script>
 
 var rsTrackJQuery = setInterval(function(){try{jQuery().jquery;clearInterval(rsTrackJQuery);
 	jQuery('#research-starters').html(researchStartersInc);
	PlacardTabs('research-starters');
}catch (err) {}}, 10);
 
 </script>
[% END %]