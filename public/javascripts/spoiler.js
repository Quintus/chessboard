$(document).ready(function(){
    $("a.expandspoiler").click(function(){
	var spoilertag = $(this).parent().parent();

	spoilertag.toggleClass("expandspoiler");

	if (spoilertag.hasClass("expandspoiler")) {
	    $(this).html("(⇄)");
	}
	else {
	    $(this).html("(⇔)");
	}
	return false;
    });
});
