class AddJtiToUsers < ActiveRecord::Migration[8.1]
  def change
    # Add column as nullable first
    add_column :users, :jti, :string

    # Set JTI for all existing users
    reversible do |dir|
      dir.up do
        execute "UPDATE users SET jti = gen_random_uuid()::text"
      end
    end

    # Now make it not null and add unique index
    change_column_null :users, :jti, false
    add_index :users, :jti, unique: true
  end
end
