class Post < ActiveRecord::Base

  LANGUAGES = %w[Markdown].freeze

  validates :content, :presence => true
  validates :language, :presence => true, :inclusion => { :in => LANGUAGES }

end
