class User < ActiveRecord::Base
  validates :name,
    :presence   => true,
    :uniqueness => true,
    :format     => { :with => /\A(?:[a-z]|_|-|\d)*\z/ }

  def as_api
    as_json(only: %i(name))
  end

  def from_api(hash)
    self.attributes = hash
    self
  end
end
