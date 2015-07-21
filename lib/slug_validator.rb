require "active_model"

class SlugValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless value =~ /\A(?:[a-z]|_|-|\d)*\z/
      record.errors[attribute] << (options[:message] || "is not a valid uri segment")
    end
  end
end
