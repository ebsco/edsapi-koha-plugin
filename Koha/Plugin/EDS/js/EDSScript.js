var knownItem = '';
var activeState = 0;
var edsOptions = "";
var kohaOptions = "";
var firstTimeSearchOptions = "";
var edsSelectedKnownItem = "";
//var defaultSearch=""; set by configure
var browseNextPage = "";
var catalogueId = "";
var nocorrect = "";

//-configurable in plugin config
var edsSwitchText = '';
var kohaSwitchText = '';
var edsSelectText = '';
var edsSelectInfo = '';
var kohaSelectInfo = '';

var defaultParams = '';
var multiFacet = {};
var activeFacets = 0;
//-basket stuff
var edsConfig = "";
var EDSItems = 0;
var verbose = QueryString('verbose');
var bibListLocal = 0;

// Adv search settings
var searchBlockCount = 3;

// DO NOT TOUCH - controlled by build.py
var versionEDSKoha = "20.05003";
///////////////////////////////////////

if (document.title == "") {
	document.title = "Koha - EDS Plugin";
}

// jStorage replacement
var eds_sessionStorage = {
	set: function (key, val) {
		if (typeof val == "object") {
			val = JSON.stringify(val);
		}
		sessionStorage.setItem("edsPlugin_" + key, val);
	},
	get: function (key) {
		var retData = sessionStorage.getItem("edsPlugin_" + key);
		try {
			retData = JSON.parse(retData);
		} catch (error) { }
		return retData;
	},
	remove: function (key) {
		sessionStorage.removeItem(key);
	},
	flush: function () {
		for (var key in sessionStorage) {
			if (key.indexOf("edsPlugin_") != -1) eds_sessionStorage.remove(key);
		}
	},
	debug: function () {
		for (var key in sessionStorage) {
			if (key.indexOf("edsPlugin_") != -1) console.log(key + ": " + eds_sessionStorage.get(key));
		}
	}
}

jQuery.ajax({ url: "/plugin/Koha/Plugin/EDS/js/custom/custom.js", dataType: "script", cache: true });

if ((document.location.pathname.indexOf("eds-detail.pl")) > -1 && ($.cookie("guest") == 'n')) {
	$("#ulactioncontainer ul:contains(cart)").append('\
	<li>\
		<a class="print-large" href="#" onclick="ris_download();">\
			Download Citation\
		</a>\
	</li>\
	');
	function ris_download() {

		var details = {};
		$(document.location.search.split(/[&\?|]/)).each(function () {
			if (this != "") {
				var a = this.split("=");
				details[a[0]] = a[1];
			}
		});

		$.get("/plugin/Koha/Plugin/EDS/opac/eds-cite.pl?an=" + details.an + "&dbid=" + details.dbid).done(function (data) {

			var text = JSON.parse(data).Data;
			var element = document.createElement('a');
			var filename = $(".title")[0].innerText + ".ris";
			element.setAttribute('href', 'data:text/plain;charset=utf-8,' + encodeURIComponent(text));
			element.setAttribute('download', filename);
			element.style.display = 'none';
			document.body.appendChild(element);
			element.click();
			document.body.removeChild(element);
		});
	}

	window.ris_download = ris_download;
}

delCookie = function (name) {
	var exp = new Date();
	exp.setTime(exp.getTime() - 1);
	if (parent.opener) {
		parent.opener.document.cookie = name + "=null; path=/; expires=" + exp.toGMTString();
	} else {
		document.cookie = name + "=null; path=/; expires=" + exp.toGMTString();
	}
}

if (QueryString('debug') != "1") { $(window).error(function (e) { e.preventDefault(); }); }
else { console.log('JS debug enabled') }// keep executing if there is an error.}

