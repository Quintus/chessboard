/**
 * Replace the text in `string` startig at `start_index` and ending
 * at `start_index + length` with the text `string_to_insert` and return
 * the result as a new string.
 */
function replace_in_string(string, start_index, length, string_to_insert)
{
    return string.substring(0, start_index) + string_to_insert + string.substring(start_index + length);
}

/**
 * Returns a new string that is broken at the specified column width,
 * if possible. It is not possible if there is no whitespace in the
 * given line.
 */
function wrap_line(line, column_width)
{
    var i = 0;
    var cur_line_len = 0;
    var result = "";

    // Iterate all characters in the string and insert newlines in
    // place of spaces if the line gets too long.
    for(i=0; i < line.length; i++, cur_line_len++) {
	var letter = line.charAt(i);
	if (cur_line_len >= column_width && letter == " ") {
	    result += "\n";
	    cur_line_len = 0;
	}
	else {
	    result += letter;
	}
    }

    return result;
}

/**
 * Returns true if the given key code (as returned by `event.which`)
 * is a character that causes a textarea's value to change. This will
 * be the case for all letters and not the case for most control characters,
 * with the notable exception of backspace and delete, which will cause this
 * method to return true when encountered (as they affect the text value).
 */
function is_text_code(code)
{
    // JQuery docs say this value is normalised between
    // browsers (http://api.jquery.com/keyup/).
    switch(code) {
    case 27: // ESC
    case 20: // Capslock
    case 16: // Shift
    case 17: // CTRL
    case 91: // Windows key
    case 18: // ALT
    case 225: // ALT GR (ISO-LEVEL3-SHIFT)
    case 37: // Arrow left
    case 40: // Array down
    case 39: // Array right
    case 38: // Arrow up
    case 33: // Page up
    case 34: // Page down
    case 36: // Pos1
    case 35: // End
    case 145: // Scroll lock
    case 42: // Print
    case 19: // Pause
	return false; // Fall-through intended.
    default:
	return true;
    }
}

$(document).ready(function(){
    $("#automatic_line_breaks_container").show();

    // Try to match this column length.
    var target_column_width = 60;

    // This event handler will only work with IE >= 9. I'll accept
    // this for now; IE < 9 uses a special createRange property instead.
    $("textarea#content").keyup(function(event){
	// Only run if the textarea's content changed
	if (!is_text_code(event.which))
	    return;

	// Only run if enabled
	if ($(this).parent().parent().find("input#automatic_line_breaks:checked").length > 0) {
	    // Get text upto the caret position
	    var text = this.value.substring(0, this.selectionStart);
	    var original_pos = this.selectionStart;

	    // Include rest of the current line (i.e. extend text to everything up
	    // to the end of the current line).
	    var index = this.selectionStart;
	    while (this.value.charAt(index) != "\n" && index < this.value.length)
		index++;
	    text += this.value.substring(this.selectionStart, index);

	    // Store end of line for later
	    var end_of_line = index - 1; // Exclude newline and EOS

	    ////////////////////////////////////////
	    // Determine the current line by going back until either the beginning
	    // of the string or a newline if found.
	    index = text.length - 1;
	    while (text.charAt(index) != "\n" && index > 0)
		index--;

	    // Store beginning of line for later
	    var beginning_of_line = null;
	    if (index == 0)
		beginning_of_line = 0;
	    else
		beginning_of_line = index + 1; // Exclude leading newline

	    var line = text.substring(beginning_of_line);

	    ////////////////////////////////////////
	    // If the line is short enough anyway, do nothing.
	    if (line.length < target_column_width)
		return;

	    ////////////////////////////////////////
	    // Exclude indented codeblocks.
	    if (line.charAt(0) == "\t" || line.substring(0, 3) == "   ")
		return;

	    ////////////////////////////////////////
	    /* Find out whether the caret is inside a fenced
	     * codeblock. In that case, do not apply automatic line
	     * breaking. The detection is done by looking at the
	     * number of tilde lines and the assumption that an odd
	     * number of those means a codeblock is open. This will
	     * fail on nested tilde lines (which are rare enough to
	     * allow failure).. */
	    var tilde_regexp = /^~{3,}/mg;
	    var tilde_line_count = 0;

	    while (tilde_regexp.test(text))
		tilde_line_count++;
	    if (tilde_line_count % 2 != 0)
		return;

	    ////////////////////////////////////////
	    // Also exclude backticked codeblocks
	    var backtick_regexp = /^`{3,}/mg;
	    var backtick_line_count = 0;

	    while (backtick_regexp.test(text))
		backtick_line_count++;
	    if (backtick_line_count % 2 != 0)
		return;

	    ////////////////////////////////////////
	    // Wrap line
	    var wrapped_line = wrap_line(line, target_column_width);

	    text = replace_in_string(this.value, beginning_of_line, line.length, wrapped_line);

	    // Replace content of textarea and re-adjust caret to end of the result
	    // so the user can continue typing. Note: wrap_line() does not change
	    // the number of characters in the textarea, it just replace a space with a newline;
	    // hence the caret position does not have to be recalculated.
	    this.value = text;
	    this.setSelectionRange(original_pos, original_pos);
	}
    });
});
