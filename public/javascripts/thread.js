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

    $("a.delete-post").click(function(){
	var post = $(this).parents(".post");

	jQuery.ajax({
	    url: $(this).attr("href"),
	    method: "DELETE",
	    success: function(){
		post.remove();
	    },
	    error: function() {
		alert("Deletion failed.");
	    }
	});

	return false;
    });
});
