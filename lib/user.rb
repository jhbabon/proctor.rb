require "slug_validator"

class User < ActiveRecord::Base
  ROLES = %w(admin user guest)

  has_secure_password

  validates :name,
    :presence   => true,
    :uniqueness => true,
    :slug       => true
  validates :role,
    :presence  => true,
    :inclusion => { :in => ROLES }

  has_many :pubkeys
  has_many :memberships
  has_many :teams, :through => :memberships

  def in_role?(check)
    check = check.to_s

    case self.role
    when "admin"
      true
    when "user"
      %w(guest user).include?(check)
    when "guest"
      check == "guest"
    end
  end

  def admin?
    role == "admin"
  end

  def guest?
    role == "guest"
  end

  def as_api
    as_json(only: %i(name))
  end

  def from_api(hash)
    self.attributes = hash
    self
  end
end
