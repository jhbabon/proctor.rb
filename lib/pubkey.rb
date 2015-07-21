require "slug_validator"
require "user"

class Pubkey < ActiveRecord::Base
  validates :key, :presence => true
  validates :title,
    :presence   => true,
    :uniqueness => { :scope => :user_id },
    :slug       => true

  belongs_to :user

  def as_api
    as_json(only: %i(title key))
  end

  def from_api(hash)
    self.attributes = hash
    self
  end
end
