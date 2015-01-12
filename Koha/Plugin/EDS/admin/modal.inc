<!-- Modal  -->
<div class="modal fade" id="myModal" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
       [% IF updatelog != "" %]
	        <h4 class="modal-title" id="myModalLabel">Update Complete - Log:</h4>
       [% END %]
      </div>
      <div class="modal-body">
        [% IF updatelog == "" %]
			<iframe id="customjsframe" src="" width="530" height="300" frameborder="0"></iframe>
            <script>
				$('#customjsframe').attr('src',document.URL+"&js=1");
            </script>
        [% ELSE %]
	        [% updatelog %]
        [% END %]
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-default" onClick="ReturnAfterUpdate()">Close</button>
      </div>
    </div>
  </div>
</div>