$(document).ready(function(){

    $("p.add-attachment button").click(function(){
	var result = $("div.edit-attachments").append("<div class='new-attachment'><p><input type='file' name='attachments[]'/><button class='remove-attachment'>✗</button></p></div>")

	var lastdiv = $(result).find(".new-attachment").last();

	$(lastdiv).find("button.remove-attachment").click(function(){
	    $(lastdiv).remove();
	    return false;
	});

	return false;
    });

});
