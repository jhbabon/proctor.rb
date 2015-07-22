require "helper"
require "models"

class PubkeyTest < Minitest::Test
  def test_create_pubkey
    assert_difference -> { Pubkey.count } do
      assert Pubkey.create(:user_id => 1, :title => "test", :key => fixture_content("id_rsa.pub"))
    end
  end

  def test_validate_key_presence
    pubkey = FactoryGirl.build(:pubkey, :key => nil)

    refute pubkey.valid?, "Expected empty key to be invalid"
  end

  def test_validate_title_presence
    pubkey = FactoryGirl.build(:pubkey, :title => nil)

    refute pubkey.valid?, "Expected empty title to be invalid"
  end

  def test_validate_title_uniqueness
    FactoryGirl.create(:pubkey, :user_id => 1, :title => "test")
    pubkey = FactoryGirl.build(:pubkey, :user_id => 1, :title => "test")

    refute pubkey.valid?, "Expected duplicated title to be invalid"
  end

  def test_validate_title_uniqueness_per_user
    FactoryGirl.create(:pubkey, :user_id => 1, :title => "test")
    pubkey = FactoryGirl.build(:pubkey, :user_id => 2, :title => "test")

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
      pubkey = FactoryGirl.build(:pubkey, :title => title)

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
      pubkey = FactoryGirl.build(:pubkey, :title => title)

      assert pubkey.valid?, "Expected '#{title}' title to be valid"
    end
  end

  def test_as_api
    pubkey = FactoryGirl.build(:pubkey, :title => "test", :key => "test")
    expected = { "title" => "#{pubkey.user.name}@test", "key" => "test" }

    assert_equal expected, pubkey.as_api, "Expected to return correct API format"
  end

  def test_from_api
    key = fixture_content("id_rsa.pub")
    pubkey = Pubkey.new("title" => "test")
    pubkey.from_api("key" => key)

    assert_equal key, pubkey.key, "Expected to fetch key from API format"
  end
end
