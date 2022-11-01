[% IF PAGE_NUMBERS %]
[% EDSLANG.eds_resort_form_INC_results_per_page %]<select id="resultsperpage" name="resultsperpage" onChange="getSelectedText('#resultsperpage')">
	[% IF PAGE_NUMBERS.ResultsPerPage == '5' %]
		<option name="perpage5" selected="selected" value="SetResultsPerPage(5)">5</option>
	[% ELSE %]
		<option name="perpage5" value="SetResultsPerPage(5)">5</option>
	[% END %]
	[% IF PAGE_NUMBERS.ResultsPerPage == '10' %]
		<option name="perpage10" selected="selected" value="SetResultsPerPage(10)">10</option>
	[% ELSE %]
		<option name="perpage10" value="SetResultsPerPage(10)">10</option>
	[% END %]
	[% IF PAGE_NUMBERS.ResultsPerPage == '20' %]
		<option name="perpage20" selected="selected" value="SetResultsPerPage(20)">20</option>
	[% ELSE %]
		<option name="perpage20" value="SetResultsPerPage(20)">20</option>
	[% END %]
	[% IF PAGE_NUMBERS.ResultsPerPage == '30' %]
		<option name="perpage30" selected="selected" value="SetResultsPerPage(30)">30</option>
	[% ELSE %]
		<option name="perpage30" value="SetResultsPerPage(30)">30</option>
	[% END %]
	[% IF PAGE_NUMBERS.ResultsPerPage == '40' %]
		<option name="perpage40" selected="selected" value="SetResultsPerPage(40)">40</option>
	[% ELSE %]
		<option name="perpage40" value="SetResultsPerPage(40)">40</option>
	[% END %]
	[% IF PAGE_NUMBERS.ResultsPerPage == '50' %]
		<option name="perpage50" selected="selected" value="SetResultsPerPage(50)">50</option>
	[% ELSE %]
		<option name="perpage50" value="SetResultsPerPage(50)">50</option>
	[% END %]

</select>
[% END %]


[% IF current_view %]
[% EDSLANG.eds_resort_form_INC_view %]<select id="searchview" name="searchview" onChange="getSelectedText('#searchview')">
	[% IF current_view == 'title' %]
		<option name="title" selected="selected" value="setView(title)">[% EDSLANG.eds_resort_form_INC_view_title %]</option>
	[% ELSE %]
		<option name="title" value="setView(title)">[% EDSLANG.eds_resort_form_INC_view_title %]</option>
	[% END %]
	[% IF current_view == 'brief' %]
		<option name="brief" selected="selected" value="setView(brief)">[% EDSLANG.eds_resort_form_INC_view_brief %]</option>
	[% ELSE %]
		<option name="brief" value="setView(brief)">[% EDSLANG.eds_resort_form_INC_view_brief %]</option>
	[% END %]
	[% IF current_view == 'detailed' %]
		<option name="detailed" selected="selected" value="setView(detailed)">[% EDSLANG.eds_resort_form_INC_view_detail %]</option>
	[% ELSE %]
		<option name="detailed" value="setView(detailed)">[% EDSLANG.eds_resort_form_INC_view_detail %]</option>
	[% END %]
</select>
[% END %]



[% IF search_modes %]
    [% EDSLANG.eds_resort_form_INC_search_mode %]<select id="searchmode" name="searchmode" onChange="getSelectedText('#searchmode')">
        [% FOREACH mode IN search_modes %]

		[%  searchModePrefix = 'eds_resort_form_' 
            modeId = mode.Mode
            searchModeMetaKey = searchModePrefix _ modeId
            searchModeLabelText = EDSLANG.$searchModeMetaKey
        %]
        [% IF searchModeLabelText.empty %]
        	[% searchModeLabelText = mode.Label %]
        [% END %]

            [% IF current_mode == mode.Mode %]
                <option name="[% mode.Mode %]" selected="selected" value="[% mode.AddAction %]">[% searchModeLabelText %]</option>
            [% ELSE %]
                <option name="[% mode.Mode %]" value="[% mode.AddAction %]">[% searchModeLabelText %]</option>
            [% END %]
        [% END %]
    </select>
[% END %]


[% IF sortable_indexes %]
<script>
	function getSelectedText(featureID){
		window.location.href="?q=Search?[% search_string %]|action="+$(featureID+" option:selected").attr('value');
	}
</script>
[% EDSLANG.eds_resort_form_INC_sort_by %]<select id="sortby" name="sortby" onChange="getSelectedText('#sortby')">
	[% FOREACH ind IN sortable_indexes.sort %]

		[%  sortByPrefix = 'eds_resort_form_' 
            sortId = ind.Id
            sortByMetaKey = sortByPrefix _ sortId
            sortByLabelText = EDSLANG.$sortByMetaKey
        %]
        [% IF sortByLabelText.empty %]
        	[% sortByLabelText = ind.Label %]
        [% END %]

		[% IF sort_by == ind.Id %]
			<option name="[% ind.Id %]" selected="selected" value="[% ind.AddAction %]">[% sortByLabelText %]</option>
		[% ELSE %]
			<option name="[% ind.Id %]" value="[% ind.AddAction %]">[% sortByLabelText %]</option>
		[% END %]
	[% END %]
</select>
[% END %]