ENV["RACK_ENV"] = "test"

require_relative "../environment"
require "minitest/autorun"

require_relative "./support/active_record"
