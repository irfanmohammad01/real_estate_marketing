class CreateCommonEmailTemplates < ActiveRecord::Migration[8.1]
  def change
    create_table :common_email_templates do |t|
      t.integer :email_type_id, null: false

      t.string :name, limit: 150
      t.string :subject, limit: 255
      t.string :preheader, limit: 255

      t.string :from_name,  limit: 150, null: false
      t.string :from_email, limit: 255, null: false
      t.string :reply_to,   limit: 255

      t.text :html_body, null: false
      t.text :text_body

      t.timestamps
    end

    add_index :common_email_templates, :email_type_id
  end
end
