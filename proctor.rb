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

def users_path
  "/users"
end

def user_path(name = ":name")
  join_paths users_path, name
end

def user_pubkeys_path(user = ":name")
  join_paths user_path(user), "pubkeys"
end

def user_pubkey_path(user = ":name", title = ":title")
  join_paths user_pubkeys_path(user), title
end

def join_paths(*paths)
  paths.join("/")
end

before user_path(":name*") do
  @user = User.find_by(:name => params["name"])
  halt 404 if @user.nil?
end

before user_pubkey_path(":name", ":title*") do
  @pubkey = @user.pubkeys.find_by(:title => params["title"])
  halt 404 if @pubkey.nil?
end

get "/" do
  "Hello world!"
end

get users_path, :provides => :json do
  json User.order(:name).map(&:as_api)
end

get user_path, :provides => :json do
  json @user.as_api
end

post users_path do
  user = User.new
  user.from_api(parse_body)

  if user.save
    status 201
    headers "Location" => to(user_path(user.name))

    json user.as_api
  else
    status 422 # TODO: check correct error value

    json({ "errors" => user.errors.full_messages })
  end
end

patch user_path do
  @user.from_api(parse_body)

  if @user.save
    headers "Location" => to(user_path(@user.name))

    json @user.as_api
  else
    status 422 # TODO: check correct error value

    json({ "errors" => @user.errors.full_messages })
  end
end

delete user_path do
  @user.destroy

  status 204
end

get user_pubkeys_path do
  json @user.pubkeys.order(:title).map(&:as_api)
end

get user_pubkey_path do
  json @pubkey.as_api
end

post user_pubkeys_path do
  pubkey = @user.pubkeys.new
  pubkey.from_api(parse_body)

  if pubkey.save
    status 201
    headers "Location" => to(user_pubkey_path(@user.name, pubkey.title))

    json pubkey.as_api
  else
    status 422 # TODO: check correct error value

    json({ "errors" => pubkey.errors.full_messages })
  end
end

patch user_pubkey_path do
  @pubkey.from_api(parse_body)

  if @pubkey.save
    headers "Location" => to(user_pubkey_path(@user.name, @pubkey.title))

    json @pubkey.as_api
  else
    status 422 # TODO: check correct error value

    json({ "errors" => @pubkey.errors.full_messages })
  end
end

delete user_pubkey_path do
  @pubkey.destroy

  status 204
end
