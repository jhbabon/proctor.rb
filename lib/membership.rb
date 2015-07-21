class Membership < ActiveRecord::Base
  belongs_to :user
  belongs_to :team

  validates :user_id, :presence => { :message => "user not found" }
  validates :team_id, :presence => { :message => "team not found" }

  def self.link(targets)
    user = User.find_by(:name => targets["user"])
    team = Team.find_or_create_by(:name => targets["team"]) if user

    create(:user => user, :team => team)
  end

  def self.unlink(targets)
    user = User.find_by(:name => targets["user"])
    team = Team.find_by(:name => targets["team"])
    if user && team
      conditions = { :user_id => user.id, :team_id => team.id }
      membership = find_by(conditions)
      membership.destroy if membership
    end
  end
end
