module MentionPlugin
  include Chessboard::Plugin

  def hook_hlpr_post_markup(options)
    result = super

    #result.scan(/(?:^|\s)@([[:alnum:]]+)/) do |ary|

    result.gsub(/(^|\s)(@[[:alnum:]]+)/) do
      "#$1<strong class='mention'>#$2</strong>"
    end
  end

end
