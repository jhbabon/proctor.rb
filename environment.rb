$:.unshift File.dirname(__FILE__)
$:.unshift File.join(File.dirname(__FILE__), "lib")

require "bundler"
Bundler.setup(:default, ENV["RACK_ENV"].to_s)

require "dotenv"
Dotenv.overload(*%W(.env .env.#{ENV["RACK_ENV"]}))
