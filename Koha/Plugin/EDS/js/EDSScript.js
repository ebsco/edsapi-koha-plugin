var knownItem = '';
var activeState=0;
var edsOptions="";
var kohaOptions = "";
var firstTimeSearchOptions = "";
var edsSelectedKnownItem="";
//var defaultSearch=""; set by configure
var browseNextPage="";
var catalogueId="";

//-configurable in plugin config
var edsSwitchText = '';
var kohaSwitchText = '';
var edsSelectText = '';
var edsSelectInfo = '';
var kohaSelectInfo = '';

var defaultParams ='';
var multiFacet=[];
var activeFacets=0;
//-basket stuff
var edsConfig ="";
var callPrepareItems = false;
var EDSItems = 0;
var verbose = QueryString('verbose');
var bibListLocal = 0;
var versionEDSKoha = '17.11';
var edsLangStore = '';

if(QueryString('debug')!="1"){$(window).error(function (e) { e.preventDefault(); });}
else{console.log('JS debug enabled')}// keep executing if there is an error.}


jQuery.ajax({ url: "/plugin/Koha/Plugin/EDS/js/jquery.cookie.min.js", dataType: "script", cache: true }).done(function (data, textStatus, jqxhr) {
	
	if(jQuery.jStorage.get('edsVersion')!=versionEDSKoha){
		jQuery.jStorage.flush();
		jQuery.jStorage.set('edsVersion',versionEDSKoha,{ TTL: edsConfig.cookieexpiry * 60 * 1000 });
	}
	
    if (typeof EDSLANG === 'undefined') {

        if ($.jStorage.get("edsLang_" + jQuery('html').attr('lang')) == null) {

            jQuery.ajax({ url: "/plugin/Koha/Plugin/EDS/bootstrap/includes/lang/" + jQuery('html').attr('lang') + ".inc", dataType: "script", cache: true }).done(function (data) { StartEDS(data); })
                .fail(function () { jQuery.ajax({ url: "/plugin/Koha/Plugin/EDS/bootstrap/includes/lang/default.inc", dataType: "script", cache: true }).done(function (data) { StartEDS(data); }); });
        } else { StartEDS(0) }
    } else { StartEDS(0) }
});

function StartEDS(edsLang) {

    if (edsLang != 0) {$.jStorage.set("edsLang_" + jQuery('html').attr('lang'), edsLang, { TTL: edsConfig.cookieexpiry * 60 * 1000 });
    } else {jQuery.globalEval($.jStorage.get("edsLang_" + jQuery('html').attr('lang')));}
	
//-configurable in plugin config
    edsSwitchText = EDSLANG.eds_switch_text;
    kohaSwitchText = EDSLANG.koha_switch_text;
    edsSelectText = EDSLANG.eds_select_text;
    edsSelectInfo = EDSLANG.eds_select_info;
    kohaSelectInfo = EDSLANG.koha_select_info;
	

	jQuery(window).resize(function () { try { ApplyPlaceAdjustments(); } catch (err) { ApplyPlaceAdjustments(); } });
	ApplyPlaceAdjustments();


	PublisherDateSlider();
	
		
	if ($.cookie("guest") == 'y') {
	    jQuery('.results_summary.actions.links a').each(function () {
	        jQuery(this).attr('href', 'javascript:LoginRequired()');
	        jQuery(this).attr('target', '_self');
	    });
	}

	if ($.jStorage.get("edsConfig") != null) {
	    ConfigData((JSON.parse($.jStorage.get("edsConfig"))));
	} else {
	    ConfigDefaultData();
	    $.getJSON('/plugin/Koha/Plugin/EDS/opac/eds-raw.pl' + '?' + 'q=config', function (data) { ConfigData(data); });
	}

    //$("#masthead_search").attr("disabled","disabled");
	if (typeof $('.back_results a').attr('href') != 'undefined') { EDSSetDetailPageNavigator(); }

	InitCartWithEDS(); // cart management

	jQuery('#eds-autosuggest').click(function () {
	    var autoSuggest = this;
	    var autoSuggestText = jQuery(autoSuggest).text();
	    jQuery('#translControl1').val(autoSuggestText);
	    jQuery('#searchsubmit').trigger('click');
	});



}

jQuery.ajax({ url: "/plugin/Koha/Plugin/EDS/js/custom/custom.js", dataType: "script", cache: true }); // load customisations.


function PFIAtoZBar() {
    var barHolder = '<div class="pagination-small"><ul><li><stong>' + EDSLANG.pfi_atoz_bar + '</strong> </li>';
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
        window.location.href = "pfi-search.pl?q=Search?query-1=AND,:{JN+" + jQuery(currentAlpha).text() + "*}|sort=title";
    });
}

