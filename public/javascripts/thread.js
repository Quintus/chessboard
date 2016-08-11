$(document).ready(function(){
    $(".thread-tree-link").click(function(){
	$(this).parent().children(".intree-post").toggle();
	return false;
    });
});
