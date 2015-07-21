require "helper"
require "models"

class PubkeyTest < Minitest::Test
  def test_create_pubkey
    assert_difference -> { Pubkey.count } do
      assert Pubkey.create(:user_id => 1, :title => "test", :key => fixture_file("id_rsa.pub").read)
    end
  end

  def test_validate_key_presence
    pubkey = Pubkey.new(:user_id => 1, :title => "test")

    refute pubkey.valid?, "Expected empty key to be invalid"
  end

  def test_validate_title_presence
    pubkey = Pubkey.new(:user_id => 1, :key => "test")

    refute pubkey.valid?, "Expected empty title to be invalid"
  end

  def test_validate_title_uniqueness
    Pubkey.create(:user_id => 1, :title => "test", :key => "test")
    pubkey = Pubkey.new(:user_id => 1, :title => "test", :key => "test")

    refute pubkey.valid?, "Expected duplicated title to be invalid"
  end

  def test_validate_title_uniqueness_per_user
    Pubkey.create(:user_id => 1, :title => "test", :key => "test")
    pubkey = Pubkey.new(:user_id => 2, :title => "test", :key => "test")

    assert pubkey.valid?, "Expected duplicated title to be valid for other user"
  end

  def test_validate_title_with_wrong_format
    titles = [
      "Test",
      "te st",
      "test?",
      "te#st",
      "tes/t",
      "t.est",
    ]

    titles.each do |title|
      pubkey = Pubkey.new(:user_id => 1, :key => "test", :title => title)

      refute pubkey.valid?, "Expected '#{title}' title to be invalid"
    end
  end

  def test_validate_title_with_correct_format
    titles = [
      "test",
      "test-123",
      "te_st",
      "12345",
    ]

    titles.each do |title|
      pubkey = Pubkey.new(:user_id => 1, :key => "test", :title => title)

      assert pubkey.valid?, "Expected '#{title}' title to be valid"
    end
  end

  def test_as_api
    pubkey = Pubkey.new(:user_id => 1, :key => "test", :title => "test")
    expected = { "title" => "test", "key" => "test" }

    assert_equal expected, pubkey.as_api, "Expected to return correct API format"
  end

  def test_from_api
    key = fixture_file("id_rsa.pub").read
    pubkey = Pubkey.new("title" => "test")
    pubkey.from_api("key" => key)

    assert_equal key, pubkey.key, "Expected to fetch key from API format"
  end
end
