[% IF facets_loop %]
  <div id="search-facets">
    <h4>Refine your search</h4>
    <ul>
        <li>
			Current Search
			
			[% IF query %]
				<ul class="facets_list">
				<li>Search Term(s)</li>
				[% FOR searchQuery IN query %]
				  <li>
					<a href="[% searchQuery.RemoveAction %]"><input type="checkbox" readonly checked onchange="window.location.href=($(this).parent().attr('href'));$(this).attr('disabled','disabled');" > [% searchQuery.Query.BooleanOperator %][% IF searchQuery.Query.FieldCode %], [% searchQuery.Query.FieldCode %][% END %] : <span id="searchTerm">[% searchQuery.Query.Term %]</span></a>
				  </li>
				[% END %]
				</ul>
			[% END %]
			
			
			[% IF filters %]
				<ul class="facets_list">
				<li>Limiters</li>
				[% FOR facetFilter IN filters %]
				  <li>
					<a href="[% facetFilter.FacetValuesWithAction.0.RemoveAction %]"><input type="checkbox" readonly checked onchange="window.location.href=($(this).parent().attr('href'));$(this).attr('disabled','disabled');" > [% facetFilter.FacetValuesWithAction.0.FacetValue.Id %] : [% facetFilter.FacetValuesWithAction.0.FacetValue.Value %]</a>
				  </li>
				[% END %]
				</ul>
			[% END %]
			
        </li> [% #seperate search criteria and facets %]
		
		[% IF limiters %]
		<li>
		[% IF limiters and expanders %]
		Limiters & Expanders
		[% ELSE %]
			[%IF limiters %]
				Limiters
			[% ELSE %]
				Expanders
			[% END %]
		[% END %]
			<ul class="facets_list">
				<li>Limit To:</li>
				[% FOR EDSLimit IN limiters %]
					[% IF EDSLimit.Type =='select' %]
						  <li>
							<a href="[% EDSLimit.AddAction %]">[% EDSLimit.Label %] </a>
						  </li>
					[% END %]
				[% END %]
			</ul>
			[% FOR EDSLimit IN limiters %][% IF EDSLimit.Type =='ymrange' %]
				<ul class="facets_list">
					<li>[% EDSLimit.Label %] 
						[% IF EDSLimit.DateValue %]
							<input title="Enter a date range and press Enter or clear this textbox to remove the date limiter." type="text" onkeypress="DateHandleKeyPress(event,this)" style="width:99%;text-align:center;" placeholder="YYYY-MM/YYYY-MM" value="[% EDSLimit.DateValue %]" >
						[% ELSE %]
							<input title="Enter a date range and press Enter or clear this textbox to remove the date limiter." type="text" onkeypress="DateHandleKeyPress(event,this)" style="width:99%;text-align:center;" placeholder="YYYY-MM/YYYY-MM" >
						[% END %]
						[% #action=removelimiter(DT1) %]
						<script>
						function DateHandleKeyPress(e,searchBox){
							var key=e.keyCode || e.which;
							if (key==13){
								var dateAction = "[% EDSLimit.AddAction %]";
								if(searchBox.value==""){
									dateAction= dateAction.replace('action=addlimiter(DT1:value)','action=removelimiter(DT1)');
									window.location.href=dateAction;
								}else{
									var regex = /^\d{4}-(0[1-9]|1[012])\/\d{4}-(0[1-9]|1[012])$/; 
									// '/\d{4}-\d[1-12]\/\d{4}-\d[1-12]/; - old'
									if(regex.test(searchBox.value)){
										dateAction= dateAction.replace('DT1:value','DT1:'+searchBox.value);
										window.location.href=dateAction;
									}else{alert('Invalid date. Please enter a date value in YYYY-MM/YYYY-MM format.\n e.g. 1900-01/2000-12.\n Remove all characters and hit enter to remove the date limiter.');}

								}
							}
						}
						</script>
					</li>
				</ul>
			[% END %][% END %]
			[% IF expanders %]
				<ul class="facets_list">
					<li>Expand To:</li>
					[% FOR expander IN expanders %]
					  <li>
						<a href="[% expander.AddAction %]">[% expander.Label %] </a>
					  </li>
					[% END %]
				</ul>
			[% END %]
			
        </li> [% #seperate limit and search criteria %]
		[% END %]
		
      [% FOR facets IN facets_loop %]
        <li>
          [% facets.Label %]
          <div style="max-height:200px;overflow:auto;margin:3px;">
			  <ul class="facets_list">
				[% FOR FacetValues IN facets.AvailableFacetValues %]
				  <li>
					<a href="[% FacetValues.AddAction %]">[% FacetValues.Value %]</a> ([% FacetValues.Count %])
				  </li>
				[% END %]
			  </ul>
		  </div>
        </li>
      [% END %]
	  
	  
    </ul>
</div>
[% END %]