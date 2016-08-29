$(document).ready(function(){

    // Event handler in the forum index view for deleting forums
    $(".delete-forum").click(function(){
	var id = $(this).attr("data-id");

	jQuery.ajax({
	    url: "/admin/forums/" + id,
	    method: "DELETE",
	    success: function() {
		$("tr#forum-" + id).remove();
	    },
	    error: function() {
		alert("Removal failed.");
	    }
	});

	return false;
    });
});
