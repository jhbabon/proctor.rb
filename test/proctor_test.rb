require "helper"
require "rack/test"
require "proctor"

class ProctorTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    authorize :admin
  end

  def test_root
    get "/", {}, "HTTP_CONTENT_TYPE" => "application/json"

    assert_status 200
    assert_equal "Hello world!", last_response.body
  end

  def test_get_users_ordered_by_name
    FactoryGirl.create(:user, :flash)
    FactoryGirl.create(:user, :batman)

    get "/users"

    actual = parsed_response

    assert_status 200
    assert_equal "batman", actual[0]["name"]
    assert_equal "flash", actual[1]["name"]
  end

  def test_get_user_with_wrong_name
    get "/users/missing"

    assert_status 404
  end

  def test_get_user_with_existing_name
    FactoryGirl.create(:user, :batman)

    get "/users/batman"

    assert_status 200
    assert_equal parsed_response["name"], "batman"
  end

  def test_create_user
    post "/users", to_json({ "name" => "batman", "password" => "secret", "role" => "user" })

    assert_status 201
    assert_location(/\/users\/batman\z/)
  end

  def test_create_user_for_non_admins
    %i(user guest).each do |role|
      authorize role

      post "/users", to_json({ "name" => "batman", "password" => "secret", "role" => "user" })

      assert_status 403
    end
  end

  def test_create_user_with_exising_name
    FactoryGirl.create(:user, :batman)

    post "/users", to_json({ "name" => "batman" })

    assert_status 422
  end

  def test_update_missing_user
    patch "/users/robin", to_json({ "name" => "batman" })

    assert_status 404
  end

  def test_update_user
    FactoryGirl.create(:user, :robin)

    patch "/users/robin", to_json({ "name" => "batman" })

    assert_status 200
    assert_location(/\/users\/batman\z/)
  end

  def test_user_updates_itself
    robin = FactoryGirl.create(:user, :robin)
    authorize robin

    patch "/users/robin", to_json({ "name" => "batman" })

    assert_status 200
    assert_location(/\/users\/batman\z/)
  end

  def test_update_user_for_other_user
    %i(user guest).each do |role|
      authorize role

      user = FactoryGirl.create(:user)

      patch "/users/#{user.name}", to_json({ "name" => "batman" })

      assert_status 403
    end
  end

  def test_update_user_with_existing_name
    FactoryGirl.create(:user, :robin)
    FactoryGirl.create(:user, :batman)

    patch "/users/robin", to_json({ "name" => "batman" })

    assert_status 422
  end

  def test_delete_existing_user
    FactoryGirl.create(:user, :batman)

    delete "/users/batman"

    assert_status 204
    assert_nil User.find_by(:name => "batman")
  end

  def test_user_deletes_itself
    batman = FactoryGirl.create(:user, :batman)
    authorize batman

    delete "/users/batman"

    assert_status 204
    assert_nil User.find_by(:name => "batman")
  end

  def test_user_deletes_other_user
    %i(user guest).each do |role|
      authorize role
      user = FactoryGirl.create(:user)

      delete "/users/#{user.name}"

      assert_status 403
    end
  end

  def test_delete_missing_user
    delete "/users/clayface"

    assert_status 404
  end

  def test_get_user_teams
    FactoryGirl.create(:user, :green_lantern)
    Membership.link("user" => "green-lantern", "team" => "corps")

    get "/users/green-lantern/teams"

    assert_status 200

    actual = parsed_response

    assert_equal 1, actual.size
    assert_equal "corps", actual.first["name"]
  end

  def test_create_pubkey
    user = FactoryGirl.create(:user, :batman)
    assert_difference -> { user.reload.pubkeys.count } do
      key = fixture_content("id_rsa.pub")
      payload = {
        "title" => "testkey",
        "key"   => key,
      }
      post "/users/batman/pubkeys", to_json(payload)

      assert_status 201
      assert_match(
        /\/users\/batman\/pubkeys\/testkey\z/,
        last_response.headers["Location"]
      )
    end
  end

  def test_user_creates_pubkey_by_itself
    user = FactoryGirl.create(:user, :batman)
    authorize user

    assert_difference -> { user.reload.pubkeys.count } do
      key = fixture_content("id_rsa.pub")
      payload = {
        "title" => "testkey",
        "key"   => key,
      }
      post "/users/batman/pubkeys", to_json(payload)

      assert_status 201
      assert_match(
        /\/users\/batman\/pubkeys\/testkey\z/,
        last_response.headers["Location"]
      )
    end
  end

  def test_user_creates_pubkey_for_other_user
    %i(user guest).each do |role|
      authorize role

      user = FactoryGirl.create(:user)

      post "/users/#{user.name}/pubkeys"

      assert_status 403
    end
  end

  def test_update_pubkey
    key = fixture_content("id_rsa.pub")
    user = FactoryGirl.create(:user, :batman)
    user.pubkeys.create(:title => "batkey", :key => key)

    payload = { "key" => fixture_content("id_rsa_v2.pub") }

    patch "/users/batman/pubkeys/batkey", to_json(payload)

    assert_status 200
  end

  def test_user_update_pubkey_by_itself
    key = fixture_content("id_rsa.pub")
    user = FactoryGirl.create(:user, :batman)
    authorize user

    user.pubkeys.create(:title => "batkey", :key => key)

    payload = { "key" => fixture_content("id_rsa_v2.pub") }

    patch "/users/batman/pubkeys/batkey", to_json(payload)

    assert_status 200
  end

  def test_user_updates_pubkey_from_other_user
    %i(user guest).each do |role|
      authorize role

      user = FactoryGirl.create(:user)
      user.pubkeys.create(:title => "batkey", :key => "test")

      payload = { "key" => "test-2" }

      patch "/users/#{user.name}/pubkeys/batkey", to_json(payload)

      assert_status 403
    end
  end

  def test_update_missing_key
    FactoryGirl.create(:user, :batman)
    payload = { "key" => fixture_content("id_rsa_v2.pub") }

    patch "/users/batman/pubkeys/batkey", to_json(payload)

    assert_status 404
  end

  def test_get_one_user_pubkey
    key = fixture_content("id_rsa.pub")
    user = FactoryGirl.create(:user, :batman)
    user.pubkeys.create(:title => "batkey", :key => key)

    get "/users/batman/pubkeys/batkey"

    actual = parsed_response

    assert_status 200
    assert_equal "batkey", actual["title"]
    assert_equal key, actual["key"]
  end

  def test_get_missing_pubkey
    FactoryGirl.create(:user, :batman)
    get "/users/batman/pubkeys/batkey"

    assert_status 404
  end

  def test_get_user_pubkeys
    user = FactoryGirl.create(:user, :batman)

    key_b = fixture_content("id_rsa_v2.pub")
    key_a = fixture_content("id_rsa.pub")
    user.pubkeys.create(:title => "key_b", :key => key_b)
    user.pubkeys.create(:title => "key_a", :key => key_a)

    get "/users/batman/pubkeys"

    actual = parsed_response

    assert_status 200
    assert_equal 2, actual.size
    assert_equal "key_a", actual.first["title"]
    assert_equal key_a, actual.first["key"]
    assert_equal "key_b", actual.last["title"]
    assert_equal key_b, actual.last["key"]
  end

  def test_delete_user_pubkey
    key = fixture_content("id_rsa.pub")
    user = FactoryGirl.create(:user, :batman)
    user.pubkeys.create(:title => "batkey", :key => key)

    delete "/users/batman/pubkeys/batkey"

    assert_status 204
    assert_nil Pubkey.find_by(:title => "batkey")
  end

  def test_user_deletes_pubky_by_itself
    key = fixture_content("id_rsa.pub")
    user = FactoryGirl.create(:user, :batman)
    authorize user

    user.pubkeys.create(:title => "batkey", :key => key)

    delete "/users/batman/pubkeys/batkey"

    assert_status 204
    assert_nil Pubkey.find_by(:title => "batkey")
  end

  def test_delete_user_pubkey_for_other_user
    %i(user guest).each do |role|
      authorize role

      user = FactoryGirl.create(:user)
      user.pubkeys.create(:title => "batkey", :key => "test")

      delete "/users/#{user.name}/pubkeys/batkey"

      assert_status 403
    end
  end

  def test_create_membership
    FactoryGirl.create(:user, :batman)
    FactoryGirl.create(:team, :jla)

    payload = { "user" => "batman", "team" => "jla" }

    assert_difference -> { Membership.count } do
      post "/memberships", to_json(payload)

      assert_status 201
      assert_location(/\/teams\/jla\z/)
    end
  end

  def test_create_membership_for_non_admins
    %i(user guest).each do |role|
      authorize role

      user = FactoryGirl.create(:user)
      team = FactoryGirl.create(:team)

      payload = { "user" => user.name, "team" => team.name }

      assert_difference -> { Membership.count }, 0 do
        post "/memberships", to_json(payload)

        assert_status 403
      end
    end
  end

  def test_delete_membership
    FactoryGirl.create(:user, :batman)
    FactoryGirl.create(:team, :jla)
    Membership.link("user" => "batman", "team" => "jla")

    payload = { "user" => "batman", "team" => "jla" }

    assert_difference -> { Membership.count }, -1 do
      delete "/memberships", to_json(payload)

      assert_status 204
    end
  end

  def test_delete_membership_for_non_admins
    %i(user guest).each do |role|
      authorize role

      user = FactoryGirl.create(:user)
      team = FactoryGirl.create(:team)
      Membership.link("user" => user.name, "team" => team.name)

      payload = { "user" => user.name, "team" => team.name }

      payload = { "user" => "batman", "team" => "jla" }

      assert_difference -> { Membership.count }, 0 do
        delete "/memberships", to_json(payload)

        assert_status 403
      end
    end
  end

  def test_get_teams
    FactoryGirl.create(:team, :jla)
    FactoryGirl.create(:team, :xmen)

    get "/teams"

    assert_status 200

    actual = parsed_response
    assert_equal 2, actual.size
    assert_equal "jla", actual.first["name"]
    assert_equal "x-men", actual.last["name"]
  end

  def test_get_team
    FactoryGirl.create(:team, :jla)

    get "/teams/jla"

    assert_status 200

    actual = parsed_response
    assert_equal "jla", actual["name"]
  end

  def test_get_missing_team
    get "/teams/empire"

    assert_status 404
  end

  def test_update_team
    team = FactoryGirl.create(:team, :jla)

    payload = { "name" => "jsa" }

    patch "/teams/jla", to_json(payload)

    assert_status 200
    assert_equal "jsa", team.reload.name
  end

  def test_update_team_for_non_admins
    %i(user guest).each do |role|
      authorize role

      team = FactoryGirl.create(:team)

      payload = { "name" => "jsa" }

      patch "/teams/#{team.name}", to_json(payload)

      assert_status 403
    end
  end

  def test_update_missing_team
    patch "/teams/empire", to_json({ "name" => "rebels" })

    assert_status 404
  end

  def test_delete_team
    FactoryGirl.create(:team, :jla)

    delete "/teams/jla"

    assert_status 204
    assert_nil Team.find_by(:name => "jla")
  end

  def test_delete_team_for_non_admins
    %i(user guest).each do |role|
      authorize role

      team = FactoryGirl.create(:team)

      delete "/teams/#{team.name}"

      assert_status 403
    end
  end

  def test_delete_missing_team
    delete "/teams/empire"

    assert_status 404
  end

  def test_get_team_users
    user = FactoryGirl.create(:user, :batman)
    user.teams.build(:name => "jla")
    user.save

    get "/teams/jla/users"

    assert_status 200

    actual = parsed_response

    assert_equal 1, actual.size
    assert_equal "batman", actual.first["name"]
  end

  def test_get_team_pubkeys
    key = fixture_content("id_rsa.pub")
    user = FactoryGirl.create(:user, :batman)
    user.teams.build(:name => "jla")
    user.pubkeys.build(:title => "batkey", key: key)
    user.save

    get "/teams/jla/pubkeys"

    assert_status 200

    actual = parsed_response

    assert_equal 1, actual.size
    assert_equal "batkey", actual.first["title"]
    assert_equal key, actual.first["key"]
  end

  private

  def assert_status(code)
    assert_equal code, last_response.status
  end

  def assert_location(match)
    assert_match(match, last_response.headers["Location"])
  end

  def parsed_response
    Oj.load last_response.body
  end

  def to_json(payload)
    Oj.dump payload
  end

  def authorize(*args)
    if args.size == 1
      user = args.first
      if user.is_a?(Symbol)
        user = FactoryGirl.create(:user, user)
      end
      super(user.name, user.password)
    else
      super(args.first, args.last)
    end
  end
end
