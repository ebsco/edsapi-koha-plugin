<div id="search-facets">
    <h4><a href="#" class="menu-collapse-toggle">Refine your search</a></h4>
    <ul class="menu-collapse">
        <li id="availability_facet">
			Current Search
			
			[% IF query %]
				<ul>
				<li>Search Term(s)</li>
				[% FOR searchQuery IN query %]
				  <li>
					<a href="[% searchQuery.RemoveAction %]"><input type="checkbox" checked onchange="window.location.href=($(this).parent().attr('href'));$(this).attr('disabled','disabled');" > [% searchQuery.Query.BooleanOperator %][% IF searchQuery.Query.FieldCode %], [% searchQuery.Query.FieldCode %][% END %] : <span id="searchTerm">[% searchQuery.Query.Term %]</span></a>
				  </li>
				[% END %]
				</ul>
			[% END %]
			
			
			[% IF filters %]
				<ul>
				<li><strong>Active Facets</strong></li>
				[% FOR facetFilter IN filters %]
				[% FOR facetFilterItem IN facetFilter.FacetValuesWithAction %]
				  <li>
					<a href="[% facetFilterItem.RemoveAction %]"><input type="checkbox" checked onchange="window.location.href=($(this).parent().attr('href'));$(this).attr('disabled','disabled');" > [% facetFilterItem.FacetValue.Id %] : [% facetFilterItem.FacetValue.Value %]</a>
				  </li>
				[% END %]
				[% END %]
				</ul>
			[% END %]
			
        </li> [% #seperate search criteria and facets %]
		
		[% IF limiters %]
		<li>

			<ul>
				<li><strong>Limit To:</strong></li>
				[% FOR EDSLimit IN limiters %]
					[% IF EDSLimit.Type =='select' %]
						  <li>
							<a href="[% EDSLimit.AddAction %]">[% EDSLimit.Label %] </a>
						  </li>
					[% END %]
				[% END %]
			</ul>
			[% FOR EDSLimit IN limiters %][% IF EDSLimit.Type =='ymrange' %]
				<ul>
					<li><strong>[% EDSLimit.Label %]</strong> <br>

							<div id="eds-dateholder" align="center">
                                <div class="input-append">
                                    <input id="published-date" name="published-date"   title="Enter a date range and press Enter or clear this textbox to remove the date limiter." type="text" onkeypress="DateHandleKeyPress(event,this)" style="text-align:center;font-size:12px;" placeholder="YYYY-MM/YYYY-MM" value="[% EDSLimit.DateValue %]" >
                                    <span id="eds-clear-date" style="cursor:pointer;"  class="add-on"  title="Clear"><i class="icon-remove"></i></span>
                                    <span  id="eds-apply-date" style="cursor:pointer;" class="add-on" title="Apply"><i class="icon-ok"></i></span>
                                </div>
                            </div>
                            
                            <input id="range-published-date" data-mindate="[% daterange.MinDate %]" data-maxdate="[% daterange.MaxDate %]" name="range-published-date" type="text" style="text-align:center;width:80%;" >
                            

						[% #action=removelimiter(DT1) %]
						<script>var dateAction = "[% EDSLimit.AddAction %]";</script>
					</li>
				</ul>
			[% END %][% END %]
			[% IF expanders %]
				<ul>
					<li><strong>Expand To:</strong></li>
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
        <li class="eds-facets">
          <span class="eds-facet-label">[% facets.Label %]</span>
          <div style="max-height:200px;overflow:auto;margin:3px;">
			  <ul>
				[% FOR FacetValues IN facets.AvailableFacetValues %]
				  <li>
                  	<input type="checkbox" name="filter[]" value="" onChange="SetFacet(this);"> 
					<a href="[% FacetValues.AddAction %]">[% FacetValues.Value %]</a> ([% FacetValues.Count %])
				  </li>
				[% END %]
			  </ul>
		  </div>
        </li>
      [% END %]
	  
	  
    </ul>
</div>

[% IF ( OPACResultsSidebar ) %]
	<div id="opacresultssidebar">
		[% OPACResultsSidebar %]
	</div>
[% END %]