$(document).ready(function(){
    $("#user-search").submit(function(){
	var query = $("#query").val();

	$(".user-search-results li").each(function(x, el){
	    var entry = $(el);

	    if (entry.text().contains(query))
		entry.show();
	    else
		entry.hide();
	});

	return false;
    });
});
