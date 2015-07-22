require "./environment"

require "sinatra"
require "sinatra/activerecord"
require "oj"

require "models"
require "ability"
require "bootstrap"

use Rack::Auth::Basic do |username, password|
  user = User.find_by(:name => username)
  user && user.authenticate(password)
end

configure do
  set :database, ENV["PROCTOR_DATABASE_URL"]

  set :auth do |*roles|
    condition do
      halt 403 unless roles.any? { |role| current_user.in_role?(role) }
    end
  end

  set :ability do |*things|
    condition do
      things.each do |thing|
        thing = instance_variable_get(thing)
        halt 403 unless ability.can_use?(thing)
      end

      true
    end
  end

  Bootstrap.run(ENV)
end

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

  def location(url)
    headers "Location" => url
  end

  def current_user
    @current_user ||= User.find_by(:name => env["REMOTE_USER"]).tap do |user|
      halt 401 if user.nil?
    end
  end

  def ability
    @ability ||= Ability.new(current_user)
  end
end

before "/users/:name*" do
  @user = User.find_by(:name => params["name"])
  halt 404 if @user.nil?
end

before "/users/:name/pubkeys/:title*" do
  @pubkey = @user.pubkeys.find_by(:title => params["title"])
  halt 404 if @pubkey.nil?
end

before "/teams/:name*" do
  @team = Team.find_by(:name => params["name"])
  halt 404 if @team.nil?
end

get "/" do
  "Hello world!"
end

get "/users" do
  json User.order(:name).map(&:as_api)
end

get "/users/:name" do
  json @user.as_api
end

post "/users", :auth => :admin do
  user = User.new
  user.from_api(parse_body)

  if user.save
    status 201
    location to("/users/#{user.name}")

    json user.as_api
  else
    status 422 # TODO: check correct error value

    json({ "errors" => user.errors.full_messages })
  end
end

patch "/users/:name", :auth => %i(admin user), :ability => :@user do
  @user.from_api(parse_body)

  if @user.save
    location to("/users/#{@user.name}")

    json @user.as_api
  else
    status 422 # TODO: check correct error value

    json({ "errors" => @user.errors.full_messages })
  end
end

delete "/users/:name", :auth => %i(admin user), :ability => :@user do
  @user.destroy

  status 204
end

get "/users/:name/pubkeys" do
  json @user.pubkeys.order(:title).map(&:as_api)
end

get "/users/:name/pubkeys/:title" do
  json @pubkey.as_api
end

post "/users/:name/pubkeys", :auth => %i(admin user), :ability => :@user do
  pubkey = @user.pubkeys.new
  pubkey.from_api(parse_body)

  if pubkey.save
    status 201
    location to("/users/#{@user.name}/pubkeys/#{pubkey.title}")

    json pubkey.as_api
  else
    status 422 # TODO: check correct error value

    json({ "errors" => pubkey.errors.full_messages })
  end
end

patch "/users/:name/pubkeys/:title", :auth => %i(admin user), :ability => :@pubkey do
  @pubkey.from_api(parse_body)

  if @pubkey.save
    location to("/users/#{@user.name}/pubkeys/#{@pubkey.title}")

    json @pubkey.as_api
  else
    status 422 # TODO: check correct error value

    json({ "errors" => @pubkey.errors.full_messages })
  end
end

delete "/users/:name/pubkeys/:title", :auth => %i(admin user), :ability => :@pubkey do
  @pubkey.destroy

  status 204
end

get "/users/:name/teams" do
  json @user.teams.map { |team| team.as_json(only: :name) }
end

get "/teams" do
  json Team.all.map(&:as_api)
end

get "/teams/:name" do
  json @team.as_api
end

patch "/teams/:name", :auth => :admin do
  @team.attributes = parse_body

  if @team.save
    location to("/teams/#{@team.name}")

    json @team.as_api
  else
    status 422 # TODO: check correct error value

    json({ "errors" => @team.errors.full_messages })
  end
end

delete "/teams/:name", :auth => :admin do
  @team.destroy

  status 204
end

get "/teams/:name/users" do
  json @team.users.map(&:as_api)
end

get "/teams/:name/pubkeys" do
  json @team.pubkeys.map(&:as_api)
end

post "/memberships", :auth => :admin do
  membership = Membership.link(parse_body)

  if membership.valid?
    status 201
    location to("/teams/#{membership.team.name}")
  else
    status 422 # TODO: check correct error value

    json({ "errors" => membership.errors.full_messages })
  end
end

delete "/memberships", :auth => :admin do
  Membership.unlink(parse_body)

  status 204
end
