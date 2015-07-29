require "rack/auth/basic"
require "models"

# Public: Middleware to protect the app from unauthorized users.
#
# The actual HTTP headers parsing and error handling is performed
# by Rack::Auth::Basic. This middleware is called back to check if
# the username and password from the HTTP headers is valid.
#
# The validation, or authentication, is done against the database
# users. But if no user is found it fallbacks to the default system
# user. This system user is set by the following environment variables:
#
# - PROCTOR_ADMIN_USERNAME
# - PROCTOR_ADMIN_PASSWORD
#
# The reason to do the authentication this way is because once
# the user is authenticated we want to put the instance of the user
# in the rack environment so the next app in the stack will have access
# to it using the key "guard.user".
class Guard
  attr_accessor :env

  def initialize(app, system_env = ENV, realm = nil)
    @system_env = system_env
    @rack_env   = {}

    @app = auth_basic(app, realm) do |username, password|
      authenticate(username, password)
    end
  end

  def auth_basic(app, realm, &authenticator)
    Rack::Auth::Basic.new(app, realm, &authenticator)
  end

  def call(env)
    @rack_env = env

    @app.call(env)
  end

  def authenticate(username, password)
    user = find_user(username) || guardian(username)
    if user && user.authenticate(password)
      @rack_env["guard.user"] = user
      true
    end
  end

  private

  def find_user(username)
    User.find_by(:name => username)
  end

  def guardian(username)
    if username == @system_env["PROCTOR_ADMIN_USERNAME"]
      User.new(
        :name     => @system_env["PROCTOR_ADMIN_USERNAME"],
        :password => @system_env["PROCTOR_ADMIN_PASSWORD"],
        :role     => "admin",
      )
    end
  end
end
