require "./environment"

require "sinatra"
require "sinatra/activerecord"
require "oj"

configure do
  set :database, ENV["PROCTOR_DATABASE_URL"]
end

require "user"

helpers do

  # Public: Return a JSON response by setting up the correct Content-Type
  # header and transforming the given argument to a JSON String.
  #
  # payload - Hash or Array to convert. They keys of any Hash MUST be Strings.
  #
  # Returns a valid JSON String.
  def json(payload)
    content_type :json
    Oj.dump(payload)
  end

  # Public: Return the request body parsed from JSON.
  #
  # Returns Hash, Array or String, depends on the content
  # of the body of the request.
  def parse_body
    request.body.rewind
    Oj.load request.body.read
  end
end


get "/" do
  "Hello world!"
end

get "/users", :provides => :json do
  json User.order(:name).map(&:as_api)
end

get "/users/:name", :provides => :json do |name|
  user = User.find_by(:name => name)
  halt 404 if user.nil?

  json user.as_api
end

post "/users" do
  user = User.new
  user.from_api(parse_body)

  if user.save
    status 201
    headers "Location" => to("/users/#{user.name}")

    json user.as_api
  else
    status 422 # TODO: check correct error value

    json({ "errors" => user.errors.full_messages })
  end
end

patch "/users/:name" do |name|
  user = User.find_by(:name => name)
  halt 404 if user.nil?

  user.from_api(parse_body)

  if user.save
    headers "Location" => to("/users/#{user.name}")

    json user.as_api
  else
    status 422 # TODO: check correct error value

    json({ "errors" => user.errors.full_messages })
  end
end
