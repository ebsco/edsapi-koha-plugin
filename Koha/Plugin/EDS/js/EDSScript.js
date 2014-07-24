/*
=============================================================================================
* WIDGET NAME: Koha EDS Integration Plugin
* DESCRIPTION: Integrates EDS with Koha
* KEYWORDS: Koha, ILS, Integration, API, EDS
* CUSTOMER PARAMETERS: None
* EBSCO PARAMETERS: None
* URL: N/A
* AUTHOR & EMAIL: Alvet Miranda - amiranda@ebsco.com
* DATE ADDED: 31/10/2013
* DATE MODIFIED: 15/07/2014
* LAST CHANGE DESCRIPTION: Added advanced search and logic for year/month seperation.
=============================================================================================
*/


var knownItem='';
var activeState=0;
var edsOptions="";
var kohaOptions="";
var edsSelectedKnownItem="";
var defaultSearch="";
var cookieExpiry="30"; //minutes -- delete; not used.
var browseNextPage="";
var catalogueId="";
//-configurable in plugin config
var edsSwitchText = "Switch to Discovery";
var kohaSwitchText = "Switch to Catalogue";
var edsSelectText = 'Discovery';
var edsSelectInfo = '<h3>Search EDS</h3>Select a known item and enter a search term';
var kohaSelectInfo = '<h3>Search Koha</h3>Select a known item and enter a search term';
//-basket stuff
var edsConfig ="";
var callPrepareItems = false;
var EDSItems = 0;
var verbose = QueryString('verbose');
var bibListLocal = "";



$(window).error(function(e){e.preventDefault();}); // keep executing if there is an error.

$(document).ready(function(){
	
	//$('body').prepend('<center><h1>This is Koha version 3.12</h1></center>');
	
	jQuery.getScript('/plugin/Koha/Plugin/EDS/js/jquery.cookie.min.js?v2', function(data, textStatus, jqxhr){
		
		
		if($.jStorage.get("edsConfig")!=null){
			ConfigData((JSON.parse($.jStorage.get("edsConfig"))));
		}else{
			$.getJSON('/plugin/Koha/Plugin/EDS/opac/eds-raw.pl'+'?'+'q=config',function(data){ConfigData(data);});
		}

		//$("#masthead_search").attr("disabled","disabled");
		if(typeof $('.back_results a').attr('href')!='undefined'){EDSSetDetailPageNavigator();}

		// cart management START
		if(document.URL.indexOf('opac-basket.pl')!=-1){// basket stuff.
			$.jStorage.set("bib_list",QueryString('bib_list'),{TTL:edsConfig.cookieexpiry*60*1000});
			PrepareItems();
			
			$('.empty').removeAttr('onclick');
			$('.empty').click(function(){ // copy of delBasket in Koha's basket.js
			    var nameCookie = "bib_list";
				var rep = false;
				rep = confirm(MSG_CONFIRM_DEL_BASKET);
				if (rep) {
					delCookie(nameCookie);
					updateAllLinks(top.opener);
					document.location = "about:blank";
					updateBasket(0,top.opener);
					$.jStorage.set("bib_list","",{TTL:edsConfig.cookieexpiry*60*1000}); // added this line
					window.close();
				}
			});
			
		}	
			
		if($.jStorage.get("bib_list")!=null){
			try{
				var jbib_list = $.jStorage.get("bib_list");
				document.cookie= 'bib_list='+jbib_list;
				if(basketcount=="")basketcount=0;
				if(basketcount!=jbib_list.split('/').length-1)
					updateBasket(jbib_list.length-1);
			}catch(err){}
		}
			
		$('.addtocart').click(function(){
			$.jStorage.set("bib_list",$.cookie("bib_list"),{TTL:edsConfig.cookieexpiry*60*1000});
		});
		$('.cartRemove').click(function(){
			$.jStorage.set("bib_list",$.cookie("bib_list"),{TTL:edsConfig.cookieexpiry*60*1000});
		});
		
		// cart management END		
	});
});

