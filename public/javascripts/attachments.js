$(document).ready(function(){

    $("p.add-attachment button").click(function(){
	$("div.edit-attachments").append("<div class='new-attachment'><p><input type='file' name='attachments[][attachment]'/><br/><input type='text' name='attachments[][description]'/></p></div>")
	return false;
    });

});
