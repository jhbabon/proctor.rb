require "active_model"

# Public: Validate if an attribute has the correct format
# to be a slug, a String part of a path segment in an URI.
class SlugValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless value =~ /\A(?:[a-z]|_|-|\d)*\z/
      record.errors[attribute] << (options[:message] || "is not a valid uri segment")
    end
  end
end