jQuery('.search-in-pub-button').click(function () {
    currentPubButton = this;
    searchTerm = jQuery(currentPubButton).parent().find('.search-in-pub-field').val();
    pubAction = jQuery(currentPubButton).parent().find('.search-in-pub-field').data('action');
    SearchPublication(searchTerm, pubAction);
});

function SearchPublication(searchinTerm, pubAction) {
    window.location.href = '/plugin/Koha/Plugin/EDS/opac/eds-search.pl?q=Search?query-1=AND,:{' + searchinTerm + '}|action=addfacetfilter(' + encodeURIComponent(pubAction) + ')&default=1';
}


function ConfigDefaultData() {
    GoDiscovery(true);
    //console.log('configured');
}

function ConfigData(data){
	
	edsConfig=data;
	if($.jStorage.get("edsConfig")==null)
		$.jStorage.set("edsConfig",(JSON.stringify(data)),{TTL:edsConfig.cookieexpiry*60*1000}); // cache in browser storage
	
	catalogueId = (data.cataloguedbid=="-")?"":data.cataloguedbid;
	defaultParams = (data.defaultparams == "-") ? "" : data.defaultparams;
	defaultSearch = (data.defaultsearch == "-") ? "" : data.defaultsearch;
	
	if (defaultSearch != "off") {
	    if (!$.jStorage.get('defaultSearch')) {
	        defaultSearch = data.defaultsearch;
	        $.jStorage.set('defaultSearch', defaultSearch, { TTL: edsConfig.cookieexpiry * 60 * 1000 });
	    } else {
	        defaultSearch = $.jStorage.get('defaultSearch');
	    }
		GoDiscovery();
	}else{
		//$("#masthead_search").removeAttr("disabled");
		//$("#transl1").removeAttr("disabled");
	}
}

function GoDiscovery(firstTime) {
    firstTime = firstTime || false;

		try{edsSelectedKnownItem=edsKnownItem}catch(e){edsSelectedKnownItem='';}

		
		var optionSelect = 1;
		    kohaOptions = '';
		    $('#masthead_search option').each(function () {
		        var optionText = $(this).text().replace('--- ', '');
		        var optionSelected = "";
		        if ($(this).val() != "") { optionText = "--- " + optionText; }
		        if ($(this).attr('selected') && optionSelect == 1) { optionSelected = ' selected="selected" '; optionSelect = 0 }
		        kohaOptions += '<option ' + optionSelected + ' value="' + $(this).val() + '">' + optionText + '</option>';
		        if (firstTime) { firstTimeSearchOptions = kohaOptions; }
		        $(this).remove();
		    });
            
		    if (firstTimeSearchOptions!=""){
		        kohaOptions = firstTimeSearchOptions;
		    }

		$('#masthead_search option').remove();
		$('#masthead_search').append(kohaOptions);
		$('#masthead_search option[value="eds"]').remove();
		$('#masthead_search').prepend("<option value='eds'>"+edsSwitchText+"</option>");
		$("#masthead_search").change(function () {
		    knownItem = $(this).val();
		    if (($(this).val() == 'eds') && (defaultSearch != 'eds')) { SetEDS(1); }// Search EDS
		    else if (($(this).val() == '') && (defaultSearch != 'koha')) { SetKoha(1); }// Search Koha
		});

		
		if($.jStorage.get("edsKnownItems")!=null){
			var knownItems = $.jStorage.get('edsKnownItems');
			SetEDSOptions(JSON.parse(knownItems));
		}else{
			SetEDSOptions(JSON.parse('[{"FieldCode":"AU","Label":"Author"},{"FieldCode":"TI","Label":"Title"}]'));// Hardcoded to improve initial loading time. Uses cached values from the server the seconds time.
			$.getJSON('/plugin/Koha/Plugin/EDS/opac/eds-raw.pl?q=knownitems',function(data){StoreEDSOptions(data);});
		}
		

		
}

function StoreEDSOptions(data){
	if($.jStorage.get("edsKnownItems")==null){
		$.jStorage.set('edsKnownItems',JSON.stringify(data),{TTL:edsConfig.cookieexpiry*60*1000});	
		SetEDSOptions(data);
	}
}

function SetEDSOptions(data){
	edsOptions='';
	edsOptions+='<option value="">'+kohaSwitchText+'</option><option selected="selected" value="eds">'+edsSelectText+'</option>';
	for(var i=0; i<data.length; i++){
		var selectedItem ="";
		if(edsSelectedKnownItem==data[i].FieldCode){selectedItem='selected="selected"'}
		edsOptions+='<option '+selectedItem+' value="'+data[i].FieldCode+'">--- '+data[i].FieldCode+': '+data[i].Label+'</option>';
	}
	
	if(defaultSearch=="eds"){SetEDS(0);
	}else if(defaultSearch=="koha"){SetKoha(0);}
	
	var date = new Date();
	var minutes = 30;
	date.setTime(date.getTime() + (minutes * 60 * 1000));
	//$.cookie("isEDSData","1", { expires: date });
}

