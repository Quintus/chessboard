# -*- coding: utf-8 -*-
class Settings < ActiveRecord::Base

  validates :user, :presence => true
  validates :preferred_markup_language, :presence => true, :inclusion => {:in => Post::MARKUP_LANGUAGES}
  validates :language, :inclusion => { :in => I18n.available_locales.map(&:to_s) }

  belongs_to :user

end
