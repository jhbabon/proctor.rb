require "models"

# Set default admin user if the users table is empty.
#
# The default user data comes from the environment variables:
#   - PROCTOR_ADMIN_USERNAME
#   - PROCTOR_ADMIN_PASSWORD
class Bootstrap
  def self.run(env)
    new(env).run
  end

  def initialize(env = ENV)
    @env = env
  end

  def run
    seed unless test? || has_users?
  end

  def test?
    @env["RACK_ENV"] == "test"
  end

  def has_users?
    User.exists?
  end

  def seed
    username = @env["PROCTOR_ADMIN_USERNAME"]
    password = @env["PROCTOR_ADMIN_PASSWORD"]

    $stdout.puts "==> Creating admin user: #{username}!"

    User.create(
      :name     => username,
      :password => password,
      :role     => "admin"
    )
  end
end
