[% IF ( PAGE_NUMBERS ) %]
	[% PAGE_NUMBERS.PageCounter = PAGE_NUMBERS.MinPageNo %]
    <div class="pagination pagination-small">
        <ul>
        [% IF ( PAGE_NUMBERS.PagePrevious ) %]
            <li><a href="?q=Search?[%PAGE_NUMBERS.URL%]|pagenumber=[%PAGE_NUMBERS.PagePrevious%]">&lt;&lt; Previous</a></li>
        [% END %]
        [% WHILE PAGE_NUMBERS.PageCounter <=  PAGE_NUMBERS.MaxPageNo %]
            [% IF ( PAGE_NUMBERS.PageCounter == PAGE_NUMBERS.PageNumber ) %]
                <li class="active"><a href="#">[% PAGE_NUMBERS.PageNumber %]</a></li>
            [% ELSE %]
                <li><a href="?q=Search?[%PAGE_NUMBERS.URL%]|pagenumber=[%PAGE_NUMBERS.PageCounter%]">[% PAGE_NUMBERS.PageCounter %]</a></li>
            [% END %]
			[% PAGE_NUMBERS.PageCounter = PAGE_NUMBERS.PageCounter+1  %]
        [% END %]
        [% IF ( PAGE_NUMBERS.PageNext ) %]
            <li> <a href="?q=Search?[%PAGE_NUMBERS.URL%]|pagenumber=[%PAGE_NUMBERS.PageNext%]">Next &gt;&gt;</a></li>
        [% END %]
        </ul>
    </div>
[% END %]