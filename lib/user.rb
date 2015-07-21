require "slug_validator"
require "pubkey"

class User < ActiveRecord::Base
  validates :name,
    :presence   => true,
    :uniqueness => true,
    :slug       => true

  has_many :pubkeys

  def as_api
    as_json(only: %i(name))
  end

  def from_api(hash)
    self.attributes = hash
    self
  end
end