function ConfigData(data){
	
	edsConfig=data;
	if($.jStorage.get("edsConfig")==null)
		$.jStorage.set("edsConfig",(JSON.stringify(data)),{TTL:edsConfig.cookieexpiry*60*1000}); // cache in browser storage
	
	edsSwitchText = data.edsswitchtext;
	kohaSwitchText = data.kohaswitchtext;
	edsSelectText = data.edsselecttext;
	edsSelectInfo = data.edsselectinfo;
	kohaSelectInfo = data.kohaselectinfo;
	catalogueId = data.cataloguedbid;
	if(data.defaultsearch!="off"){
		if(!$.cookie('defaultSearch')){defaultSearch=data.defaultsearch;$.cookie('defaultSearch',defaultSearch);
		}else{defaultSearch=$.cookie('defaultSearch');}
		GoDiscovery();
	}else{
		//$("#masthead_search").removeAttr("disabled");
		//$("#transl1").removeAttr("disabled");
	}
}

function GoDiscovery(){		
	$(document).ready(function(){
		try{edsSelectedKnownItem=edsKnownItem}catch(e){edsSelectedKnownItem='';}


		if($.jStorage.get("edsKnownItems")==null){
			$.getJSON('/plugin/Koha/Plugin/EDS/opac/eds-raw.pl'+'?'+'q=knownitems',function(data){SetEDSOptions(data);});
		}
		
		var optionSelect=1;
		$('#masthead_search option').each(function(){
			var optionText = $(this).text();
			var optionSelected="";
			if($(this).val()!=""){optionText="--- "+optionText;}
			if($(this).attr('selected') && optionSelect==1){optionSelected=' selected="selected" ';optionSelect=0}
			kohaOptions+='<option '+optionSelected+' value="'+$(this).val()+'">'+optionText+'</option>';
			$(this).remove();
		});
		$('#masthead_search').append(kohaOptions);
		$('#masthead_search').prepend("<option value='eds'>"+edsSwitchText+"</option>");
		$("#masthead_search").change(function() {
			knownItem=$(this).val();
			if(($(this).val()=='eds') && (defaultSearch!='eds')){SetEDS(1);// Search EDS
			}else if(($(this).val()=='') && (defaultSearch!='koha')){SetKoha(1);}// Search Koha
		})
		
		if($.jStorage.get("edsKnownItems")!=null){
			var knownItems = $.jStorage.get('edsKnownItems');
			SetEDSOptions(JSON.parse(knownItems));
		}
		
		
	});
	//$("#masthead_search").removeAttr("disabled");
	//$("#transl1").removeAttr("disabled");

}

function SetEDSOptions(data){
	if($.jStorage.get("edsKnownItems")==null)
		$.jStorage.set('edsKnownItems',JSON.stringify(data),{TTL:edsConfig.cookieexpiry*60*1000});
	
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
			$.removeCookie('defaultSearch', { path: '/' });
			$.cookie('defaultSearch','eds');
			defaultSearch="eds";
			$('#transl1').val($.cookie('QueryTerm'));
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
			
}

function SetKoha(showInfo){
			$('#searchform').unbind('submit');
			$('#searchsubmit').unbind('click');
			$('#masthead_search option').each(function(){$(this).remove();});
			if(showInfo){ShowInfo(kohaSelectInfo);}
			$('#masthead_search').append(kohaOptions);
			$('#masthead_search').prepend("<option value='eds'>"+edsSwitchText+"</option>");
			$.removeCookie('defaultSearch', { path: '/' });
			$.cookie('defaultSearch','koha')
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
	$("#cartDetails").css('top',(topPos-90)+'px');
	setTimeout(function(){
		hideCart();
		$("#cartDetails").html(cartMsg);
		},2000);
}

function SearchEDS(){
  var searchTerm = $('#transl1').val();
  if(knownItem=='eds'){knownItem='';}
  window.location='/plugin/Koha/Plugin/EDS/opac/eds-search.pl?q=Search?query-1=AND,'+knownItem+':{'+searchTerm+'}&default=1';
}

function EDSGetRecord(recordURL,callingObjParent){
	$.getJSON('/plugin/Koha/Plugin/EDS/opac/eds-raw.pl'+'?'+'q=Search?'+recordURL,function(data){EDSGoToRecord(data);});
	$('.'+callingObjParent).html('<center><span><img src="/opac-tmpl/prog/images/loading.gif" width="14"></span></center>');
}

