class Warning < ActiveRecord::Base
  validates :reason, :presence => true
  validates :warned_user, :presence => true
  validates :warning_user, :presence => true

  belongs_to :warned_user, :class_name => "User", :foreign_key => "warned_user_id"
  belongs_to :warning_user, :class_name => "User", :foreign_key => "warning_user_id"

  before_create do
    if GlobalConfiguration.instance.warning_expiration > 0
      self.expiration_date = Time.now + GlobalConfiguration.instance.warning_expiration
    end
  end

  # Checks if this warning is expired.
  def expired?
    # Do not expire if no expiration date is set.
    return false unless expiration_date?

    Time.now >= self.expiration_date
  end

  # Checks if this warning is expired, and if so, destroys the
  # database record and returns true. Otherwise does nothing
  # and returns false.
  def expire!
    if expired?
      destroy
      true
    else
      false
    end
  end

end
