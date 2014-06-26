class Post < ActiveRecord::Base

  LANGUAGES = %w[Markdown].freeze

  validates :content, :presence => true
  validates :language, :presence => true, :inclusion => { :in => LANGUAGES }
  validates :author, :presence => true

  belongs_to :topic
  belongs_to :author, :class_name => "User"

end
