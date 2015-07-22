require "helper"
require "ability"
require "user"

class AbilityTest < Minitest::Test
  def test_admin_can_use_everything
    admin = FactoryGirl.build(:user, :admin)
    ability = Ability.new(admin)

    [FactoryGirl.build(:user), FactoryGirl.build(:pubkey)].each do |thing|
      assert ability.can_use?(thing)
    end
  end

  def test_guest_cannot_use_anything
    guest = FactoryGirl.build(:user, :guest)
    ability = Ability.new(guest)

    [guest, FactoryGirl.build(:user), FactoryGirl.build(:pubkey)].each do |thing|
      refute ability.can_use?(thing)
    end
  end

  def test_user_can_use_itself
    user = FactoryGirl.create(:user, :user)
    ability = Ability.new(user)

    assert ability.can_use?(user)
  end

  def test_user_cannot_use_other_users
    user = FactoryGirl.create(:user, :user)
    ability = Ability.new(user)

    refute ability.can_use?(FactoryGirl.create(:user))
  end

  def test_user_can_use_its_pubkeys
    user = FactoryGirl.create(:user, :user)
    pubkey = FactoryGirl.create(:pubkey, :user => user)
    ability = Ability.new(user)

    assert ability.can_use?(pubkey)
  end

  def test_user_cannot_use_other_pubkeys
    pubkey = FactoryGirl.create(:pubkey)
    ability = Ability.new(FactoryGirl.create(:user, :user))

    refute ability.can_use?(pubkey)
  end
end
