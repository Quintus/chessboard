$(document).ready(function(){

    $(".show-raw-item a").click(function(){
	$(this).parents("li").css("display", "none");
	$(this).parents("ul").children("li.show-normal-item").css("display", "inline");

	$(this).parents(".post-content").find(".post-normal-markup").hide();
	$(this).parents(".post-content").find(".post-raw-markup").show();

	return false;
    });

    $(".show-normal-item a").click(function(){
	$(this).parents("li").css("display", "none");
	$(this).parents("ul").children("li.show-raw-item").css("display", "inline");

	$(this).parents(".post-content").find(".post-raw-markup").hide();
	$(this).parents(".post-content").find(".post-normal-markup").show();

	return false;
    });

    // Show JS-only link (so it is hidden for non-JS-capable browsers)
    $(".show-raw-item").css("display", "inline");
});
