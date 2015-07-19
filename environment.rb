require "bundler"
Bundler.setup(:default, ENV["RACK_ENV"])


require "dotenv"
Dotenv.load
