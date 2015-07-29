require "./environment"

require "sinatra"
require "sinatra/activerecord"
require "oj"

require "models"
require "ability"
require "guard"

use Guard, ENV

configure do
  set :database, ENV["PROCTOR_DATABASE_URL"]

  # Public: Authorize routes based on the current user role
  #
  # Examples
  #
  #   get "/stuff", :auth => [:admin, :guest]
  #
  # If the user doesn't belong to the role the app stops
  # with 403 (Forbidden) error.
  set :auth do |*roles|
    condition do
      halt 403 unless roles.any? { |role| current_user.in_role?(role) }
    end
  end

  # Check if the current user has the ability to use an object.
  # The object must be in an instace variable.
  #
  # Examples
  #
  #   get "/my/stuff", :ability => :@saved_stuff
  #
  # If the user can't use the variable the app stops
  # with 403 (Forbidden) error.
  set :ability do |*things|
    condition do
      things.each do |thing|
        thing = instance_variable_get(thing)
        halt 403 unless ability.can_use?(thing)
      end

      true
    end
  end
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

  # Public: Set the url as the Location HTTP header.
  #
  # url - String with the url for the location.
  #
  # Returns nothing.
  def location(url)
    headers "Location" => url
  end

  # Public: Get the current user using the app. Because the user was authenticated
  # by Rack::Auth::Basic, the name is set in the env["REMOTE_USER"] key.
  #
  # Returns the current User or stops with 401 if not found.
  def current_user
    @current_user ||= env["guard.user"].tap do |user|
      halt 401 if user.nil?
    end
  end

  # Public: Get the ability of the current_user
  #
  # Returns Ability.
  def ability
    @ability ||= Ability.new(current_user)
  end

  # Public: Set the response to 422 for not valid records.
  #
  # record - Any ActiveRecord::Base instance.
  #
  # Returns the errors of the record as a JSON response.
  def unprocessable_entity(record)
    status 422
    errors = { "errors" => record.errors.full_messages }

    json errors
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
  info = {
    "users"   => User.count,
    "pubkeys" => Pubkey.count,
    "teams"   => Team.count,
  }

  json info
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
    unprocessable_entity user
  end
end

patch "/users/:name", :auth => %i(admin user), :ability => :@user do
  attributes = parse_body
  halt 403 if attributes.key?("role") && !current_user.admin?

  @user.from_api(attributes)

  if @user.save
    location to("/users/#{@user.name}")

    json @user.as_api
  else
    unprocessable_entity @user
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
    unprocessable_entity pubkey
  end
end

patch "/users/:name/pubkeys/:title", :auth => %i(admin user), :ability => :@pubkey do
  @pubkey.from_api(parse_body)

  if @pubkey.save
    location to("/users/#{@user.name}/pubkeys/#{@pubkey.title}")

    json @pubkey.as_api
  else
    unprocessable_entity @pubkey
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
    unprocessable_entity @team
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
    unprocessable_entity membership
  end
end

delete "/memberships", :auth => :admin do
  Membership.unlink(parse_body)

  status 204
end
