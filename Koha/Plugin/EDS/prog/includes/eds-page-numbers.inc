[% IF ( PAGE_NUMBERS ) %]
  <div class="pages">
  [% IF PAGE_NUMBERS.PagePrevious %]
      <a class="nav" href="?q=Search?[%PAGE_NUMBERS.URL%]|pagenumber=[%PAGE_NUMBERS.PagePrevious%]">&lt;&lt; Previous</a>
  [% END %]
  [% WHILE PAGE_NUMBERS.MinPageNo <=  PAGE_NUMBERS.MaxPageNo %]
  		[% IF PAGE_NUMBERS.MinPageNo == PAGE_NUMBERS.PageNumber %]
    	    <span class="current">[% PAGE_NUMBERS.PageNumber %]</span>
		[% ELSE %]
	        <a class="nav" href="?q=Search?[%PAGE_NUMBERS.URL%]|pagenumber=[%PAGE_NUMBERS.MinPageNo%]">[% PAGE_NUMBERS.MinPageNo %]</a>
		[% END %]
		[% PAGE_NUMBERS.MinPageNo = PAGE_NUMBERS.MinPageNo+1  %]
  [% END %]	
  [% IF PAGE_NUMBERS.PageNext %]
      <a class="nav" href="?q=Search?[%PAGE_NUMBERS.URL%]|pagenumber=[%PAGE_NUMBERS.PageNext%]">Next &gt;&gt;</a>
  [% END %]
  </div>
[% END %]