PFIAtoZBar();
function PFIAtoZBar() {
    var barHolder = '<div class="pagination-small"><ul>';
    var firstChar = "A", lastChar = "Z";
    for (var i = firstChar.charCodeAt(0) ; i <= lastChar.charCodeAt(0) ; i++) {
        var alphaChar = eval("String.fromCharCode(" + i + ")");
        alphaChar = '<li><a href="javascript:{}" class="pfialpha">' + alphaChar + '</a></li>';
        barHolder += alphaChar;
    }
    barHolder += '</ul></div>';
    jQuery('#pfi-selections-toolbar').html(barHolder);
    jQuery('.pfialpha').click(function () {
        var currentAlpha = this;
        window.location.href = "pfi-search.pl?q=Search?query-1=JN+" + jQuery(currentAlpha).text()+"*";
    });
}