require "slug_validator"

class Team < ActiveRecord::Base
  validates :name,
    :presence   => true,
    :uniqueness => true,
    :slug       => true

  has_many :memberships
  has_many :users, :through => :memberships
  # has_many :pubkeys, :through => :users

  def as_api
    hash = as_json(only: %i(name))
    hash["users"] = users.map(&:name)

    hash
  end

  def pubkeys
    users.map(&:pubkeys).flatten
  end
end
