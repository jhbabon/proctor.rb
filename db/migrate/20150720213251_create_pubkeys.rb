class CreatePubkeys < ActiveRecord::Migration
  def change
    create_table :pubkeys do |t|
      t.string :title
      t.text :key

      t.belongs_to :user

      t.index %i(user_id title)
    end
  end
end
