require "helper"
require "models"

class TeamTest < Minitest::Test
  def test_create_team
    assert_difference -> { Team.count } do
      assert Team.create(:name => "test")
    end
  end

  def test_validate_name_presence
    team = Team.new

    refute team.valid?, "Expected empty name to be invalid"
  end

  def test_validate_name_uniqueness
    Team.create(:name => "test")
    team = Team.new(:name => "test")

    refute team.valid?, "Expected duplicated name to be invalid"
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
      team = Team.new(:name => name)

      refute team.valid?, "Expected '#{name}' name to be invalid"
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
      team = Team.new(:name => name)

      assert team.valid?, "Expected '#{name}' name to be valid"
    end
  end

  def test_pubkeys
    team = Team.new(:name => "test")

    user = team.users.build(:name => "tester")
    user.pubkeys.build(:title => "key", :key => "testing")

    user = team.users.build(:name => "tester2")
    user.pubkeys.build(:title => "key", :key => "testing")

    assert_equal 2, team.pubkeys.size
  end

  def test_as_api
    team = Team.new(:name => "test")
    team.users << User.new(:name => "tester")
    expected = { "name" => "test", "users" => %w(tester) }

    assert_equal expected, team.as_api, "Expected to return correct API format"
  end
end
