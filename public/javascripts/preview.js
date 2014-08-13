$(document).ready(function(){

    $("#preview-button").click(function(){
	var token = $("input[name='authenticity_token']").attr("value");
	var text = $("textarea").val();
	var lang = $("select").val();

	$.post("/preview", {text: text, markup_language: lang, authenticity_token: token}, function(result){
	    $(".preview").html(result.text);
	    $(".preview").show();
	});
    });

});
