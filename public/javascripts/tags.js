$(document).ready(function(){

    // Event handler in the tag index view for deleting tags
    $(".delete-tag").click(function(){
	var id = $(this).attr("data-id");

	jQuery.ajax({
	    url: "/admin/tags/" + id,
	    method: "DELETE",
	    success: function() {
		$("tr#tag-" + id).remove();
	    },
	    error: function() {
		alert("Removal failed.");
	    }
	});

	return false;
    });

    // Event handler in the tag edit/new view for displaying the color
    $("#tag-color-input").keyup(function(){
	$(this).css("background-color", "#" + $(this).val());
    });
});
