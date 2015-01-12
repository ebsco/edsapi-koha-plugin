<html>
<head>
<title>Customisation Manager</title>
<style type="text/css" media="screen">
    #editor { 
        position: absolute;
        top: 40;
        right: 0;
        bottom: 0;
        left: 0;
    }
	body{
		font-family:Gotham, "Helvetica Neue", Helvetica, Arial, sans-serif;
	}
</style>
</head>
<body>

<div id="editor">[% FOR jsline IN customjs %][% jsline %][% END %]</div>
    
<script src="https://cdnjs.cloudflare.com/ajax/libs/ace/1.1.3/ace.js" type="text/javascript" charset="utf-8"></script>
<script>
    var editor = ace.edit("editor");
    editor.setTheme("ace/theme/monokai");
    editor.getSession().setMode("ace/mode/javascript");
    
	var jsState = '[%jsstate%]';
	if(jsState==2){
		alert('Changes saved successfully.');
	}
	
    function SaveScript(){
        document.getElementById('code').value = editor.getValue();
        document.getElementById('customjsform').action = document.URL;
        document.getElementById('customjsform').submit();
    }
    
</script>
<div style="float:left;"><strong>Customisation Manager</strong></div>
<div style="float:right;">
    <form method="post" action="/cgi-bin/koha/plugins/run.pl" id="customjsform">
        <input name="class" id="class" type="hidden" value="Koha::Plugin::EDS">
        <input name="method" id="method" type="hidden" value="tool">
        <input name="code" id="code" type="hidden">
        <input name="js" id="js" type="hidden" value="2">
        <input name="save" id="save" type="button" value="Save Changes" onclick="SaveScript();">
    </form>
</div>

</body>
</html> 