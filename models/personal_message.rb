class PersonalMessage < ActiveRecord::Base

  validates :title, :presence => true
  validates :author, :presence => true
  validate :author_is_allowed?
  validate :has_recipient?

  has_many :posts, :class_name => "PersonalPost"
  belongs_to :author, :class_name => "User"

  has_and_belongs_to_many :users_who_read_this, :class_name => "User", :join_table => "read_pms"

  # Note this also includes the author.
  has_and_belongs_to_many :allowed_users, :class_name => "User", :join_table => :pm_access

  before_validation :ensure_author_is_allowed

  # Returns a list of all recipients excluding the author
  # of the PM, sorted in ascending order of their nicknames.
  def recipients
    allowed_users.where.not("users.id = ?", author.id).order(:nickname => :asc)
  end

  private

  def ensure_author_is_allowed
    allowed_users << author unless author_is_allowed?
  end

  def author_is_allowed?
    allowed_users.include?(author)
  end

  def has_recipient?
    if allowed_users.length <= 1 # Author is not self-recipient
      errors.add(:allowed_users, I18n.t("errors.pm.missing_recipient"))
    end
  end

end
