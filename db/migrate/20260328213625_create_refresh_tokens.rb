class CreateRefreshTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :refresh_tokens do |t|
      t.string :token
      t.references :authenticatable, polymorphic: true, null: false
      t.datetime :expires_at

      t.timestamps
    end
    add_index :refresh_tokens, :token
  end
end
