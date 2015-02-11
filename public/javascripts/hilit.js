$(document).ready(function(){

    var hilit = getURLParameter("hilit");
    if (hilit != null) {
	$(".post-text p").each(function(){
	    var index    = -1;
	    var lastpos = 0;
	    var contents = $(this).html();
	    var replacement = "";

	    while ((index = contents.indexOf(hilit, index + 1)) >= 0) { // Single = intended
		replacement += contents.slice(lastpos, index);

		if ((index > 0 && contents.charAt(index - 1) == "<") /* opening tag */ || /* closing tag*/ (index > 1 && contents.charAt(index - 1) == "/" && contents.charAt(index - 2) == "<")) {
		    lastpos = index;
		    continue; // This is an HTML tag. Ignore.
		}

		var endpos = index + hilit.length;
		replacement += "<span class='hilit'>" + contents.slice(index, endpos) + "</span>";

		lastpos = endpos;
	    }

	    replacement += contents.slice(lastpos); // till end
	    $(this).html(replacement);
	});
    }
});

function getURLParameter(name) {
  return decodeURIComponent((new RegExp('[?|&]' + name + '=' + '([^&;]+?)(&|#|;|$)').exec(location.search)||[,""])[1].replace(/\+/g, '%20'))||null
}
