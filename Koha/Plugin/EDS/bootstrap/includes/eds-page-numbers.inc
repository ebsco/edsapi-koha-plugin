[% USE raw %]
[% IF total %]
    [% IF ( PAGE_NUMBERS ) %]
        <nav class="pagination pagination-sm noprint" aria-label="Search results pagination">
        [% PAGE_NUMBERS.PageCounter = PAGE_NUMBERS.MinPageNo %]
            <ul class="pagination">
            [% IF ( PAGE_NUMBERS.PagePrevious ) %]
                <li class="page-item"><a class="page-link" href="?q=Search?[%PAGE_NUMBERS.URL%]|pagenumber=[%PAGE_NUMBERS.PagePrevious%]"><i class="fa fa-fw fa-angle-left" aria-hidden="true"></i>[% EDSLANG.eds_page_numbers_INC_previous %]</a></li>
            [% END %]
            [% WHILE PAGE_NUMBERS.PageCounter <=  PAGE_NUMBERS.MaxPageNo %]
                [% IF ( PAGE_NUMBERS.PageCounter == PAGE_NUMBERS.PageNumber ) %]
                    <li class="active"><a class="page-link" href="#">[% PAGE_NUMBERS.PageNumber %]</a></li>
                [% ELSE %]
                    <li class="page-item"><a class="page-link" href="?q=Search?[%PAGE_NUMBERS.URL%]|pagenumber=[%PAGE_NUMBERS.PageCounter%]">[% PAGE_NUMBERS.PageCounter %]</a></li>
                [% END %]
                [% PAGE_NUMBERS.PageCounter = PAGE_NUMBERS.PageCounter+1  %]
            [% END %]
            [% IF ( PAGE_NUMBERS.PageNext ) %]
                <li class="page-item"> <a class="page-link" href="?q=Search?[%PAGE_NUMBERS.URL%]|pagenumber=[%PAGE_NUMBERS.PageNext%]">[% EDSLANG.eds_page_numbers_INC_next %] <i class="fa fa-fw fa-angle-double-right" aria-hidden="true"></i></a></li>
            [% END %]
            </ul>
        </nav>
    [% END %]
[% END %]
