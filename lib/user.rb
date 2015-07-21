require "slug_validator"

class User < ActiveRecord::Base
  validates :name,
    :presence   => true,
    :uniqueness => true,
    :slug       => true

  has_many :pubkeys
  has_many :memberships
  has_many :teams, :through => :memberships

  def as_api
    as_json(only: %i(name))
  end

  def from_api(hash)
    self.attributes = hash
    self
  end
end
