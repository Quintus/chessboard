$(document).ready(function(){
    $(".thread-tree-link").click(function(){
	$(this).parent().children(".intree-post").toggle();
	return false;
    });

    $(".expand-all a").click(function(){
	$(".intree-post").show();
	$(".expand-all").hide();
	$(".collapse-all").show();
	return false;
    });

    $(".collapse-all a").click(function(){
	$(".intree-post").hide();
	$(".collapse-all").hide();
	$(".expand-all").show();
	return false;
    });

    $(".expand-all").show();
});