function SetEDS(showInfo){
			$('#searchform').submit(function(){return false;});
			$('#searchsubmit').click(SearchEDS);
			$('#masthead_search option').each(function(){$(this).remove();});
			if(showInfo){ShowInfo(edsSelectInfo);}
			$('#masthead_search').append(edsOptions);
			//$.removeCookie('defaultSearch', { path: '/' });
			$.jStorage.set('defaultSearch', 'eds', { TTL: edsConfig.cookieexpiry * 60 * 1000 });
			defaultSearch="eds";
			$('#transl1').val($.cookie('QueryTerm'));
			$('.transl1').val($.cookie('QueryTerm')); //for 314
			$('#searchBread').text(EDSLANG.search_breadcrumb + " " + $.cookie('QueryTerm'));
			$('#transl1').removeClass('placeholder');
			//advSearch
			if(document.URL.indexOf("/plugin/Koha/Plugin/EDS/opac/eds-search.pl")!=-1 && QueryString('q')==""){
				$('a[href="/cgi-bin/koha/opac-search.pl"]').attr('title',kohaSwitchText);
			}else if(document.URL.indexOf("/cgi-bin/koha/opac-search.pl")!=-1  && QueryString('q')==""){
				$('a[href="/cgi-bin/koha/opac-search.pl"]').attr('title',edsSwitchText);
				$('a[href="/cgi-bin/koha/opac-search.pl"]').attr('href','/plugin/Koha/Plugin/EDS/opac/eds-search.pl');
			}else{
				$('a[href="/cgi-bin/koha/opac-search.pl"]').attr('href','/plugin/Koha/Plugin/EDS/opac/eds-search.pl');
			}
	
			if(document.URL.indexOf("/plugin/Koha/Plugin/EDS/opac/pfi-search.pl")!=-1){
				$('#masthead_search option[value="JN"]').prop('selected',true);
				knownItem="JN";
			}
	
			
}

function SetKoha(showInfo){
			$('#searchform').unbind('submit');
			$('#searchsubmit').unbind('click');
			$('#masthead_search option').each(function(){$(this).remove();});
			if(showInfo){ShowInfo(kohaSelectInfo);}
			$('#masthead_search').append(kohaOptions);
			$('#masthead_search option[value="eds"]').remove();
			$('#masthead_search').prepend("<option value='eds'>"+edsSwitchText+"</option>");
			//$.removeCookie('defaultSearch', { path: '/' });
			$.jStorage.set('defaultSearch', 'koha', { TTL: edsConfig.cookieexpiry * 60 * 1000 })
			defaultSearch="koha";
			//advSearch
			if(document.URL.indexOf("/plugin/Koha/Plugin/EDS/opac/eds-search.pl")!=-1 && QueryString('q')==""){
				$('a[href="/cgi-bin/koha/opac-search.pl"]').attr('title',kohaSwitchText);
			}else if(document.URL.indexOf("/cgi-bin/koha/opac-search.pl")!=-1  && QueryString('q')==""){
				$('a[href="/cgi-bin/koha/opac-search.pl"]').attr('title',edsSwitchText);
				$('a[href="/cgi-bin/koha/opac-search.pl"]').attr('href','/plugin/Koha/Plugin/EDS/opac/eds-search.pl');
			}else{
				$('a[href="/plugin/Koha/Plugin/EDS/opac/eds-search.pl"]').attr('href','/cgi-bin/koha/opac-search.pl');
			}
}

function ShowInfo(msg){
	var topPos = $('#masthead_search').offset().top;
	var leftPos = $('#masthead_search').offset().left;
	var cartMsg = $("#cartDetails").html();
	if(activeState==0){
		activeState=1;
	}
	$("#cartDetails").html(msg);
	showCart();
	$("#cartDetails").css('left',leftPos+'px');
	$("#cartDetails").css('top',(topPos+40)+'px');
	setTimeout(function(){
		hideCart();
		$("#cartDetails").html(cartMsg);
		},2000);
}

