class AddPasswordToUsers < ActiveRecord::Migration
  def change
    change_table :users do |t|
      t.string :role
      t.string :password_digest
    end
  end
end
