# -*- coding: utf-8 -*-
class Ban < ActiveRecord::Base

  validates :reason, :presence => true
  validate :validate_nick_pattern
  validate :validate_email_pattern
  validate :validate_ip_range

  # Checks if +user+ or +request+ match any pattern imposed
  # by any ban available in the database. Also automatically
  # deletes (and does not consider) expired bans from the
  # database.
  def self.matches_any?(user, request)
    all.each do |ban|
      # Delete expired bans and ignore them.
      if ban.expired?
        ban.destroy
        next
      end

      return true if ban.matches?(user, request)
    end

    false
  end

  # Returns true if either +user+ or +request+ match any
  # pattern this ban imposes.
  def matches?(user, request)
    return true if !nick_pattern.blank?  && user.nickname =~ Regexp.compile(nick_pattern)
    return true if !email_pattern.blank? && user.email    =~ Regexp.compile(email_pattern)
    return true if !ip_range.blank?      && IPAddr.new(ip_range).include?(request.ip)
    false
  end

  # Checks if this ban is expired and hence shouldn’t
  # be considered anymore.
  def expired?
    # Never expires if no expiration date is set.
    return false unless expiration_date?

    Time.now > expiration_date
  end

  private

  def validate_nick_pattern
    return if nick_pattern.blank?

    Regexp.compile(nick_pattern)
  rescue RegexpError => e
    errors.add(:nick_pattern, e.message)
  end

  def validate_email_pattern
    return if email_pattern.blank?

    Regexp.compile(email_pattern)
  rescue RegexpError => e
    errors.add(:email_pattern, e.message)
  end

  def validate_ip_range
    return if ip_range.blank?

    IPAddr.new(ip_range)
  rescue IPAddr::InvalidAddressError => e
    errors.add(:ip_range, e.message)
  end

end