function SearchEDS(){
	var searchTerm;
	
  try{searchTerm = $('#transl1').val().replace(/\&/g,"%2526");}catch(err){
	  if(searchTerm==undefined) searchTerm = $('.transl1').val().replace(/\&/g,"%2526");} // for bootstrap
	  
  if(knownItem=='eds'){knownItem='';}
  if (defaultParams === undefined) { defaultParams = ''; }
  var apiSearchType = "eds";
  if (knownItem == 'JN') { apiSearchType = "pfi"; }
  window.location = '/plugin/Koha/Plugin/EDS/opac/' + apiSearchType + '-search.pl?q=Search?query-1=AND,' + knownItem + ':{' + searchTerm + '}' + defaultParams + '&default=1';
}

function EDSGetRecord(recordURL,callingObjParent){
	recordURL = recordURL.replace(/\%26/g,"%2526");
	$.getJSON('/plugin/Koha/Plugin/EDS/opac/eds-raw.pl'+'?'+'q=Search?'+recordURL,function(data){EDSGoToRecord(data);});
	$('.' + callingObjParent).html('<center><span><img src="/opac-tmpl/bootstrap/images/loading.gif" width="14"></span></center>');
}

function EDSGoToRecord(data){
	 var gotoURL= '/plugin/Koha/Plugin/EDS/opac/eds-detail.pl?q=Retrieve?an='+data.SearchResult.Data.Records[0].Header.An+'|dbid='+data.SearchResult.Data.Records[0].Header.DbId+'&resultid='+data.SearchResult.Data.Records[0].ResultId;
	 if(data.SearchResult.Data.Records[0].Header.DbId.indexOf(catalogueId)>-1){
	     gotoURL = '/cgi-bin/koha/opac-detail.pl?resultid=' + data.SearchResult.Data.Records[0].ResultId + '&biblionumber=' + data.SearchResult.Data.Records[0].Header.An.replace(edsConfig.catalogueanprefix, '');
	 }
	 window.location = gotoURL;
}


function EDSBrowseResults(fetchURL){
	
	var currentBrowsePage = fetchURL;
	regex = /pagenumber\=\d/;
	currentBrowsePage = currentBrowsePage.match(regex)[0];
	currentBrowsePage = currentBrowsePage.replace('pagenumber=','');
	browseNextPage=eval(currentBrowsePage)+1;
	browseNextPage = fetchURL.replace(/pagenumber\=\d/,'pagenumber='+browseNextPage);
	$("li[title='More Results']").html('<center><span><img src="/opac-tmpl/bootstrap/images/loading.gif" width="14"></span></center>');
	
	$.getJSON('/plugin/Koha/Plugin/EDS/opac/eds-raw.pl'+'?'+'q=Search?'+fetchURL,function(data){EDSAppendToBrowse(data);});
}

function EDSAppendToBrowse(data){
	var totalHits = data.SearchResult.Statistics.TotalHits;
	var maxResultId = "";
	var searchResults = '';
	for(var i=0; i<data.SearchResult.Data.Records.length; i++){
		try{
		searchResults += '<li title="Go to detail" class="highlight" ><a href="?q=Retrieve?an='+data.SearchResult.Data.Records[i].Header.An.replace('\w+\.','')+'|dbid='+data.SearchResult.Data.Records[i].Header.DbId+'&resultid='+data.SearchResult.Data.Records[i].ResultId+'"><span class="">'+data.SearchResult.Data.Records[i].ResultId+'. </span>'+$('<div/>').html(data.SearchResult.Data.Records[i].Items[0].Data).text()+'</a></li>';
		maxResultId = data.SearchResult.Data.Records[i].ResultId;
		}catch(e){
		    searchResults += '<li title="' + EDSLANG.go_to_detail + '" class="highlight" >' + data.SearchResult.Data.Records[i].ResultId + '. <span class="">' + EDSLANG.login_to_access + '</span></li>';
				$('.FullTextLoader').css('display','none');
		}
	}
	if(maxResultId<totalHits){
	    searchResults += '<li title="' + EDSLANG.more_details + '" class="highlight" ><a href="javascript:EDSBrowseResults(\'' + browseNextPage + '\');"><center>' + EDSLANG.view_more_results + '</center></a></li>';
	}
	$("li[title='More Results']").remove('li');
	$(".pagination_list").css('max-height',$( window ).height()-($('.nav_results').offset().top+100));
	$(".pagination_list").css('overflow','auto');
	$("#browseLoader").css('display','none');
	$("#ul_pagination_list").append(searchResults);
	$("#ul_pagination_list").css('padding-top','0px');
}

