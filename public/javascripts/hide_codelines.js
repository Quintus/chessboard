$(document).ready(function(){
    $("div.CodeRay").prepend("<img class='hide-codelines' src='/images/icons/hide-codelines.png' alt='hide codelines'/>");

    $("img.hide-codelines").click(function(){
	$(this).parent().find(".line-numbers").toggle();
    });

    $("div.CodeRay").hover(function(){
	$(this).find("img.hide-codelines").show();
    }, function(){
	$(this).find("img.hide-codelines").hide();
    });
});
