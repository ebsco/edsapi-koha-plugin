[% IF researchstarters.size %]
<script>
var researchStartersInc='';
//  <!-- Indicators -->\
//  <ol class="carousel-indicators">\
//    <li data-target="#carousel-example-generic" data-slide-to="0" class="active"></li>\
//    <li data-target="#carousel-example-generic" data-slide-to="1"></li>\
//    <li data-target="#carousel-example-generic" data-slide-to="2"></li>\
//  </ol>\

researchStartersInc +='<div id="carousel-example-generic" class="carousel slide" data-ride="carousel">\
<ol class="carousel-indicators">\
<li data-target="#carousel-example-generic" data-slide-to="0" class="active"></li>\
';
//	[% rsitemscount=1 %]
//	[% WHILE rsitemscount <  researchstarters.0.Records.size %]
		researchStartersInc +='<li data-target="#carousel-example-generic" data-slide-to="[% rsitemscount %]"></li>';
//		[% rsitemscount = rsitemscount+1 %]
//	[% END %]

researchStartersInc+='  </ol>\
<!-- Wrapper for slides -->\
<div class="carousel-inner" role="listbox">\
  ';
//		  [% rsitemdata = '' %]
//		  [% rsitemtitle = '' %]
// [% FOR researchStarter IN researchstarters.0.Records %]  

//	[% rsactive = '' %]
//	[% rsheading = 'Related' %]
//	[% IF researchStarter.ResultId==1 %]
//	[% rsactive = 'active' %]
//	[% rsheading = 'Research Starter' %]
//	[% END %]

//	[% rsImage = researchStarter.ImageInfo.0.Target %]

	researchStartersInc+='<div class="item [% rsactive %]">';
//	[% FOR rsItem IN researchStarter.Items %]

	//  [% IF rsItem.Group == 'Ab' %]
	//		  [% rsitemdata = rsItem.Data %]
	//  [% END %]
	
	//   	[% IF rsItem.Label == 'Title' %]
	//		  [% rsitemtitle = rsItem.Data %]
	//   [% END %]
	
	//   	[% IF rsItem.Group == 'Src' %]
	//		  [% rsitemsrc = rsItem.Data %]
	//   [% END %]
//	 [% END %]
//  [% IF rsitemtitle == '' %]
	//	  [% rsitemtitle = 'Login to gain access to this result.' %]
//	 [% END %]
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
	//researchStartersInc+=' <div class="carousel-caption"> </div>';
   	researchStartersInc+='</div>';
// [% END %]

  

researchStartersInc+='  </div>\
	<!-- Controls -->\
  <a class="left carousel-control" role="button" href="javascript:void(0)" onClick="$(\'.carousel\').carousel(\'prev\')" data-slide="prev">\
&lsaquo;</a>\
  <a class="right carousel-control" role="button" href="javascript:void(0)" onClick="$(\'.carousel\').carousel(\'next\')" data-slide="next">\
&rsaquo;</a>\
</div>\
<style>\
.carousel-control.left, .carousel-control.right{ \
	background-image: none !important; \
	filter: progid:none !important; \
	color:#444!important;\
}\
.slidecontainer{\
	border: 1px solid #ccc;\
	padding:15px;\
	margin-left:0px;\
}\
.carousel-indicators li{\
	border: 1px solid #999 !important;\
}\
.carousel-indicators .active{\
	background-color: #ccc !important;\
}\
.carousel-indicators{\
	bottom:inherit!important;\
	margin-top:5px;\
}\
</style>\
';

</script>


 <div class="placardtab" style="display:none;"><div><div id="research-starters" width="100%" data-heading="[% researchstarters.0.Label %]"></div></div></div>
 <script>
 
 var rsTrackJQuery = setInterval(function(){try{PlacardTabs('research-starters');clearInterval(rsTrackJQuery);
 	jQuery('#research-starters').html(researchStartersInc);
}catch (err) {}}, 10);
 
 </script>
[% END %]