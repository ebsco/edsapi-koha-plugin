<script>
		
		function DisplayResults(data){
			var releaseNotesData="<ul>";
			data = TextToXML(data);
			
			var latestDownload = data.getElementsByTagName("download")[0];
			$('#downloadVersion').attr('onclick','window.open("'+latestDownload.childNodes[0].nodeValue+'")')

			var resultRecords = data.getElementsByTagName("release");
			for(recordNo=0; recordNo<resultRecords.length; recordNo++){
				var versionNo = resultRecords[recordNo].attributes;
				//alert(versionNo.getNamedItem("version").value);
				releaseNotesData+="<li>Version: "+versionNo.getNamedItem("version").value+"<ul>";
				var notesNum = resultRecords[recordNo].getElementsByTagName('note').length;
				for(noteNo=0; noteNo<notesNum;noteNo++){		
					releaseNotesData+="<li>"+resultRecords[recordNo].getElementsByTagName('note')[noteNo].firstChild.nodeValue+"</li>";
					//alert(resultRecords[recordNo].getElementsByTagName('note')[noteNo].firstChild.nodeValue);
				}
				releaseNotesData+="</ul></li>";
			}
			releaseNotesData+="</ul>";
			$('#releaseNotes').html(releaseNotesData);
			//alert(releaseNotesData);
		}

	
function TextToXML(text){
	if (window.ActiveXObject){
	  xmlData=new ActiveXObject('Microsoft.XMLDOM');
	  xmlData.async='false';
	  xmlData.loadXML(text);
	} else {
	  var xmlParser=new DOMParser();
	  var xmlData=xmlParser.parseFromString(text,'text/xml');
	}
	return xmlData;
}

DisplayResults(jQuery('#releaseNotes').html());

$('#liveupdate-version').change(function(e){
	UpdateButtonVersionCheck();
});

function UpdateButtonVersionCheck(){
	if($('#liveupdate-version option[selected="selected"]').text() == $('#liveupdate-version option:eq('+$('#liveupdate-version')[0].selectedIndex+')').text()){
		$('#update-button').attr('disabled','disabled');
	}else{
		$('#update-button').removeAttr('disabled');
	}
}

function UpdatePlugin(){
	alert('You have selected to update the EDS plugin. Please wait while live update runs some tests.');
	jQuery('#update-button').attr('disabled','disabled');
	
	jQuery('#check-all').trigger('click');
	var trackUpdateCheck = setInterval(function(){
		if(jQuery('#check-all').data('write')!=0){
			clearInterval(trackUpdateCheck);
			if(jQuery('#check-all').data('write')==1){
				alert('Live Update Check Passed. Updating the EDS plugin now. This will take 2 to 3 minutes. Please do not close the browser or navigate away from this page.');
				$('.FullTextLoader').css('display','block');
				window.location.href = document.URL+"&updateto="+$('#liveupdate-version option:eq('+$('#liveupdate-version')[0].selectedIndex+')').val()+"&v="+$('#liveupdate-version option:eq('+$('#liveupdate-version')[0].selectedIndex+')').text();				
			}else{
				alert('Live Update Check Failed. Please contact your System Administrator to check file permissions and ensure the plugin files and folders have Read/Write/Execute set to 755.');
				jQuery('#update-button').removeAttr('disabled');
			}
		}
	}, 3000);
	

	//window.open("https://cdn.rawgit.com/ebsco/edsapi-koha-plugin/"+$('#liveupdate-version option:eq('+$('#liveupdate-version')[0].selectedIndex+')').val()+"/eds_plugin_"+$('#liveupdate-version option:eq('+$('#liveupdate-version')[0].selectedIndex+')').text()+".kpz");
}

function QueryString(key) {
   var re=new RegExp('(?:\\?|&)'+key+'=(.*?)(?=&|$)','gi');
   var r=[], m;
   while ((m=re.exec(document.location.search)) != null) r.push(m[1]);
   return r;
}

function ReturnAfterUpdate(){
	jQuery('body').css('display','none');
	window.location.href=document.URL.replace('&updateto='+QueryString('updateto')+'&v='+QueryString('v'),'');
}

function CheckStatus(checkButton){
	var filePath = jQuery(checkButton).data('path');
	jQuery(checkButton).text('Checking...');
	jQuery(checkButton).attr('class','btn btn-info btn-small check-write');
	$.getJSON('/cgi-bin/koha/plugins/run.pl?class=Koha::Plugin::EDS&method=tool&check='+filePath,function(data){
		if(data==1){
			jQuery(checkButton).text('OK Updatable');
			jQuery(checkButton).attr('class','btn btn-success btn-small check-write');
			jQuery(checkButton).data('write','1');
		}else{ 
			jQuery(checkButton).text('NOT Updatable');
			jQuery(checkButton).attr('class','btn btn-danger btn-small check-write');
			jQuery(checkButton).data('write','-1');
		}
	});
}

function CheckAll(CheckAllButton){
	console.log('checking started');
	jQuery(CheckAllButton).text("Please wait.....");
	jQuery(CheckAllButton).attr('class','btn btn-warning');
	jQuery(CheckAllButton).attr('disabled','disabled');
	
	jQuery('.check-write').each(function(){
			console.log('getting all check-write');
			var self=this;
			jQuery(self).data('write','0');
			jQuery(self).trigger('click');
			console.log('triggering a check');
	});
	

	var trackChecking = setInterval(function(){
		var allCheckStatus="1";
		var allWriteStatus="1";
		jQuery('.check-write').each(function(){
			var self=this;
			if(jQuery(self).data('write')==0){
				allCheckStatus="0";
			}
			if(jQuery(self).data('write')==-1){
				allWriteStatus="-1";
			}
		});
		console.log('allCheckStatus='+allCheckStatus);
		console.log('allWriteStatus='+allWriteStatus);
		if(allCheckStatus==1){
			clearInterval(trackChecking);
			console.log('exiting interval');
			jQuery(CheckAllButton).removeAttr('disabled');
			if(allWriteStatus==-1){
				jQuery(CheckAllButton).text("Check Failed");
				jQuery(CheckAllButton).attr('class','btn btn-danger');
				jQuery(CheckAllButton).data('write','-1');
			}else{
				jQuery(CheckAllButton).text("Check Passed");
				jQuery(CheckAllButton).attr('class','btn btn-success');				
				jQuery(CheckAllButton).data('write','1');
			}
		}else{
			if(jQuery(CheckAllButton).attr('class')=="btn btn-warning"){
				jQuery(CheckAllButton).attr('class','btn btn-info');
			}else{
				jQuery(CheckAllButton).attr('class','btn btn-warning');
			}
		}

		
	}, 2000);
}

$(document).ready(function(){
	var updateCheck = QueryString('updateto');
	if(updateCheck!=''){
		$('#myModal').modal();
	}
	UpdateButtonVersionCheck();
});


</script>