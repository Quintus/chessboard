class Post < ActiveRecord::Base

  MARKUP_LANGUAGES = %w[BBCode Markdown].freeze

  validates :content, :presence => true
  validates :markup_language, :presence => true, :inclusion => { :in => MARKUP_LANGUAGES }
  validates :author, :presence => true

  belongs_to :topic
  belongs_to :author, :class_name => "User"

end