function EDSSetDetailPageNavigator(){
	$('#titleBread').text($('#titleBread').text()+$('.title').text());
	if($('.back_results a').attr('href').indexOf('q=Search?')>-1){
		$("#a_listResults").unbind('click');
		$("#ul_pagination_list").append('<div align="center" id="browseLoader"><img title="' + more_loading_msg + '" src="/opac-tmpl/bootstrap/images/loading.gif" width="14" ></div>');
		$("#a_listResults").click(function(e) {
			var navigation = $(".results-pagination");
			if (navigation.css("display") == 'none') {
				navigation.show();
			} else {
				navigation.hide();
			}
		});
		$("#close_pagination").click(function(e) {
			var navigation = $(".results-pagination");
			navigation.hide();
		});
		EDSBrowseResults($.cookie('ReturnToResults'));
		if($('.back_results a').attr('href').indexOf('opac-search.pl?q=Search?')>-1){
			$('.back_results a').attr('href',$('.back_results a').attr('href').replace('opac-search.pl?q=Search?','/plugin/Koha/Plugin/EDS/opac/eds-search.pl?q=Search?'));
		}
		var resultId = QueryString('resultid');
		var previousResult = parseInt(resultId)-1;
		var nextResult = parseInt(resultId)+1;
		var simpleQuery = $.cookie('EDSSimpleQuery');
		if(previousResult>0){
		    $('.left_results').html('<a href="javascript:EDSGetRecord(\'' + simpleQuery + '|resultsperpage=1|pagenumber=' + previousResult + '\',\'left_results\')" title="' + EDSLANG.previous_title + '">&laquo; ' + EDSLANG.previous + '</a>');
		}
		if(nextResult<250 && nextResult<$.cookie('ResultTotal')){
		    $('.right_results').html('<a href="javascript:EDSGetRecord(\'' + simpleQuery + '|resultsperpage=1|pagenumber=' + nextResult + '\',\'right_results\')" title="' + next_title + '">' + next + ' &raquo;</a>');
		}
	}
	$('.breadcrumb a:contains("Details for:")').text('Details for: '+$('.title').text());
	
	if(QueryString('fulltext')=='html'){
		$('.html-customlink').each(function(){
			if($(this).text().trim()=="HTML Full Text"){
				$('.FullTextLoader').css('display','block');
				window.location.href=$(this).attr('href');
				return false;
			}
			});
	}else if(QueryString('fulltext')!=''){
		$('.'+QueryString('fulltext')).each(function(){
			//if($(this).text().trim()=="PDF Full Text"){
				$('.FullTextLoader').css('display','block');
				window.location.href=$(this).attr('href');
				return false;
			//}
			});
	}
}

function MinFullTextLoader(){
	
	if($('.FullTextLoader').css('height')=="40px")
		$('.FullTextLoader').css('height','100%');
	else
		$('.FullTextLoader').css('height','40px');
}

function LoginRequired(){
    alert(EDSLANG.login_to_access);
	$('.FullTextLoader').css('display','none');
}

function QueryString(key) {
   var re=new RegExp('(?:\\?|&)'+key+'=(.*?)(?=&|$)','gi');
   var r=[], m;
   while ((m=re.exec(document.location.search)) != null) r.push(m[1]);
   return r;
}

//BASKET START---------
function InitCartWithEDS() {

    jQuery('#addto').change(function () { CheckEDSRecordsforAddToList(); });
    jQuery('.addto input:submit').click(function () { CheckEDSRecordsforAddToList(); });




    if ($.jStorage.get("bib_list") != null) {
        try {
            var jbib_list = $.jStorage.get("bib_list");
            document.cookie = 'bib_list=' + jbib_list;
            if (basketcount == "") basketcount = 0;
            //if (basketcount != jbib_list.split('/').length - 1)
               //updateBasket(jbib_list.length -1);
        } catch (err) { }
    }


    if (document.URL.indexOf('opac-basket.pl') != -1) {// basket stuff.
        $.jStorage.set("bib_list", QueryString('bib_list'), { TTL: edsConfig.cookieexpiry * 60 * 1000 });
        document.cookie = 'bib_list=' + QueryString('bib_list');
        PrepareItems();

        $('.empty').removeAttr('onclick');
        $('.empty').click(function () { // copy of delBasket in Koha's basket.js
            var nameCookie = "bib_list";
            var rep = false;
            rep = confirm(MSG_CONFIRM_DEL_BASKET);
            if (rep) {
                delCookie(nameCookie);
                updateAllLinks(top.opener);
                document.location = "about:blank";
                updateBasket(0, top.opener);
                $.jStorage.set("bib_list", "", { TTL: edsConfig.cookieexpiry * 60 * 1000 }); // added this line
                window.close();
            }
        });
        $('.addtocart').click(function () {
            $.jStorage.set("bib_list", $.cookie("bib_list"), { TTL: edsConfig.cookieexpiry * 60 * 1000 });
        });
        $('.cartRemove').click(function () {
            $.jStorage.set("bib_list", $.cookie("bib_list"), { TTL: edsConfig.cookieexpiry * 60 * 1000 });
        });
    }


    if ((document.URL.indexOf('opac-downloadcart.pl') != -1) || (document.URL.indexOf('opac-sendbasket.pl') != -1)) {
        SetEDSCartField();
    }
}

