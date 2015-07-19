require "./environment"

require "sinatra"
require "sinatra/activerecord"
require "oj"

set :database, ENV["PROCTOR_DATABASE_URL"]

helpers do

  # Public: Return a JSON response by setting up the correct Content-Type
  # header and transforming the given argument to a JSON String.
  #
  # payload - Hash to convert. They keys MUST be Strings.
  #
  # Returns a valid JSON String.
  def json(payload)
    content_type :json
    Oj.dump(payload)
  end
end


# Actions
get "/" do
  payload = {
    "hello" => "world!",
    "env"   => ENV["RACK_ENV"],
  }

  json payload
end
