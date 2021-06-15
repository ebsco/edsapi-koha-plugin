
jQuery('.table-striped').before('<div id="resultListControl"></div>');
jQuery('body').append('<link rel="stylesheet" type="text/css" href="https://widgets.ebscohost.com/prod/simplekey/recom/koha/recom.css">');

jQuery.getScript('https://widgets.ebscohost.com/prod/simplekey/recom/recom.js', function (data, textStatus, jqxhr) {
	Recommender(jQuery('#translControl1').val(), 'en', 'https://widgets.ebscohost.com/prod/simplekey/recom/koha/', 'json', 'placardb', '3', '1', '0', 'php');
});