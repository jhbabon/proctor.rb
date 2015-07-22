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

  # Public: check if a User is in the scope of a role.
  # The scopes of the roles go like this:
  #
  #   admin > user > guest
  #
  # E.g: If a User is admin, is going to be always true. If the user is
  # a guest, is going to be true only if the check role is guest.
  #
  # check - Symbol or String with the name of the role to check.
  #
  # Returns true if the user is an admin.
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
    as_json(only: %i(name role))
  end

  def from_api(hash)
    self.attributes = hash
    self
  end
end
