class CreatePubkeys < ActiveRecord::Migration
  def change
    create_table :pubkeys do |t|
      t.integer :user_id
      t.string :title
      t.text :key

      t.index %i(user_id title)
    end
  end
end
