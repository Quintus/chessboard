$(document).ready(function(){

    $(".quickreply-form").show();

    $(".quickreply-form").submit(function(){
	var topic = $(".quickreply-form").attr("data-topicid");
	var token = $("input[name='authenticity_token']").val();

	jQuery.post("/topics/" + topic + "/posts/new?authenticity_token=" + token, {
	    post: {
		content: $("#post_content").val(),
		markup_language: $("#post_markup_language").val()
	    }
	}, function(result){
	    var template = Handlebars.compile($("#post-template").html());
	    $(".post").last().after(template(JSON.parse(result)));

	    // Clear form for next time
	    $("#post_content").val("");
	});

	return false;
    });
});