function PrepareItems(){
	if(callPrepareItems==false){callPrepareItems=true;}else{return;} 

	var recordList = document.URL;
	recordList = QueryString("bib_list").toString();

	var recordId=recordList.split("/");
	
	for(var edsItemCount=0;edsItemCount<recordId.length-1;edsItemCount++){
		if(recordId[edsItemCount].indexOf(edsConfig.cataloguedbid)==-1)
			if(recordId[edsItemCount].indexOf("|")!=-1)
				EDSItems++;
	}
	
	if(EDSItems>0){ 
		$('.print-large, .print').attr('onclick',''); // .print for prog
		$('.print-large, .print').attr('href','javascript:window.print();location.reload();'); // .print for prog
		$('#itemst').append('<tr id="EDSBasketLoader"><td>&nbsp;</td><td nowrap="nowrap"><img src="/opac-tmpl/bootstrap/images/loading.gif" width="15"> ' + EDSLANG.basket_loading + '</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td></tr>');
		$(".dataTables_empty").css('display','none');
	}
	
	for(i=0;i<recordId.length-1;i++){
		if(recordId[i].indexOf(edsConfig.cataloguedbid)==-1){ // ignore catalogue records
			var recordDataCache = $.jStorage.get(recordId[i]);
			if(recordDataCache==null && recordId[i].indexOf('|')!=-1){
				recordId[i] = "Retrieve?an="+recordId[i].replace("|","|dbid=");
				$.getJSON('/plugin/Koha/Plugin/EDS/opac/eds-raw.pl'+'?'+'q='+recordId[i],function(data){
					if(verbose==1){BuildMoreDetails(data)}else{GetEDSItems(data);}});
			}else{
				if(verbose==1){
					BuildMoreDetails(JSON.parse(recordDataCache));			
				}else{
					GetEDSItems(JSON.parse(recordDataCache));
				}
			}
		}
	}

		if((EDSItems==0)){
			$('#EDSBasketLoader').css('display','none');
		}
		
		
}

