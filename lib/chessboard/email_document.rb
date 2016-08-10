# A subclass of Kramdown::Document that preprocesses the string
# passed to ::new to strip it from certain email slang that
# is not valid markdown. After this preprocessing, the resulting
# string is regularyly passed to kramdown.
class Chessboard::EmailDocument < Kramdown::Document

  # Set this to true to get ::new output the pre- and postprocessing
  # results to standard output.
  def self.debug_preprocessor=(val)
    @debug_preprocessor = val
  end

  # Returns the value set with ::debug_preprocessor=.
  def self.debug_preprocessor?
    @debug_preprocessor ||= false
  end

  # Create a new instance of this class. Arguments are
  # like with Kramdown::Document.new.
  def initialize(str, *args)
    if self.class.debug_preprocessor?
      puts ">>>>>>>>> Pre <<<<<<<<<"
      puts str
      puts ">>>>>>>>> End Pre <<<<<<<<<"
    end

    str = preprocess(str)

    if self.class.debug_preprocessor?
      puts ">>>>>>>>> Post <<<<<<<<<"
      puts str
      puts ">>>>>>>>> End Post <<<<<<<<<"
    end

    super(str, *args)
  end

  private

  def preprocess(str)
    str = str.dup

    # Remove emailish newlines (breaks regular expressions using only \n)
    str.gsub!("\r\n", "\n")

    # Remove inline PGP. We cannot usefully include it because we
    # display the mail signature as a distinct element. This does not
    # hurt because people can still view the raw content if they want
    # to verify the signature.
    str.sub!(/^(\-+)BEGIN PGP SIGNED MESSAGE\1.*?\n\n(.*)\1BEGIN PGP SIGNATURE\1.*\1END PGP SIGNATURE\1$/m) do
      "[ PGP inline signed message; view raw format to verify the signature ]\n{:.pgp-inline}\n\n#$2"
    end

    # Cut off signature and ensure it always is a code block.
    # The signature is appended later again.
    # (many people use ASCII art in their signature).
    str.sub!(/^-- ?$(.*)\z/m, "")
    signature = $1 ? "\n\n~~~~~~~~~~\n#{$1.strip}\n~~~~~~~~~~\n{:.signature}" : ""

    # Fix links not surrounded with angle brackets.
    # Link reference definitions need to be excluded.
    str.gsub!(/(?<!\]:)([^<])(http|https|ftp):\/\/(.+)([^>])/, '\1<\2://\3>\4')

    # Obsure email addresses
    str.gsub!(/@[a-z0-9\.]+?\.\w+/i, "@xxxxxxxxxx")

    # Email quotes often come directly after the "on xy, abc wrote:" or similar
    # origin line without a space. That's invalid markdown (making parsers not
    # recognise that as a quote), so fix it by inserting the missing newline.
    newstr = ""
    lines = str.lines
    lines.each_with_index do |line, index|
      if line.start_with?(">")
        if !lines[index-1].strip.empty? && !lines[index-1].start_with?(">")
          newstr << "\n" << line
        else
          newstr << line
        end
      else
        newstr << line
      end
    end

    # Center lines with more than 4 spaces at the beginning, unless
    # preceeded by a line with 4 spaces.
    str = newstr
    newstr = ""
    encountered_4_spaces = false
    str.lines.each do |line|
      if line =~ /^( {4,})(.*)$/
        if $1.length == 4
          encountered_4_spaces = true
        else
          if encountered_4_spaces
            newstr << line
          else
            newstr << "#{line.strip}\n{:.center}\n\n"
          end
          next
        end
      else
        encountered_4_spaces = false
      end

      newstr << line
    end

    str = newstr
    newstr = ""

    # Ensure links on footer are referenced with proper colons, otherwise
    # it is invalid markdown.
    str.lines.each do |line|
      if line =~ /^\[(\d)\][^:]\s?((http:|https:|ftp:).*)$/
        newstr << "[#$1]: #$2\n"
      else
        # Fix incomplete references
        newstr << line.gsub(/([^\[\]\s]+)\[(\d+)\]/, '[\1][\2]')
      end
    end

    newstr = newstr + signature
  end

end