function EDSGoToRecord(data){
	 var gotoURL= '/plugin/Koha/Plugin/EDS/opac/eds-detail.pl?q=Retrieve?an='+data.SearchResult.Data.Records[0].Header.An+'|dbid='+data.SearchResult.Data.Records[0].Header.DbId+'&resultid='+data.SearchResult.Data.Records[0].ResultId;
	 if(data.SearchResult.Data.Records[0].Header.DbId.indexOf(catalogueId)>-1){
		 gotoURL= '/cgi-bin/koha/opac-detail.pl?resultid='+data.SearchResult.Data.Records[0].ResultId+'&biblionumber='+data.SearchResult.Data.Records[0].Header.An.replace('niwa.','');
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
	$("li[title='More Results']").html('<center><span><img src="/opac-tmpl/prog/images/loading.gif" width="14"></span></center>');
	
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
				searchResults += '<li title="Go to detail" class="highlight" >'+data.SearchResult.Data.Records[i].ResultId+'. <span class="">Login to gain access to this result.</span></li>';
				$('.FullTextLoader').css('display','none');
		}
	}
	if(maxResultId<totalHits){
		searchResults += '<li title="More Results" class="highlight" ><a href="javascript:EDSBrowseResults(\''+browseNextPage+'\');"><center>View More Results</center></a></li>';
	}
	$("li[title='More Results']").remove('li');
	$(".pagination_list").css('max-height',$( window ).height()-($('.nav_results').offset().top+100));
	$(".pagination_list").css('overflow','auto');
	$("#browseLoader").css('display','none');
	$("#ul_pagination_list").append(searchResults);
	$("#ul_pagination_list").css('padding-top','0px');
}

