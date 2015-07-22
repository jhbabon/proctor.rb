require "helper"
require "models"

class MembershipTest < Minitest::Test
  def test_link_existing_user_and_team
    user = FactoryGirl.create(:user, :batman)
    team = FactoryGirl.create(:team, :jla)

    membership = Membership.link("user" => "batman", "team" => "jla")

    assert membership.persisted?
    assert_equal user, membership.user
    assert_equal team, membership.team
    assert_includes user.teams, team
    assert_includes team.users, user
  end

  def test_link_existing_user_and_new_team
    assert_difference -> { Team.count } do
      user = FactoryGirl.create(:user, :flash)
      membership = Membership.link("user" => "flash", "team" => "jsa")

      assert membership.persisted?
      assert_equal user, membership.user
      assert_equal "jsa", membership.team.name
      assert_includes user.teams.map(&:name), "jsa"
      assert_includes membership.team.users, user
    end
  end

  def test_doesnt_link_on_missing_user
    assert_difference -> { Team.count }, 0 do
      membership = Membership.link("user" => "missing", "team" => "jla")
      assert membership.invalid?
    end
  end

  def test_unlink
    user = FactoryGirl.create(:user, :batman)
    team = FactoryGirl.create(:team, :jla)
    Membership.create(:user => user, :team => team)

    assert_difference -> { Membership.count }, -1 do
      Membership.unlink("user" => "batman", "team" => "jla")

      refute_includes user.teams, team
      refute_includes team.users, user
    end
  end
end
