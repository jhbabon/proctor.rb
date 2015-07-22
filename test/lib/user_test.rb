require "helper"
require "models"

class UserTest < Minitest::Test
  def test_create_user
    assert_difference -> { User.count } do
      assert User.create(:name => "test", :password => "secret", :role => "admin")
    end
  end

  def test_validate_role_presence
    user = FactoryGirl.build(:user, :role => nil)

    refute user.valid?, "Expected empty role to be invalid"
  end

  def test_validate_role_value
    user = FactoryGirl.build(:user, :role => "unknown")

    refute user.valid?, "Expected 'unknown' role to be invalid"
  end

  def test_validate_name_presence
    user = FactoryGirl.build(:user, :name => nil)

    refute user.valid?, "Expected empty name to be invalid"
  end

  def test_validate_name_uniqueness
    FactoryGirl.create(:user, :name => "test")
    user = FactoryGirl.build(:user, :name => "test")

    refute user.valid?, "Expected duplicated name to be invalid"
  end

  def test_validate_name_with_wrong_format
    names = [
      "Test",
      "te st",
      "test?",
      "te#st",
      "tes/t",
      "t.est",
    ]

    names.each do |name|
      user = FactoryGirl.build(:user, :name => name)

      refute user.valid?, "Expected '#{name}' name to be invalid"
    end
  end

  def test_validate_name_with_correct_format
    names = [
      "test",
      "test-123",
      "te_st",
      "12345",
    ]

    names.each do |name|
      user = FactoryGirl.build(:user, :name => name)

      assert user.valid?, "Expected '#{name}' name to be valid"
    end
  end

  def test_as_api
    user = FactoryGirl.build(:user, :name => "test")
    expected = { "name" => "test" }

    assert_equal expected, user.as_api, "Expected to return correct API format"
  end

  def test_from_api
    user = User.new
    user.from_api("name" => "test", :password => "secret")

    assert_equal "test", user.name, "Expected to fetch name from API format"
  end

  def test_in_role_for_admin
    user = FactoryGirl.build(:user, :admin)

    User::ROLES.each do |role|
      assert user.in_role?(role)
    end
  end

  def test_in_role_for_user
    user = FactoryGirl.build(:user, :user)

    assert user.in_role?("user")
    assert user.in_role?("guest")
    refute user.in_role?("admin")
  end

  def test_in_role_for_guest
    user = FactoryGirl.build(:user, :guest)

    assert user.in_role?("guest")
    refute user.in_role?("user")
    refute user.in_role?("admin")
  end
end
