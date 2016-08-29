$(document).ready(function(){
    // Handler for progress display
    sync_timer_id = null; // global
    function check_sync_progress(){
	jQuery.ajax({
	    url: "/admin/forums/" + $("#sync_progress").attr("data-id") + "/synchronize",
	    method: "GET",
	    dataType: "json",
	    statusCode: {
		202: function(data) {
		    $("#sync_progress").text(data.str);
		},
		200: function(data) {
		    $("#sync_progress").text(data.str);
		    window.clearInterval(sync_timer_id);
		}
	    },
	    error: function() {
		$("#sync_progress").html("Failed to synchronize!");
	    }
	});
    }

    sync_timer_id = window.setInterval(check_sync_progress, 1000);
});
