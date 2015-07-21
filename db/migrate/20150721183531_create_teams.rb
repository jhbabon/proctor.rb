class CreateTeams < ActiveRecord::Migration
  def change
    create_table :teams do |t|
      t.string :name, :index => true
    end

    create_table :memberships do |t|
      t.belongs_to :user, :index => true
      t.belongs_to :team, :index => true
    end
  end
end
