require "slug_validator"

class Pubkey < ActiveRecord::Base
  validates :key, :presence => true
  validates :title,
    :presence   => true,
    :uniqueness => { :scope => :user_id },
    :slug       => true

  belongs_to :user

  def full_title
    "#{user.name}@#{title}"
  end

  def as_api
    {
      "title" => full_title,
      "key"   => key,
    }
  end

  def from_api(hash)
    self.attributes = hash
    self
  end
end
