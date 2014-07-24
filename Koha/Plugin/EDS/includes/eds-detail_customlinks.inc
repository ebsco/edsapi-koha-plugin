<ul id="action">
[%# FOREACH CUSTOMLINK IN DETAILED_RECORD.FullText %]

	[% IF DETAILED_RECORD.FullText.Text.Availability==1 %]			  
		<li>
			<a target="_blank" class="html-customlink customLink" href="[% DETAILED_RECORD.PLink %]">
			HTML Full Text
		</a></li>
	[% END %]
	

	[% IF DETAILED_RECORD.FullText.Links.0.Type %]			  
		<li>
		[% IF DETAILED_RECORD.FullText.Links.0.Url %]
			<a target="_blank" class="[% DETAILED_RECORD.FullText.Links.0.Type %] customLink" href="[% DETAILED_RECORD.FullText.Links.0.Url %]">
		[% ELSE %]
			<a class="[% DETAILED_RECORD.FullText.Links.0.Type %] customLink" href="javascript:alert('Login to gain access to this result.');$('.FullTextLoader').css('display','none');return false;">
		[% END %]
		[% IF DETAILED_RECORD.FullText.Links.0.Type=='pdflink' %]
			PDF Full Text
		[% ELSIF DETAILED_RECORD.FullText.Links.0.Type=='ebook-pdf' %]	
			eBook Full Text
		[% ELSE %]	
			[% DETAILED_RECORD.FullText.Links.0.Type %]
		[% END %]
		</a></li>
	[% END %]
[%# END %]
[% FOREACH CUSTOMLINK IN DETAILED_RECORD.FullText.CustomLinks %]
	[% IF CUSTOMLINK.Text %]		  
		<li><a target="_blank" class="customLink" title="[% CUSTOMLINK.MouseOverText %]" href="[% CUSTOMLINK.Url %]">[% CUSTOMLINK.Text %]</a></li>
	[% END %]
[% END %]
[% FOREACH CUSTOMLINK IN DETAILED_RECORD.CustomLinks %]
	[% IF CUSTOMLINK.Text %]		  
		<li><a target="_blank" class="customLink" title="[% CUSTOMLINK.MouseOverText %]" href="[% CUSTOMLINK.Url %]">[% CUSTOMLINK.Text %]</a></li>
	[% END %]
[% END %]
[% IF DETAILED_RECORD.PLink %]		  
	<li><a target="_blank" class="customLink" title="View in EDS" href="[% DETAILED_RECORD.PLink %]">View in EDS</a></li>
[% END %]

</ul>