class AddJtiToSuperUsers < ActiveRecord::Migration[8.1]
  def change
    # Add column as nullable first
    add_column :super_users, :jti, :string

    # Set JTI for all existing super users
    reversible do |dir|
      dir.up do
        execute "UPDATE super_users SET jti = gen_random_uuid()::text"
      end
    end

    # Now make it not null and add unique index
    change_column_null :super_users, :jti, false
    add_index :super_users, :jti, unique: true
  end
end
