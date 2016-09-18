$(document).ready(function(){
    $(".thread-tree-link").click(function(){
	hide_recurse($(this).parent().children("ul"));
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

/**
 * Toggle all posts until a post with multiple answers is encountered.
 * Since one cannot know which way the user wants, stop expanding
 * posts there and have him choose again.
 */
function hide_recurse(node)
{
    // Each <ul> has exactly on div.intree-post in its parent <li>.
    node.parent().children("div.intree-post").toggle();

    var child_lis = node.children("li.thread-tree-li");
    if (child_lis.length == 1) {
	// Each <li> can only ever have one <ul>.
	hide_recurse(child_lis.children("ul.thread-tree-ul"));
    }
}
