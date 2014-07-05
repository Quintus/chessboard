module DefaultSpamprotectPlugin
  include Chessboard::Plugin

  def hook_view_registration(options)
    content = super
    numbers = [rand(100), rand(100)]
    options[:session][:anti_spam_math] = numbers.first + numbers.last

    content += content_tag("p") do
      str = I18n.t("plugins.default_spamprotect.anti_spam_math").html_safe
      str += "<br/>".html_safe
      str += "#{numbers.first} + #{numbers.last}".html_safe
      str += "<br/>".html_safe
      str += text_field_tag "anti_spam_math"
      str
    end

    content
  end

  def hook_ctrl_registration(options)
    return false unless super

    if options[:params]["anti_spam_math"].to_i != options[:session][:anti_spam_math]
      options[:user].errors[:base] << I18n.t("plugins.default_spamprotect.anti_spam_failed")
      return false
    end

    true
  end

end
