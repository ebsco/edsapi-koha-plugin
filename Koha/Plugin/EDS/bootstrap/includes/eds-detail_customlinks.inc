<ul id="action">
[%# FOREACH CUSTOMLINK IN DETAILED_RECORD.FullText %]

	[% IF DETAILED_RECORD.FullText.Text.Availability==1 %]			  
		<li>
			<a target="_blank" class="html-customlink customLink" href="[% DETAILED_RECORD.PLink %]">
			[% EDSLANG.eds_detail_customlinks_INC_html_fulltext %]
		</a></li>
	[% END %]
	

	[% IF DETAILED_RECORD.FullText.Links.0.Type %]			  
		<li>
		[% IF DETAILED_RECORD.FullText.Links.0.Url %]
			<a target="_blank" class="[% DETAILED_RECORD.FullText.Links.0.Type %] customLink" href="[% DETAILED_RECORD.FullText.Links.0.Url %]">
		[% ELSE %]
			<a class="[% DETAILED_RECORD.FullText.Links.0.Type %] customLink" href="javascript:LoginRequired();">
		[% END %]
		[% IF DETAILED_RECORD.FullText.Links.0.Type=='pdflink' %]
			[% EDSLANG.eds_detail_customlinks_INC_pdf_fulltext %]
		[% ELSIF DETAILED_RECORD.FullText.Links.0.Type=='ebook-pdf' %]	
			[% EDSLANG.eds_detail_customlinks_INC_ebook_fulltext %]
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
	<li><a target="_blank" class="edslink customLink" title="View in EDS" href="[% DETAILED_RECORD.PLink %]">[% EDSLANG.eds_detail_customlinks_INC_view_in_eds %]</a></li>
[% END %]

</ul>