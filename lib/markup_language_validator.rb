class MarkupLanguageValidator < ActiveModel::EachValidator

  def validate_each(record, attribute, value)
    return if value == Post::DEFAULT_MARKUP_LANGUAGE

    unless Chessboard::Plugin.plugin_markup_languages.find{|m| m.name == value}
      record.errors.add(attribute, I18n.t("errors.post.markup_language", :lang => value))
    end
  end

end
