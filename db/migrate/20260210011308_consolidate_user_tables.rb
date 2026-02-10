class ConsolidateUserTables < ActiveRecord::Migration[8.1]
  def up
    # Step 1: Add is_system flag to organizations
    add_column :organizations, :is_system, :boolean, default: false, null: false
    add_index :organizations, :is_system

    # Step 2: Create System Administration organization
    system_org = Organization.create!(
      name: "System Administration",
      description: "Internal system administration organization",
      is_system: true
    )

    # Step 3: Add SUPERUSER role
    superuser_role = Role.create!(name: "SUPERUSER")

    # Step 4: Make organization_id nullable temporarily
    change_column_null :users, :organization_id, true

    # Step 5: Migrate super_users to users table
    SuperUser.find_each do |super_user|
      User.create!(
        email: super_user.email,
        password_digest: super_user.password_digest,
        role_id: superuser_role.id,
        organization_id: system_org.id,
        full_name: "System Administrator",
        status: "active",
        phone: "0000000000",
        created_at: super_user.created_at,
        updated_at: super_user.updated_at
      )
    end

    # Step 6: Re-add NOT NULL constraint to organization_id
    change_column_null :users, :organization_id, false

    # Step 7: Update email uniqueness constraint
    remove_index :users, :email if index_exists?(:users, :email)
    add_index :users, [ :email, :organization_id ], unique: true, name: "index_users_on_email_and_organization_id"

    # Step 8: Drop super_users table
    drop_table :super_users
  end

  def down
    # Recreate super_users table
    create_table :super_users do |t|
      t.string :email
      t.string :password_digest
      t.timestamps
    end

    # Migrate SUPERUSER users back to super_users
    superuser_role = Role.find_by(name: "SUPERUSER")
    if superuser_role
      User.where(role_id: superuser_role.id).find_each do |user|
        SuperUser.create!(
          email: user.email,
          password_digest: user.password_digest,
          created_at: user.created_at,
          updated_at: user.updated_at
        )
        user.destroy
      end

      # Remove SUPERUSER role
      superuser_role.destroy
    end

    # Remove email uniqueness constraint scoped to organization
    remove_index :users, name: "index_users_on_email_and_organization_id" if index_exists?(:users, [ :email, :organization_id ])
    add_index :users, :email, unique: true if !index_exists?(:users, :email)

    # Remove System Administration organization
    system_org = Organization.find_by(name: "System Administration", is_system: true)
    system_org&.destroy

    # Remove is_system flag from organizations
    remove_index :organizations, :is_system if index_exists?(:organizations, :is_system)
    remove_column :organizations, :is_system
  end
end
