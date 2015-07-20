require "helper"
require "user"

class UserTest < Minitest::Test
  def test_create_user
    before = User.count
    user = User.create(:name => "test")
    after = User.count

    assert user
    assert_equal before + 1, after, "Expected to increase users by 1"
  end

  def test_validate_name_presence
    user = User.new

    refute user.valid?, "Expected empty name to be invalid"
  end

  def test_validate_name_uniqueness
    User.create(:name => "test")
    user = User.new(:name => "test")

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
      user = User.new(:name => name)

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
      user = User.new(:name => name)

      assert user.valid?, "Expected '#{name}' name to be valid"
    end
  end

  def test_as_api
    user = User.new(:name => "test")
    expected = { "name" => "test" }

    assert_equal expected, user.as_api, "Expected to return correct API format"
  end

  def test_from_api
    user = User.new
    user.from_api("name" => "test")

    assert_equal "test", user.name, "Expected to fetch name from API format"
  end
end
