
	jQuery('.table-striped').before('<div id="resultListControl"></div>');
	jQuery('body').append('<link rel="stylesheet" type="text/css" href="http://gss.ebscohost.com/alvet/Koha/recom.css">');

	jQuery.getScript('http://widgets.ebscohost.com/prod/simplekey/recom/recom.js', function (data, textStatus, jqxhr) {
		Recommender(jQuery('#translControl1').val(), 'en', 'https://gss.ebscohost.com/alvet/Koha/', 'json', 'placardb', '3', '1', '0', 'php');
	});