function EDSSetDetailPageNavigator(){
	if($('.back_results a').attr('href').indexOf('q=Search?')>-1){
		$("#a_listResults").unbind('click');
		$("#ul_pagination_list").append('<div align="center" id="browseLoader"><img title="Loading. Please wait..." src="/opac-tmpl/prog/images/loading.gif" width="14" ></div>');
		$("#a_listResults").click(function(e) {
			var navigation = $(".pagination");
			if (navigation.css("display") == 'none') {
				navigation.show();
			} else {
				navigation.hide();
			}
		});
		$("#close_pagination").click(function(e) {
			var navigation = $(".pagination");
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
			$('.left_results').html('<a href="javascript:EDSGetRecord(\''+simpleQuery+'|resultsperpage=1|pagenumber='+previousResult+'\',\'left_results\')" title="See previous">&laquo; Previous</a>');
		}
		if(nextResult<250 && nextResult<$.cookie('ResultTotal')){
			$('.right_results').html('<a href="javascript:EDSGetRecord(\''+simpleQuery+'|resultsperpage=1|pagenumber='+nextResult+'\',\'right_results\')" title="See next">Next &raquo;</a>');
		}
	}

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

function QueryString(key) {
   var re=new RegExp('(?:\\?|&)'+key+'=(.*?)(?=&|$)','gi');
   var r=[], m;
   while ((m=re.exec(document.location.search)) != null) r.push(m[1]);
   return r;
}

//BASKET START---------
function PrepareItems(){
	if(callPrepareItems==false){callPrepareItems=true;}else{return;} 
	
	$(document).ready(function(){
		var recordList = document.URL;
		recordList = recordList.substring(recordList.indexOf('?')+10);

		var recordId=recordList.split("/");
		

		for(var edsItemCount=0;edsItemCount<recordId.length-1;edsItemCount++){
			if(recordId[edsItemCount].indexOf(edsConfig.cataloguedbid)==-1)
				if(recordId[edsItemCount].indexOf("|")!=-1)
					EDSItems++;
		}
		
		if(EDSItems>0){
			$('.print').attr('onclick','return false;');
			$('.print').attr('href','javascript:window.print();location.reload();');
			$('#itemst').append('<tr id="EDSBasketLoader"><td>&nbsp;</td><td nowrap="nowrap"><img src="/opac-tmpl/prog/images/loading.gif" width="15"> Loading Items. Please wait...</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td></tr>');
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
			}else{
				bibListLocal+=recordId[i]+"/";
			}
		}

			if((EDSItems==0)){
				$('#EDSBasketLoader').css('display','none');
			}
			
			if(document.URL.indexOf('|')!=-1){
				var sendParent = $('.send').parent();
				$(sendParent).html('<a class="send" href="opac-basket.pl" onclick="EDSSendBasket(); return false;">Send</a>');
			}
	});
}

function GetEDSItems(data){
	try{
	$('#itemst').append('<tr><td><input type="checkbox" class="cb" value="'+data.Record.Header.An+'|'+data.Record.Header.DbId+'" name="'+data.Record.Header.An+'|'+data.Record.Header.DbId+'" id="'+data.Record.Header.An+'|'+data.Record.Header.DbId+'" onclick="selRecord(value,checked);"></td><td><a href="#" onclick="opener.document.location=\'/plugin/Koha/Plugin/EDS/opac/eds-detail.pl?q=Retrieve?an='+data.Record.Header.An+'|dbid='+data.Record.Header.DbId+'\'">'+$("<div/>").html(data.Record.Items[0].Data).text()+'</a></td><td>'+$("<div/>").html(data.Record.Items[1].Data).text()+'</td><td>'+data.Record.RecordInfo.BibRecord.BibRelationships.IsPartOfRelationships[0].BibEntity.Dates[0].Y+'</td><td>Discovery</td></tr>');
	EDSItems--;
	if(EDSItems==0){$('#EDSBasketLoader').css('display','none');}

	$.jStorage.set(data.Record.Header.An+'|'+data.Record.Header.DbId,JSON.stringify(data),{TTL:edsConfig.cookieexpiry*60*1000});
	
	}catch(e){
		EDSItems--;
		if(EDSItems==0){$('#EDSBasketLoader').css('display','none');}
	}
		//if($.jStorage.get(data.Record.Header.An+'|'+data.Record.Header.DbId)==null){

		//}
}

function BuildMoreDetails(detailedRecord){
	try{
		var recordDbId = detailedRecord.Record.Header.DbId;
		var recordAN = detailedRecord.Record.Header.An;
		
		var moreDetailsData = '\
		<h3>\
			<input type="checkbox" class="cb" value="'+recordAN+'|'+recordDbId+'" name="bib'+recordAN+'|'+recordDbId+'" id="bib'+recordAN+'|'+recordDbId+'" onclick="selRecord(value,checked)">\
			'+detailedRecord.Record.RecordInfo.BibRecord.BibEntity.Titles[0].TitleFull+'\
		</h3>\
		<table>\
			<tbody>';
	

		for(itemCount=0;itemCount<detailedRecord.Record.Items.length;itemCount++){
			if(detailedRecord.Record.Items[itemCount].Label!="Title"){
				moreDetailsData =	moreDetailsData+'\
				<tr>\
					<th>\
					'+detailedRecord.Record.Items[itemCount].Label+'\
					</th>\
					<td>\
					'+$('<div/>').html(detailedRecord.Record.Items[itemCount].Data).text()+'\
					</td>\
				</tr>\
				';
			}
		}

			
		moreDetailsData =	moreDetailsData+'\
			</tbody>\
		</table>\
		';
		
		$('#bookbag_form').append(moreDetailsData);

	}catch(err){}	
}


function EDSSendBasket() {
	if(bibListLocal==""){
		alert("There are no local items to send. Please add local items to the cart before sending.");
		return false;
	}
    var loc = CGIBIN + "opac-sendbasket.pl?bib_list=" + bibListLocal;

    var optWin="dependant=yes,scrollbars=no,resizable=no,height=300,width=450,top=50,left=100";
    var win_form = open(loc,"win_form",optWin);
}
//BASKET END----


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
		var advTerm=$("#searchFields_"+sbCount+" .advInput").val(); if(advTerm==undefined){advTerm="";}
	
		if(advTerm.length>1)
			advQuery+="query-"+sbCount+"="+advBool+","+advKi+":{"+advTerm+"}|";
	}
	
	$("input:not(.advSB)").each(function(index,value){

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
	
	$("select:not(.advSB) option:selected").each(function(index,value){
			advQuery+="action="+$(this).val()+"|";
	});
	
	//dateRange
	var fromMonth=($("#common_DT1").val()=="")?"01":$("#common_DT1").val();
	var toMonth=($("#common_DT1_ToMonth").val()=="")?"12":$("#common_DT1_ToMonth").val();
	var fromYear=$("#common_DT1_FromYear").val();
	var toYear=$("#common_DT1_ToYear").val();
	if (fromYear!="YYYY" && toYear!="YYYY"){
		if(isNaN(fromYear) || isNaN(toYear)){
			alert("Please enter a valid year in YYYY format");
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