/////  Language data setup  /////
function getLanguage(code, callback) {
	// Use cache 
	var sessionLang = eds_sessionStorage.get('lang_' + code);
	if (sessionLang) {
		callback(sessionLang);
		return;
		// If custom language, and there's no language file for it
	} else if (code != 'default' && eds_sessionStorage.get('nolang_' + code)) {
		getLanguage('default', callback);
		return;
	}

	// Fetch the language file
	jQuery.ajax({ url: "/plugin/Koha/Plugin/EDS/bootstrap/includes/lang/" + code + ".inc", dataType: "script", cache: true })
		.done(function (data) {

			// Parse language file
			var langData = {};
			var lineData = data.split("var EDSLANG =")[1].split("\n");
			for (line in lineData) {
				if (lineData[line].indexOf(":") != -1) {
					var parts = lineData[line].split(":");
					var key = parts[0].replace(/\s/g, "");
					var val = parts[1].replace(/',|",|'|"/g, "").trim();
					langData[key] = val;
				}
			}

			eds_sessionStorage.set('lang_' + code, langData);
			callback(langData);

			// No language file, try default
		}).fail(function () {
			if (code == 'default') {
				callback(null);
			} else {
				console.error("No " + code + " language file, trying default");
				eds_sessionStorage.set('nolang_' + code, true);
				getLanguage('default', callback);
			}
		});
}

var plugin_lang = document.querySelector('html').lang;
getLanguage(plugin_lang, StartEDS);

/////////////////////////////

function eds_img_resize(e) {
	if (e.height > e.width) {
		$(e).addClass("sc_height");
	} else {
		$(e).addClass("sc_width");
	}
}

$('body').on('click', '.search-in-pub-button', function () {
	currentPubButton = this;
	searchTerm = jQuery(currentPubButton).parent().find('.search-in-pub-field').val();
	pubAction = jQuery(currentPubButton).parent().find('.search-in-pub-field').data('action');
	SearchPublication(searchTerm, pubAction);
});

$('body').on('click', '.diag-img', function (e) {
	e.preventDefault();
	$("body").addClass("eds_noscroll");
	$("body").append('\
	<div class="c_modal" onclick="javascript: $(\'body\').removeClass(\'eds_noscroll\'); $(\'.c_modal\').remove();">\
		<span class="close" onclick="javascript: $(\'body\').removeClass(\'eds_noscroll\'); $(\'.c_modal\').remove();">&times;</span>\
		<img class="c_modal-content" src="' + e.target.parentNode.href + '" onload="eds_img_resize(this)"  >\
	</div>');
});

$.each($.cookie('bib_list').split("/"), function () {
	if (this != "") {
		var code = this.split("__")[0];
		$(".cart" + code).html(MSG_ITEM_IN_CART).addClass("incart");
		$(".cartR" + code).show();
	}
});

function StartEDS(edsLang) {
	//console.log("Running startEDS...");
	if (!edsLang) {
		console.error("No language files found, the plugin is broken");
		return;
	}

	window.edsLang = edsLang;

	//-configurable in plugin config
	edsSwitchText = edsLang.eds_switch_text;
	kohaSwitchText = edsLang.koha_switch_text;
	edsSelectText = edsLang.eds_select_text;
	kohaSelectText = edsLang.koha_select_text;
	edsSelectInfo = edsLang.eds_select_info;
	kohaSelectInfo = edsLang.koha_select_info;


	jQuery(window).resize(function () { try { ApplyPlaceAdjustments(); } catch (err) { ApplyPlaceAdjustments(); } });
	ApplyPlaceAdjustments();


	PublisherDateSlider();


	if ($.cookie("guest") == 'y') {
		jQuery('.results_summary.actions.links a, #opac-detail a.pdflink').each(function () {
			jQuery(this).attr('href', 'javascript:LoginRequired()');
			jQuery(this).attr('target', '_self');
		});

	}

	//Commenting out caching in favor of immediate updating of settings
	//var sessionConfig = eds_sessionStorage.get("edsConfig");
	//if (sessionConfig) {
	//	ConfigData(sessionConfig);
	//} else {
	// ConfigDefaultData();
	$.getJSON('/plugin/Koha/Plugin/EDS/opac/eds-raw.pl' + '?' + 'q=config', function (data) { ConfigData(data); });
	//}

	//$("#masthead_search").attr("disabled","disabled");
	if (typeof $('.back_results a').attr('href') != 'undefined') { EDSSetDetailPageNavigator(); }

	InitCartWithEDS(); // cart management

	jQuery('#eds-autosuggest').click(function () {
		nocorrect = "&nocorrect=1";
		var autoSuggestText = jQuery(this).text();
		jQuery('#translControl1').val(autoSuggestText);
		jQuery('#searchsubmit').trigger('click');
	});

	jQuery('#eds-edsautocorrect').click(function () {
		var autoSuggestText = jQuery(this).text();
		jQuery('#translControl1').val(autoSuggestText);
		jQuery('#searchsubmit').trigger('click');
	});

	if (edsConfig.autocomplete == "yes") {
		EDSAutoComp();
	}

}

function PFIAtoZBar() {
	var barHolder = '<div class="pagination-small"><ul><li><stong>' + edsLang.pfi_atoz_bar + '</strong> </li>';
	var firstChar = "A", lastChar = "Z";
	for (var i = firstChar.charCodeAt(0); i <= lastChar.charCodeAt(0); i++) {
		var alphaChar = eval("String.fromCharCode(" + i + ")");
		alphaChar = '<li><a href="javascript:{}" class="pfialpha">' + alphaChar + '</a></li>';
		barHolder += alphaChar;
	}
	barHolder += '</ul></div>';
	jQuery('#pfi-selections-toolbar').html(barHolder);
	jQuery('.pfialpha').click(function () {
		var currentAlpha = this;
		window.location.href = "pfi-search.pl?q=Search?query-1=AND,:{JN+" + jQuery(currentAlpha).text() + "*}|sort=title";
	});
}

function SearchPublication(searchinTerm, pubAction) {
	window.location.href = '/plugin/Koha/Plugin/EDS/opac/eds-search.pl?q=Search?query-1=AND,:{' + searchinTerm + '}|action=addfacetfilter(' + encodeURIComponent(pubAction) + ')&default=1';
}


// function ConfigDefaultData() {
// 	GoDiscovery(true);
// 	//console.log('configured');
// }

function ConfigData(data) {

	window.edsConfig = data;

	eds_sessionStorage.set('edsConfig', data);

	catalogueId = (data.cataloguedbid == "-") ? "" : data.cataloguedbid;
	defaultParams = (data.defaultparams == "-") ? "" : data.defaultparams;


	if (data.defaultsearch != "off") {
		var currentDefaultSearchValue = eds_sessionStorage.get('defaultSearch');
		if (!currentDefaultSearchValue) {
			eds_sessionStorage.set('defaultSearch', data.defaultsearch)
		}
		GoDiscovery();
	}
}

function GoDiscovery() {

	try { edsSelectedKnownItem = edsKnownItem } catch (e) { edsSelectedKnownItem = ''; }

	var optionSelect = 1;
	kohaOptions = '';
	$('#masthead_search option').each(function () {
		var optionText = $(this).text().replace('--- ', '');
		var optionSelected = "";
		if ($(this).val() != "") { optionText = "--- " + optionText; }
		if ($(this).val() == "") { optionText = kohaSelectText; }
		if (optionSelect == 1 && optionText == kohaSelectText) { optionSelected = ' selected '; optionSelect = 0 }
		kohaOptions += '<option ' + optionSelected + ' value="' + $(this).val() + '">' + optionText + '</option>';
		firstTimeSearchOptions = kohaOptions;
		$(this).remove();
	});

	if (firstTimeSearchOptions != "") {
		kohaOptions = firstTimeSearchOptions;
	}

	$('#masthead_search option').remove();
	kohaOptions = "<option value='eds'>" + edsSwitchText + "</option>" + kohaOptions;
	$('#masthead_search').append(kohaOptions);
	//$('#masthead_search option[value="eds"]').remove();
	//$('#masthead_search').prepend("<option value='eds'>" + edsSwitchText + "</option>");
	$('#masthead_search option[value=""]').attr("selected", "selected");
	$("#masthead_search").change(function () {
		knownItem = $(this).val();
		if (($(this).val() == 'eds') && (eds_sessionStorage.get('defaultSearch') != 'eds')) { SetEDS(1); }// Search EDS
		else if (($(this).val() == '') && (eds_sessionStorage.get('defaultSearch') != 'koha')) { SetKoha(1); }// Search Koha
	});

	if (eds_sessionStorage.get('edsKnownItems')) {
		SetEDSOptions(eds_sessionStorage.get('edsKnownItems'));
	} else {
		SetEDSOptions(JSON.parse('[{"FieldCode":"AU","Label":"Author"},{"FieldCode":"TI","Label":"Title"}]'));// Hardcoded to improve initial loading time. Uses cached values from the server the seconds time.
		$.getJSON('/plugin/Koha/Plugin/EDS/opac/eds-raw.pl?q=knownitems', function (data) { StoreEDSOptions(data); });
	}

	if (eds_sessionStorage.get('defaultSearch') == 'eds') {
		SetEDS(0);
	}

}

function StoreEDSOptions(data) {
	if (!eds_sessionStorage.get('edsKnownItems')) {
		eds_sessionStorage.set('edsKnownItems', data)
		SetEDSOptions(data);
	}
}

function SetEDSOptions(data) {
	edsOptions = '';
	edsOptions += '<option value="">' + kohaSwitchText + '</option><option selected="selected" value="eds">' + edsSelectText + '</option>';
	for (var i = 0; i < data.length; i++) {
		var selectedItem = "";
		if (edsSelectedKnownItem == data[i].FieldCode) { selectedItem = 'selected="selected"' }
		edsOptions += '<option ' + selectedItem + ' value="' + data[i].FieldCode + '">--- ' + data[i].FieldCode + ': ' + data[i].Label + '</option>';
	}

	if (eds_sessionStorage.get('defaultSearch') == "eds") {
		SetEDS(0);
	} else if (eds_sessionStorage.get('defaultSearch') == "koha") { SetKoha(0); }

	var date = new Date();
	var minutes = 30;
	date.setTime(date.getTime() + (minutes * 60 * 1000));
	//$.cookie("isEDSData","1", { expires: date });
}

function SetEDS(showInfo) {
	$('#searchform').submit(function () { return false; });
	$('#searchsubmit').click(SearchEDS);
	$('#masthead_search option').each(function () { $(this).remove(); });
	if (showInfo) { ShowInfo(edsSelectInfo); }
	$('#masthead_search').append(edsOptions);
	eds_sessionStorage.set('defaultSearch', 'eds');
	$('#transl1').val($.cookie('QueryTerm'));
	$('.transl1').val($.cookie('QueryTerm')); //for 314
	$('#searchBread').text(edsLang.search_breadcrumb + " " + $.cookie('QueryTerm'));
	$('#transl1').removeClass('placeholder');
	//advSearch
	if (document.URL.indexOf("/plugin/Koha/Plugin/EDS/opac/eds-search.pl") != -1 && QueryString('q') == "") {
		$('a[href="/cgi-bin/koha/opac-search.pl"]').attr('title', kohaSwitchText);
	} else if (document.URL.indexOf("/cgi-bin/koha/opac-search.pl") != -1 && QueryString('q') == "") {
		$('a[href="/cgi-bin/koha/opac-search.pl"]').attr('title', edsSwitchText);
		$('a[href="/cgi-bin/koha/opac-search.pl"]').attr('href', '/plugin/Koha/Plugin/EDS/opac/eds-search.pl');
	} else {
		$('a[href="/cgi-bin/koha/opac-search.pl"]').attr('href', '/plugin/Koha/Plugin/EDS/opac/eds-search.pl');
	}

	if (document.URL.indexOf("/plugin/Koha/Plugin/EDS/opac/pfi-search.pl") != -1) {
		$('#masthead_search option[value="JN"]').prop('selected', true);
		knownItem = "JN";
	}

	EDSAutoComp();
}

function SetKoha(showInfo) {
	$('#searchform').unbind('submit');
	$('#searchsubmit').unbind('click');
	$('#masthead_search option').each(function () { $(this).remove(); });
	if (showInfo) { ShowInfo(kohaSelectInfo); }
	$('#masthead_search').append(kohaOptions);
	$('#masthead_search option[value="eds"]').remove();
	$('#masthead_search').prepend("<option value='eds'>" + edsSwitchText + "</option>");
	eds_sessionStorage.set('defaultSearch', 'koha')
	//advSearch
	if (document.URL.indexOf("/plugin/Koha/Plugin/EDS/opac/eds-search.pl") != -1 && QueryString('q') == "") {
		$('a[href="/cgi-bin/koha/opac-search.pl"]').attr('title', kohaSwitchText);
	} else if (document.URL.indexOf("/cgi-bin/koha/opac-search.pl") != -1 && QueryString('q') == "") {
		$('a[href="/cgi-bin/koha/opac-search.pl"]').attr('title', edsSwitchText);
		$('a[href="/cgi-bin/koha/opac-search.pl"]').attr('href', '/plugin/Koha/Plugin/EDS/opac/eds-search.pl');
	} else {
		$('a[href="/plugin/Koha/Plugin/EDS/opac/eds-search.pl"]').attr('href', '/cgi-bin/koha/opac-search.pl');
	}
	$('#translControl1').autocomplete("destroy");
}

function ShowInfo(msg) {
	var topPos = $('#masthead_search').offset().top;
	var leftPos = $('#masthead_search').offset().left;
	var cartMsg = $("#cartDetails").html();
	if (activeState == 0) {
		activeState = 1;
	}
	$("#cartDetails").html(msg);
	showCart();
	$("#cartDetails").css('left', leftPos + 'px');
	$("#cartDetails").css('top', (topPos + 40) + 'px');
	setTimeout(function () {
		hideCart();
		$("#cartDetails").html(cartMsg);
	}, 2000);
}

function SearchEDS() {
	var searchTerm;

	try { searchTerm = $('#transl1').val().replace(/\&/g, "%2526"); } catch (err) {
		if (searchTerm == undefined) searchTerm = $('.transl1').val().replace(/\&/g, "%2526");
	} // for bootstrap

	if (knownItem == 'eds') { knownItem = ''; }
	if (defaultParams === undefined) { defaultParams = ''; }
	var apiSearchType = "eds";
	if (knownItem == 'JN') { apiSearchType = "pfi"; }
	window.location = '/plugin/Koha/Plugin/EDS/opac/' + apiSearchType + '-search.pl?q=Search?query-1=AND,' + knownItem + ':{' + searchTerm + '}' + defaultParams + '&default=1' + nocorrect;
}

function EDSGetRecord(recordURL, callingObjParent) {
	recordURL = recordURL.replace(/\%26/g, "%2526");
	$.getJSON('/plugin/Koha/Plugin/EDS/opac/eds-raw.pl' + '?' + 'q=Search?' + recordURL, function (data) { EDSGoToRecord(data); });
	$('.' + callingObjParent).html('<center><span><img src="/opac-tmpl/bootstrap/images/loading.gif" width="14"></span></center>');
}

function EDSGoToRecord(data) {
	var gotoURL = '/plugin/Koha/Plugin/EDS/opac/eds-detail.pl?q=Retrieve?an=' + data.SearchResult.Data.Records[0].Header.An + '|dbid=' + data.SearchResult.Data.Records[0].Header.DbId + '&resultid=' + data.SearchResult.Data.Records[0].ResultId;
	if (data.SearchResult.Data.Records[0].Header.DbId.indexOf(catalogueId) > -1) {
		gotoURL = '/cgi-bin/koha/opac-detail.pl?resultid=' + data.SearchResult.Data.Records[0].ResultId + '&biblionumber=' + data.SearchResult.Data.Records[0].Header.An.replace(edsConfig.catalogueanprefix, '');
	}
	window.location = gotoURL;
}


function EDSBrowseResults(fetchURL) {

	var currentBrowsePage = fetchURL;
	regex = /pagenumber\=\d/;
	currentBrowsePage = currentBrowsePage.match(regex)[0];
	currentBrowsePage = currentBrowsePage.replace('pagenumber=', '');
	browseNextPage = eval(currentBrowsePage) + 1;
	browseNextPage = fetchURL.replace(/pagenumber\=\d/, 'pagenumber=' + browseNextPage);
	$("li[title='More Results']").html('<center><span><img src="/opac-tmpl/bootstrap/images/loading.gif" width="14"></span></center>');

	$.getJSON('/plugin/Koha/Plugin/EDS/opac/eds-raw.pl' + '?' + 'q=Search?' + fetchURL, function (data) { EDSAppendToBrowse(data); });
}

function EDSAppendToBrowse(data) {
	var totalHits = data.SearchResult.Statistics.TotalHits;
	var maxResultId = "";
	var searchResults = '';
	for (var i = 0; i < data.SearchResult.Data.Records.length; i++) {
		try {
			searchResults += '<li title="Go to detail" class="highlight" ><a href="?q=Retrieve?an=' + data.SearchResult.Data.Records[i].Header.An.replace('\w+\.', '') + '|dbid=' + data.SearchResult.Data.Records[i].Header.DbId + '&resultid=' + data.SearchResult.Data.Records[i].ResultId + '"><span class="">' + data.SearchResult.Data.Records[i].ResultId + '. </span>' + $('<div/>').html(data.SearchResult.Data.Records[i].Items[0].Data).text() + '</a></li>';
			maxResultId = data.SearchResult.Data.Records[i].ResultId;
		} catch (e) {
			searchResults += '<li title="' + edsLang.go_to_detail + '" class="highlight" >' + data.SearchResult.Data.Records[i].ResultId + '. <span class="">' + edsLang.login_to_access + '</span></li>';
			$('.FullTextLoader').css('display', 'none');
		}
	}
	if (maxResultId < totalHits) {
		searchResults += '<li title="' + edsLang.more_details + '" class="highlight" ><a href="javascript:EDSBrowseResults(\'' + browseNextPage + '\');"><center>' + edsLang.view_more_results + '</center></a></li>';
	}
	$("li[title='More Results']").remove('li');
	$(".pagination_list").css('max-height', $(window).height() - ($('.nav_results').offset().top + 100));
	$(".pagination_list").css('overflow', 'auto');
	$("#browseLoader").css('display', 'none');
	$("#ul_pagination_list").append(searchResults);
	$("#ul_pagination_list").css('padding-top', '0px');
}

function EDSSetDetailPageNavigator() {
	$('#titleBread').text($('#titleBread').text() + $('.title').text());
	if ($('.back_results a').attr('href').indexOf('q=Search?') > -1) {
		$("#a_listResults").unbind('click');
		$("#ul_pagination_list").append('<div align="center" id="browseLoader"><img title="' + edsLang.more_loading_msg + '" src="/opac-tmpl/bootstrap/images/loading.gif" width="14" ></div>');
		$("#a_listResults").click(function (e) {
			var navigation = $(".results-pagination");
			if (navigation.css("display") == 'none') {
				navigation.show();
			} else {
				navigation.hide();
			}
		});
		$("#close_pagination").click(function (e) {
			var navigation = $(".results-pagination");
			navigation.hide();
		});
		EDSBrowseResults($.cookie('ReturnToResults'));
		if ($('.back_results a').attr('href').indexOf('opac-search.pl?q=Search?') > -1) {
			$('.back_results a').attr('href', $('.back_results a').attr('href').replace('opac-search.pl?q=Search?', '/plugin/Koha/Plugin/EDS/opac/eds-search.pl?q=Search?'));
		}
		var resultId = QueryString('resultid');
		var previousResult = parseInt(resultId) - 1;
		var nextResult = parseInt(resultId) + 1;
		var simpleQuery = $.cookie('EDSSimpleQuery');
		if (previousResult > 0) {
			$('.left_results').html('<a href="javascript:EDSGetRecord(\'' + simpleQuery + '|resultsperpage=1|pagenumber=' + previousResult + '\',\'left_results\')" title="' + edsLang.previous_title + '">&laquo; ' + edsLang.previous + '</a>');
		}
		if (nextResult < 250 && nextResult < $.cookie('ResultTotal')) {
			$('.right_results').html('<a href="javascript:EDSGetRecord(\'' + simpleQuery + '|resultsperpage=1|pagenumber=' + nextResult + '\',\'right_results\')" title="' + edsLang.next_title + '">' + edsLang.next + ' &raquo;</a>');
		}
	}
	$('.breadcrumb a:contains("Details for:")').text('Details for: ' + $('.title').text());

	if (QueryString('fulltext') == 'html') {
		$('.html-customlink').each(function () {
			if ($(this).text().trim() == "HTML Full Text") {
				$('.FullTextLoader').css('display', 'block');
				window.location.href = $(this).attr('href');
				return false;
			}
		});
	} else if (QueryString('fulltext') != '') {
		$('.' + QueryString('fulltext')).each(function () {
			//if($(this).text().trim()=="PDF Full Text"){
			$('.FullTextLoader').css('display', 'block');
			window.location.href = $(this).attr('href');
			return false;
			//}
		});
	}
}

function MinFullTextLoader() {

	if ($('.FullTextLoader').css('height') == "40px")
		$('.FullTextLoader').css('height', '100%');
	else
		$('.FullTextLoader').css('height', '40px');
}

function LoginRequired() {
	alert(edsLang.login_to_access);
	$('.FullTextLoader').css('display', 'none');
}

function QueryString(key) {
	var re = new RegExp('(?:\\?|&)' + key + '=(.*?)(?=&|$)', 'gi');
	var r = [], m;
	while ((m = re.exec(document.location.search)) != null) r.push(m[1]);
	return r;
}

//BASKET START---------
function InitCartWithEDS() {
	jQuery('#addto').change(function () { CheckEDSRecordsforAddToList(); });
	jQuery('.addto input:submit').click(function () { CheckEDSRecordsforAddToList(); });

	if (document.URL.indexOf('opac-basket.pl') != -1) {// basket stuff.
		document.cookie = 'bib_list=' + QueryString('bib_list') + ";path=/";
		PrepareItems();
	}

	if ((document.URL.indexOf('opac-downloadcart.pl') != -1) || (document.URL.indexOf('opac-sendbasket.pl') != -1)) {
		SetEDSCartField();
	}
}

async function PrepareItems() {

	//Get Bib numbers from the url
	var recordList = document.URL;
	recordList = QueryString("bib_list").toString();

	//Split bib list into array on /
	var recordId = recordList.split("/");

	//Iterate through all the record IDs
	for (var edsItemCount = 0; edsItemCount < recordId.length - 1; edsItemCount++) {
		//Check that it doesn't have the catalogue dbid
		if (recordId[edsItemCount].indexOf(edsConfig.cataloguedbid) == -1)
			//Look for bib numbers that include a | as these will be EDS records
			if (recordId[edsItemCount].indexOf("__") != -1)
				//If we find a EDS record, up the count
				EDSItems++;
	}

	//If we have any EDS items, we need to add the loader
	if (EDSItems > 0) {
		$('#download_cart').prop('action', '/plugin/Koha/Plugin/EDS/opac/2005/opac-downloadcart.pl');
		$('.print-large, .print').attr('onclick', ''); // .print for prog
		$('.print-large, .print').attr('href', 'javascript:window.print();location.reload();'); // .print for prog
		$('#itemst').append('<tr id="EDSBasketLoader"><td>&nbsp;</td><td nowrap="nowrap"><img src="/opac-tmpl/bootstrap/images/loading.gif" width="15"> ' + edsLang.basket_loading + '</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td></tr>');
		$(".dataTables_empty").css('display', 'none');
		await IterateEDSItems(recordId);
		SetEDSCartField();
	}

	if ((EDSItems == 0)) {
		$('#EDSBasketLoader').remove()
	}



}
async function IterateEDSItems(recordId) {
	//iterate through all the EDS items
	for (i = 0; i < recordId.length - 1; i++) {
		//ignore catalogue records
		if (recordId[i].indexOf(edsConfig.cataloguedbid) == -1) {
			//get the current record ID from cache
			var recordDataCache = eds_sessionStorage.get(recordId[i]);
			//If recordDataCache is null or is an EDS record due to __
			if (recordDataCache == null && recordId[i].indexOf('__') != -1) {
				//set recordId to be a retrieve call?
				recordId[i] = "Retrieve?an=" + recordId[i].replace(/\_dot\_/g, ".").replace("__", "|dbid=");
				//get the data from eds through the "raw" api call
				getRecord = new Promise(resolve => {
					$.getJSON('/plugin/Koha/Plugin/EDS/opac/eds-raw.pl' + '?' + 'q=' + recordId[i], function (data) {
						//use the data to GetEDSItems
						AN = data.Record.Header.An.replace(/\./g, "_dot_");
						let selector = AN + "__" + data.Record.Header.DbId;
						if (verbose == 1) { BuildMoreDetails(data) } else { GetEDSItems(data); }
						$(`[id="${selector}"]`).bind('change', function () { selRecord(this.value, this.checked) });
						resolve(true);
					});
				});
				await getRecord;

			} else if (recordDataCache) {
				//If we had recordDataCache, use that
				if (verbose == 1) {
					BuildMoreDetails(recordDataCache);
				} else {
					GetEDSItems(recordDataCache);
				}
			}

		}
	}
}

function GetEDSItems(data) {
	AN = data.Record.Header.An.replace(/\./g, "_dot_");
	try {
		$('#itemst').append('<tr><td><input type="checkbox" class="cb" value="' + AN + '__' + data.Record.Header.DbId + '" name="' + AN + '__' + data.Record.Header.DbId + '" id="' + AN + '__' + data.Record.Header.DbId + '"></td><td><a href="#" onclick="opener.document.location=\'/plugin/Koha/Plugin/EDS/opac/eds-detail.pl?q=Retrieve?an=' + data.Record.Header.An + '|dbid=' + data.Record.Header.DbId + '\'">' + $("<div/>").html(data.Record.Items[0].Data).text() + '</a></td><td>' + $("<div/>").html(data.Record.Items[1].Data).text() + '</td><td>' + data.Record.RecordInfo.BibRecord.BibRelationships.IsPartOfRelationships[0].BibEntity.Dates[0].Y + '</td><td>' + edsLang.basket_item_location + '</td></tr>');
		EDSItems--;
		if (EDSItems == 0) { $('#EDSBasketLoader').remove() }

		eds_sessionStorage.set(AN + '__' + data.Record.Header.DbId, data);

	} catch (e) {
		console.log(e);
		EDSItems--;
		if (EDSItems == 0) { $('#EDSBasketLoader').remove() }
	}

	jQuery('.cb').click(function () {
		enableCheckboxActions();
		var selectedValues = document.myform.records.value;
		var containsEDSItems = (selectedValues.replace('__' + edsConfig.cataloguedbid, edsConfig.cataloguedbid).indexOf('__') > -1) ? true : false;


		if (containsEDSItems) {
			jQuery('.hold, .newshelf').addClass('disabled');
		}

		jQuery('.hold').removeAttr('onclick');
		jQuery('.hold').unbind('click');
		jQuery('.hold').click(function () {
			if (containsEDSItems) {
				alert(edsLang.basket_deselect_hold);
			} else {
				holdSel(); return false;
			}
		});

		jQuery('.newshelf').removeAttr('onclick');
		jQuery('.newshelf').unbind('click');
		jQuery('.newshelf').click(function () {
			if (containsEDSItems) {
				alert(edsLang.basket_deselect_list);
			} else {
				addSelToShelf(); return false;
			}
		});
	});
}

function CheckEDSRecordsforAddToList() {
	var containsEDS = false;
	jQuery('tr input[type="checkbox"]:checked').each(function () {
		var currentCheckBox = this;
		checkBoxVal = jQuery(currentCheckBox).val();
		var containsEDSItems = (checkBoxVal.replace('__' + edsConfig.cataloguedbid, edsConfig.cataloguedbid).indexOf('__') > -1) ? true : false;

		if (containsEDSItems) {
			containsEDS = true;
			return false;
		}

	});

	if (containsEDS == true) {
		//jQuery(newin).on('load', function () {
		//alert(newin.location.pathname);
		if (newin.location.pathname !== undefined) {
			alert(edsLang.basket_deselect_list);
			newin.close();
		}
		//});
	}
}


function SetEDSCartField() {
	//Use the EDS version of sendbasket

	if ($('#sendbasketform')) {
		$('#sendbasketform').prop('action', '/plugin/Koha/Plugin/EDS/opac/2005/opac-sendbasket.pl');
	}
	//GET record list from URL and split into array on /
	var recordList = document.URL;
	recordList = QueryString("bib_list").toString();
	//recordList = recordList.replace(/\_dot\_/g, ".");
	var recordId = recordList.split("/");

	var fieldDataObj = { Records: [] };

	//For each recordID
	for (i = 0; i < recordId.length - 1; i++) {
		// ignore catalogue records
		if (recordId[i].indexOf(edsConfig.cataloguedbid) == -1) {
			//Create a field Record Object
			var fieldRecordObj = {};
			fieldRecordObj[recordId[i]] = eds_sessionStorage.get(recordId[i]);
			//Push to the FieldDataObject Records Array
			fieldDataObj.Records.push(fieldRecordObj);
		}
	}
	//Add a hidden object with fieldDataObject
	//if on SendCart, put in different place than if on the general cart screen
	if ($('#sendbasketform')) {
		$('.action').prepend('<input type="hidden" name="eds_data" value="' + encodeURIComponent(JSON.stringify(fieldDataObj)) + '">');
	}
	if ($('#download_cart')) {
		$('#download_cart').append('<input type="hidden" name="eds_data" value="' + encodeURIComponent(JSON.stringify(fieldDataObj)) + '">');
	}

}



function sendBasket() { // override function in basket.js
	var nameCookie = "bib_list";
	var valCookie = readCookie(nameCookie);
	var strCookie = nameCookie + "=" + valCookie;

	var loc = "/plugin/Koha/Plugin/EDS/opac/2005/opac-sendbasket.pl?" + strCookie;

	var optWin = "scrollbars=yes,resizable=yes,height=600,width=900,top=50,left=100";
	var win_form = open(loc, "win_form", optWin);
}

function downloadBasket() { // override function in basket.js
	var nameCookie = "bib_list";
	var valCookie = readCookie(nameCookie);
	var strCookie = nameCookie + "=" + valCookie;

	var loc = "/plugin/Koha/Plugin/EDS/opac/2005/opac-downloadcart.pl?" + strCookie;

	open(loc, "win_form", 'scrollbars=no,resizable=no,height=300,width=450,top=50,left=100');
}

//BASKET END----

function BuildMoreDetails(detailedRecord) {
	try {
		var recordDbId = detailedRecord.Record.Header.DbId;
		var recordAN = detailedRecord.Record.Header.An;

		var moreDetailsData = '\
		<h3>\
			<input type="checkbox" class="cb" value="'+ recordAN + '__' + recordDbId + '" name="bib' + recordAN + '__' + recordDbId + '" id="bib' + recordAN + '__' + recordDbId + '">\
			'+ detailedRecord.Record.RecordInfo.BibRecord.BibEntity.Titles[0].TitleFull + '\
		</h3>\
		<table class="table">\
			<tbody>';

		for (itemCount = 0; itemCount < detailedRecord.Record.Items.length; itemCount++) {
			if (detailedRecord.Record.Items[itemCount].Label != "Title") {
				moreDetailsData = moreDetailsData + '\
				<tr>\
					<th scope="row">\
					'+ detailedRecord.Record.Items[itemCount].Label + '\
					</th>\
					<td>\
					<p>'+ $('<div/>').html(detailedRecord.Record.Items[itemCount].Data).text() + '</p>\
					</td>\
				</tr>\
				';
			}
		}


		moreDetailsData = moreDetailsData + '\
			</tbody>\
		</table>\
		';

		$('#bookbag_form').append(moreDetailsData);

	} catch (err) { }
}


//ADVANCED SEARCH START
function AddSearchBlock(blockNo) {
	var newBlock = $('#searchFields_' + blockNo).html();
	newBlock = newBlock.replace("(" + blockNo + ")", "(" + (blockNo + 1) + ")");
	newBlock = newBlock.replace("(" + blockNo + ")", "(" + (blockNo + 1) + ")");
	newBlock = newBlock.replace('style="display:none;"', "");
	$('#searchFields_' + blockNo + ' .addRemoveLinks').css('display', 'none');
	$("#searchBlock").append('<li id="searchFields_' + (blockNo + 1) + '">' + newBlock + '</li>');
	searchBlockCount++;
}
function RemoveSearchBlock(blockNo) {
	$('#searchFields_' + blockNo).remove();
	searchBlockCount--;
	$('#searchFields_' + searchBlockCount + ' .addRemoveLinks').css('display', 'inline');
}

function AdvSearchEDS() {
	var advQuery = "";
	for (sbCount = 1; sbCount <= searchBlockCount; sbCount++) {
		var advBool = $("#searchFields_" + sbCount + " .advBool").val(); if (advBool == undefined) { advBool = "AND"; }
		var advKi = $("#searchFields_" + sbCount + " .advFieldCode").val();
		var advTerm = $("#searchFields_" + sbCount + " .advInput").val();
		if (advTerm == undefined) { advTerm = ""; } else { advTerm = advTerm.replace(/\&/g, "%2526"); }

		if (advTerm.length > 1)
			advQuery += "query-" + sbCount + "=" + advBool + "," + advKi + ":{" + advTerm + "}|";
	}

	$("input.advSBOps").each(function (index, value) {

		if (jQuery(this).attr("type") == "checkbox" || jQuery(this).attr("type") == "radio") {
			if (jQuery(this).is(":checked")) {
				jQuery(this).val(jQuery(this).val().replace(":value", ":y"));
				advQuery += "action=" + jQuery(this).val() + "|";
			}
		} else if (jQuery(this).attr("type") == "text") {
			if (jQuery(this).val().length > 1) {
				jQuery(this).attr("data-action", jQuery(this).attr("data-action").replace(":value", ":" + jQuery(this).val()));
				advQuery += "action=" + jQuery(this).attr("data-action") + "|";
			}
		}
	});

	$("select.advSBOps option:selected").each(function (index, value) {
		advQuery += "action=" + $(this).val() + "|";
	});

	//dateRange
	var fromMonth = ($("#common_DT1").val() == "") ? "01" : $("#common_DT1").val();
	var toMonth = ($("#common_DT1_ToMonth").val() == "") ? "12" : $("#common_DT1_ToMonth").val();
	var fromYear = $("#common_DT1_FromYear").val();
	var toYear = $("#common_DT1_ToYear").val();
	if (fromYear != "YYYY" && toYear != "YYYY") {
		if (isNaN(fromYear) || isNaN(toYear)) {
			alert(edsLang.date_valid_format);
			$("#common_DT1_FromYear").focus();
			return;
		} else {
			advQuery += "action=" + jQuery("#common_DT1_FromYear").attr("data-action").replace(":value", ":" + fromYear + "-" + fromMonth + "/" + toYear + "-" + toMonth);
		}
	}

	//alert(advQuery);
	window.location.href = "eds-search.pl?q=Search?" + advQuery;

}
//ADVANCED SEARCH END

// Multiple Facets START

function SetFacet(checkBoxItem) {

	var facetAction = jQuery(checkBoxItem).next().attr('href');

	// If no multiFacet store, create it 
	if (Object.keys(multiFacet).length == 0) {
		var action = [];
		facetAction.split("__").slice(1).forEach(function (item, index, arr) {
			var e = item.split("=");

			if (multiFacet[e[0]]) {
				if (typeof multiFacet[e[0]] == "object") {
					multiFacet[e[0]].push(e[1]);
				} else {
					var arr = [multiFacet[e[0]]];
					arr.push(e[1]);
					multiFacet[e[0]] = arr;
				}
			} else {
				multiFacet[e[0]] = e[1];
			}

		});
		multiFacet.action = action;
	}

	var newAction = facetAction.substring(facetAction.indexOf('|action')).replace("|", "").split("=");

	if (jQuery(checkBoxItem).is(':checked')) {
		multiFacet.action.push(newAction[1]);
		activeFacets++;
		UpdateFacetButton(1);
	} else {
		multiFacet.action = removeMatchArray(newAction[1], multiFacet.action);
		activeFacets--;
		UpdateFacetButton(0);
	}

}

function removeMatchArray(match, array) {
	for (var i = 0; i < array.length; i++) {
		if (array[i] == match) {
			array.splice(i, 1);
			return array;
		}
	}
	return array;
}

function UpdateFacetButton(state) {
	if (activeFacets == 0) {
		jQuery('#updatefacets').remove();
	} else if (activeFacets == 1 && state == 1) {
		jQuery('body').append('<input type="button" id="updatefacets" value="' + edsLang.update_facets + '" class="updateFacet" onclick="UpdateFacet()">');
		jQuery('#updatefacets').css('top', '102px');
		jQuery('#updatefacets').animate({ "top": "-=100px" }, "fast");
	} else {
		jQuery('#updatefacets').animate({ "top": "+=10px" }, "fast");
		jQuery('#updatefacets').animate({ "top": "-=10px" }, "fast");
	}
}

function UpdateFacet() {
	var newEDSURL = document.URL.replace("&default=1", "");
	var str = [];
	for (var e in multiFacet) {
		if (typeof multiFacet[e] == "object") {
			for (var i = 0; i < multiFacet[e].length; i++) {
				str.push(e + "=" + multiFacet[e][i]);
			}
		} else {
			str.push(e + "=" + multiFacet[e]);
		}
	}
	window.location.href = document.URL.split("|")[0].replace("&default=1", "") + "|" + str.join("|");
}


function SearchAgain() {
	var resultsSelector = (jQuery('#noresultsfound').length) ? '#noresultsfound' : '#top-pages'; // top-pages for bootstrap
	var searchQueryString = document.URL;
	jQuery(resultsSelector + ' input[type="checkbox"]').each(function () {
		var checkItem = this;
		if (!jQuery(checkItem).is(':checked')) {
			searchQueryString = searchQueryString.replace('|' + jQuery(checkItem).val(), '');
		}
	});
	window.location.href = searchQueryString;
}

// Multile Facets END

//
function PlacardTabs(placardTab) {
	jQuery('#placard-tabs').append('<div class="placard-tab-item"><a id="' + placardTab + '-tab" href="javascript:void(0)">' + jQuery('#' + placardTab).data('heading') + '</a></div>');
	if (jQuery('#placard-tabs a').length == 1) {
		jQuery('#' + placardTab + '-tab').addClass('placard-tab-item-active');
		jQuery('#' + placardTab).parent().parent().css('display', '');
	}

	if (jQuery('#placard-tabs a').length > 1) {
		jQuery('#placard-tabs').parent().css('display', '');
	}

	jQuery('#' + placardTab + '-tab').click(function () {
		jQuery('.placardtab').css('display', 'none');
		jQuery('#placard-tabs a').removeClass('placard-tab-item-active');
		jQuery('#' + placardTab).parent().parent().css('display', '');
		jQuery('#' + placardTab + '-tab').addClass('placard-tab-item-active');
	});

}

function ApplyPlaceAdjustments() {
	if (jQuery('.eds-refine').length != 0) {
		if (jQuery(window).width() > 1300) {
			jQuery('.eds-refine').removeClass('span4').removeClass('span3').addClass('span2');
			jQuery('.maincontent').removeClass('span8').removeClass('span9').addClass('span10');
		} else if (jQuery(window).width() < 1299 && jQuery(window).width() > 900) {
			jQuery('.eds-refine').removeClass('span4').removeClass('span2').addClass('span3');
			jQuery('.maincontent').removeClass('span8').removeClass('span10').addClass('span9');
		} else {
			jQuery('.eds-refine').removeClass('span2').removeClass('span3').addClass('span4');
			jQuery('.maincontent').removeClass('span10').removeClass('span9').addClass('span8');
		}
	}

	jQuery('#published-date').width(jQuery('#eds-dateholder').width() - 70);
}


var rangeSlider = '';
function PublisherDateSlider() {
	//Load ionRangeSlider
	jQuery.ajax({ url: 'https://cdnjs.cloudflare.com/ajax/libs/ion-rangeslider/2.1.3/js/ion.rangeSlider.min.js', dataType: 'script', cache: true }).done(function (data) {

		var pubMaxDate = jQuery("#range-published-date").data("maxdate");
		var pubMinDate = jQuery("#range-published-date").data("mindate");
		var pubDateLimiter = jQuery("#published-date").val();
		pubDateLimiter = (pubDateLimiter == "YYYY-MM/YYYY-MM") ? '' : pubDateLimiter;
		var pubFromDate = '';
		var pubToDate = '';


		if (pubDateLimiter != '') {
			var dateValue = pubDateLimiter;
			dateValue = dateValue.split('/');
			pubFromDate = dateValue[0].substring(0, 4);
			pubToDate = dateValue[1].substring(0, 4);
			pubMinDate = pubMinDate.split('-')[0];
			pubMaxDate = pubMaxDate.split('-')[0];
			//pubMinDate = jQuery.edsDB.get('pubMinDate');
			//pubMaxDate = jQuery.edsDB.get('pubMaxDate');
		} else {
			pubFromDate = pubMinDate = pubMinDate.split('-')[0];
			pubMaxDate = pubMaxDate.split('-')[0];

			var maxRealDate = parseInt(EDSGetDateForLastUpdate().substring(0, 4)) + 1;
			pubMaxDate = (parseInt(pubMaxDate) > maxRealDate) ? maxRealDate : pubMaxDate;
			pubToDate = pubMaxDate;
			//jQuery.edsDB.set('pubMinDate', pubMinDate.toString(), { TTL: edsSessionTimeout });
			//jQuery.edsDB.set('pubMaxDate', pubMaxDate.toString(), { TTL: edsSessionTimeout });
		}




		jQuery("#range-published-date").ionRangeSlider({
			type: "double",
			min: pubMinDate,
			max: pubMaxDate,
			from: pubFromDate,
			to: pubToDate,
			drag_interval: true,
			prettify_enabled: false
		});

		rangeSlider = jQuery("#range-published-date").data("ionRangeSlider");

		jQuery("#range-published-date").on('change', function () {
			//console.log(jQuery(this).val());
			var currentValue = jQuery(this).val();
			currentValue = currentValue.split(';');
			jQuery("#published-date").val(currentValue[0] + '-01' + '/' + currentValue[1] + '-12');
		});

	});

	jQuery('#eds-clear-date').click(function () {
		var e = jQuery.Event("keypress"); e.which = 13; e.keyCode = 13;
		jQuery('#published-date').val('');
		jQuery('#published-date').trigger(e);
	});

	jQuery('#eds-apply-date').click(function () {
		var e = jQuery.Event("keypress"); e.which = 13; e.keyCode = 13;
		jQuery('#published-date').trigger(e);
	});

}

function EDSGetDateForLastUpdate() {
	var dateObj = new Date();
	var month = dateObj.getUTCMonth() + 1;
	var day = dateObj.getUTCDate();
	var year = dateObj.getUTCFullYear();

	return (year.toString() + month.toString() + day.toString());
}

function DateHandleKeyPress(e, searchBox) {
	var key = e.keyCode || e.which;
	if (key == 13) {
		// dateAction is in the template
		if (searchBox.value == "") {
			dateAction = dateAction.replace('action=addlimiter(DT1:value)', 'action=removelimiter(DT1)');
			window.location.href = dateAction;
		} else {
			var regex = /^\d{4}-(0[1-9]|1[012])\/\d{4}-(0[1-9]|1[012])$/;
			// '/\d{4}-\d[1-12]\/\d{4}-\d[1-12]/; - old'
			if (regex.test(searchBox.value)) {
				dateAction = dateAction.replace('DT1:value', 'DT1:' + searchBox.value);
				window.location.href = dateAction;
			} else { alert(edsLang.date_invalid); }
		}
	}
}

function EDSAutoComp() {

	// Check for expired credentials
	var credsExpiry = eds_sessionStorage.get("autoComp_expiry");
	if (credsExpiry && credsExpiry < Math.round(Date.now() / 1000)) {
		eds_sessionStorage.remove('autoComp');
		eds_sessionStorage.remove('autoComp_expiry');
	}

	var creds = eds_sessionStorage.get("autoComp");

	var idx = "rawqueries";
	if (edsConfig.autocomplete_mode != "normal") {
		idx = "holdings";
	}

	if (eds_sessionStorage.get('defaultSearch') != "eds") {
		return;
	}

	if (!creds) {
		$.getJSON('/plugin/Koha/Plugin/EDS/opac/eds-ac.pl?type=auth', function (data) {
			eds_sessionStorage.set('autoComp', data);
			eds_sessionStorage.set('autoComp_expiry', Math.round(Date.now() / 1000) + parseInt(data.AuthTimeout) - 30);
			EDSAutoComp();
		});
	} else {
		$('#translControl1').autocomplete({
			source: function (request, response) {
				var promise = $.ajax(creds.Autocomplete.Url, {
					data: {
						token: creds.Autocomplete.Token,
						term: request.term,
						idx: idx,
						filters: JSON.stringify([{
							name: 'custid',
							values: [creds.Autocomplete.CustId]
						}])
					}
				});

				promise.done(function (data) {
					if (data.error) {
						eds_sessionStorage.remove('autoComp');
						eds_sessionStorage.remove('autoComp_expiry');

						EDSAutoComp();
					} else {
						var terms = data.terms.map(function (wrapper) {
							return wrapper.term;
						});
						response(terms);
					}
				});
			},
			select: EDSautoSearch
		});
	}
}

function EDSautoSearch(event, ui) {
	$.when($('#translControl1').val(ui.item.value)).done(function () {
		$("#searchsubmit").click();
	});
}
$('body').on('click', '#translControl1', function () {
	if (eds_sessionStorage.get('defaultSearch') == "eds") {
		$("#translControl1").autocomplete("search");
	}
});

