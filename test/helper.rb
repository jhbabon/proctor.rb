ENV["RACK_ENV"] = "test"

require_relative "../environment"
require "minitest/autorun"

Dir[File.join(__dir__, "support", "**", "*.rb")].each do |support|
  require support
end