function GetEDSItems(data){
	try{
	    $('#itemst').append('<tr><td><input type="checkbox" class="cb" value="' + data.Record.Header.An + '|' + data.Record.Header.DbId + '" name="' + data.Record.Header.An + '|' + data.Record.Header.DbId + '" id="' + data.Record.Header.An + '|' + data.Record.Header.DbId + '" onclick="selRecord(value,checked);"></td><td><a href="#" onclick="opener.document.location=\'/plugin/Koha/Plugin/EDS/opac/eds-detail.pl?q=Retrieve?an=' + data.Record.Header.An + '|dbid=' + data.Record.Header.DbId + '\'">' + $("<div/>").html(data.Record.Items[0].Data).text() + '</a></td><td>' + $("<div/>").html(data.Record.Items[1].Data).text() + '</td><td>' + data.Record.RecordInfo.BibRecord.BibRelationships.IsPartOfRelationships[0].BibEntity.Dates[0].Y + '</td><td>' + EDSLANG.basket_item_location + '</td></tr>');
	EDSItems--;
	if(EDSItems==0){$('#EDSBasketLoader').css('display','none');}

	$.jStorage.set(data.Record.Header.An+'|'+data.Record.Header.DbId,JSON.stringify(data),{TTL:edsConfig.cookieexpiry*60*1000});
	
	} catch (e) {
	    console.log(e);
		EDSItems--;
		if(EDSItems==0){$('#EDSBasketLoader').css('display','none');}
	}

	jQuery('.cb').click(function () {
	    enableCheckboxActions();
	    var selectedValues = document.myform.records.value;
	    var containsEDSItems = (selectedValues.replace('|' + edsConfig.cataloguedbid, edsConfig.cataloguedbid).indexOf('|') > -1) ? true : false;


	    if (containsEDSItems) {
	        jQuery('.hold, .newshelf').addClass('disabled');
	    }

	    jQuery('.hold').removeAttr('onclick');
	    jQuery('.hold').unbind('click');
	    jQuery('.hold').click(function () {
	        if (containsEDSItems) {
	            alert(EDSLANG.basket_deselect_hold);
	        } else {
	            holdSel(); return false;
	        }
	    });

	    jQuery('.newshelf').removeAttr('onclick');
	    jQuery('.newshelf').unbind('click');
	    jQuery('.newshelf').click(function () {
	        if (containsEDSItems) {
	            alert(EDSLANG.basket_deselect_list);
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
        var containsEDSItems = (checkBoxVal.replace('|' + edsConfig.cataloguedbid, edsConfig.cataloguedbid).indexOf('|') > -1) ? true : false;

        if (containsEDSItems) {
            containsEDS = true;
            return false;
        }

    });

    if (containsEDS == true) {
        //jQuery(newin).on('load', function () {
            //alert(newin.location.pathname);
            if (newin.location.pathname!==undefined) {
                alert(EDSLANG.basket_deselect_list);
                newin.close();
            }
        //});
    }
}


function SetEDSCartField(){
	var recordList = document.URL;
	recordList = QueryString("bib_list").toString();
	var recordId=recordList.split("/");
	
	var fieldDataObj = {Records:[]};
	
	for(i=0;i<recordId.length-1;i++){
		if(recordId[i].indexOf(edsConfig.cataloguedbid)==-1){ // ignore catalogue records
			var fieldRecordObj = {};
			fieldRecordObj[recordId[i]]=JSON.parse($.jStorage.get(recordId[i]));
			fieldDataObj.Records.push(fieldRecordObj);
		}
	}
	$('.action').prepend('<input type="hidden" name="eds_data" value="'+encodeURIComponent(JSON.stringify(fieldDataObj))+'">');
}

jQuery('#sendbasketform').attr('action', '/plugin/Koha/Plugin/EDS/opac/1711/opac-sendbasket.pl');
function sendBasket() { // override function in basket.js
    var nameCookie = "bib_list";
    var valCookie = readCookie(nameCookie);
    var strCookie = nameCookie + "=" + valCookie;

    var loc = "/plugin/Koha/Plugin/EDS/opac/1711/opac-sendbasket.pl?" + strCookie;

    var optWin = "scrollbars=yes,resizable=yes,height=600,width=900,top=50,left=100";
    var win_form = open(loc, "win_form", optWin);
}

jQuery('form[action="/cgi-bin/koha/opac-downloadcart.pl"]').attr('action', '/plugin/Koha/Plugin/EDS/opac/1711/opac-downloadcart.pl');
function downloadBasket() { // override function in basket.js
    alert('asdf');
    var nameCookie = "bib_list";
    var valCookie = readCookie(nameCookie);
    var strCookie = nameCookie + "=" + valCookie;

    var loc = "/plugin/Koha/Plugin/EDS/opac/1711/opac-downloadcart.pl?" + strCookie;

    open(loc, "win_form", 'scrollbars=no,resizable=no,height=300,width=450,top=50,left=100');
}

//BASKET END----

function BuildMoreDetails(detailedRecord) {
    try {
        var recordDbId = detailedRecord.Record.Header.DbId;
        var recordAN = detailedRecord.Record.Header.An;

        var moreDetailsData = '\
		<h3>\
			<input type="checkbox" class="cb" value="'+ recordAN + '|' + recordDbId + '" name="bib' + recordAN + '|' + recordDbId + '" id="bib' + recordAN + '|' + recordDbId + '" onclick="selRecord(value,checked)">\
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
var searchBlockCount=3;
function AddSearchBlock(blockNo){
	var newBlock = $('#searchFields_'+blockNo).html();
	newBlock = newBlock.replace("("+blockNo+")","("+(blockNo+1)+")");
	newBlock = newBlock.replace("("+blockNo+")","("+(blockNo+1)+")");
	newBlock = newBlock.replace('style="display:none;"',"");
	$('#searchFields_'+blockNo+' .addRemoveLinks').css('display','none');
	$("#searchBlock").append('<li id="searchFields_'+(blockNo+1)+'">'+newBlock+'</li>');
	searchBlockCount++;
}
function RemoveSearchBlock(blockNo){
	$('#searchFields_'+blockNo).remove();
		searchBlockCount--;
	$('#searchFields_'+searchBlockCount+' .addRemoveLinks').css('display','inline');
}

function AdvSearchEDS(){
	var advQuery="";
	for(sbCount=1;sbCount<=searchBlockCount;sbCount++){
		var advBool=$("#searchFields_"+sbCount+" .advBool").val(); if(advBool==undefined){advBool="AND";}
		var advKi=$("#searchFields_"+sbCount+" .advFieldCode").val();
		var advTerm=$("#searchFields_"+sbCount+" .advInput").val(); 
		if(advTerm==undefined){advTerm="";}else{advTerm=advTerm.replace(/\&/g,"%2526");}
	
		if(advTerm.length>1)
			advQuery+="query-"+sbCount+"="+advBool+","+advKi+":{"+advTerm+"}|";
	}
	
	$("input.advSBOps").each(function(index,value){

		if(jQuery(this).attr("type")=="checkbox" || jQuery(this).attr("type")=="radio"){
			if(jQuery(this).is(":checked")){
				jQuery(this).val(jQuery(this).val().replace(":value",":y"));
				advQuery+="action="+jQuery(this).val()+"|";
			}
		}else if(jQuery(this).attr("type")=="text"){
			if(jQuery(this).val().length>1){
				jQuery(this).attr("data-action",jQuery(this).attr("data-action").replace(":value",":"+jQuery(this).val()));
				advQuery+="action="+jQuery(this).attr("data-action")+"|";
			}
		}
	});
	
	$("select.advSBOps option:selected").each(function(index,value){
			advQuery+="action="+$(this).val()+"|";
	});
	
	//dateRange
	var fromMonth=($("#common_DT1").val()=="")?"01":$("#common_DT1").val();
	var toMonth=($("#common_DT1_ToMonth").val()=="")?"12":$("#common_DT1_ToMonth").val();
	var fromYear=$("#common_DT1_FromYear").val();
	var toYear=$("#common_DT1_ToYear").val();
	if (fromYear!="YYYY" && toYear!="YYYY"){
		if(isNaN(fromYear) || isNaN(toYear)){
		    alert(EDSLANG.date_valid_format);
			$("#common_DT1_FromYear").focus();
			return;
		}else{
			advQuery+="action="+jQuery("#common_DT1_FromYear").attr("data-action").replace(":value",":"+fromYear+"-"+fromMonth+"/"+toYear+"-"+toMonth);
		}
	}
	
	//alert(advQuery);	
	window.location.href="eds-search.pl?q=Search?"+advQuery;
	
}
//ADVANCED SEARCH END 

// Multiple Facets START

function SetFacet(checkBoxItem){
	var facetAction = jQuery(checkBoxItem).next().attr('href');
	facetAction = facetAction.substring(facetAction.indexOf('|action'));
	if(jQuery(checkBoxItem).is(':checked')){
		multiFacet.push(facetAction);
		activeFacets++;
		UpdateFacetButton(1);
	}else{
		multiFacet.splice( $.inArray(facetAction, multiFacet), 1 );
		activeFacets--;
		UpdateFacetButton(0);
	}
}

function UpdateFacetButton(state){
	if(activeFacets==0){
		jQuery('#updatefacets').remove();
	}else if(activeFacets==1 && state == 1){
		jQuery('body').append('<input type="button" id="updatefacets" value="'+EDSLANG.update_facets+'" class="updateFacet" onclick="UpdateFacet()">');
		jQuery('#updatefacets').css('top','102px');
		jQuery('#updatefacets').animate({"top":"-=100px"},"fast");
	}else{
		jQuery('#updatefacets').animate({"top":"+=10px"},"fast");
		jQuery('#updatefacets').animate({"top":"-=10px"},"fast");
	}
}

function UpdateFacet(){
	var newEDSURL = document.URL.replace("&default=1","");
	newEDSURL=newEDSURL+multiFacet.join('');
	window.location.href=newEDSURL;
}


function SearchAgain(){
	var resultsSelector = (jQuery('#noresultsfound').length)?'#noresultsfound':'#top-pages'; // top-pages for bootstrap
	var searchQueryString = document.URL;
	jQuery(resultsSelector+' input[type="checkbox"]').each(function(){
		var checkItem = this;
		if(!jQuery(checkItem).is(':checked')){
			searchQueryString = searchQueryString.replace('|'+jQuery(checkItem).val(),'');
		}
	});
	window.location.href=searchQueryString;
}

// Multile Facets END

//
function PlacardTabs(placardTab){
	jQuery('#placard-tabs').append('<div class="placard-tab-item"><a id="'+placardTab+'-tab" href="javascript:void(0)">'+jQuery('#'+placardTab).data('heading')+'</a></div>');
	if(jQuery('#placard-tabs a').length==1){
		jQuery('#'+placardTab+'-tab').addClass('placard-tab-item-active');
		jQuery('#'+placardTab).parent().parent().css('display','');
	}
		
	if(jQuery('#placard-tabs a').length>1){
		jQuery('#placard-tabs').parent().css('display','');
	}
		
	jQuery('#'+placardTab+'-tab').click(function(){
		jQuery('.placardtab').css('display','none');
		jQuery('#placard-tabs a').removeClass('placard-tab-item-active');
		jQuery('#'+placardTab).parent().parent().css('display','');
		jQuery('#'+placardTab+'-tab').addClass('placard-tab-item-active');
	});
	
}

function ApplyPlaceAdjustments() {
    if (jQuery('.eds-refine').length!=0){
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
            drag_interval: true
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
            } else { alert(EDSLANG.date_invalid); }
        }
    }
}
