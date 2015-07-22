ENV["RACK_ENV"] = "test"

require_relative "../environment"
require "factory_girl"
require "minitest/autorun"

Dir[File.join(__dir__, "support", "**", "*.rb")].each do |support|
  require support
end

FactoryGirl.find_definitions
