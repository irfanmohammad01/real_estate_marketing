class CreateEmailTemplates < ActiveRecord::Migration[8.1]
  def change
    create_table :email_templates do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :email_type, null: false, foreign_key: true
      t.string :name, limit: 150
      t.string :subject
      t.string :preheader
      t.string :from_name, limit: 150
      t.string :from_email
      t.string :reply_to
      t.text :html_body
      t.text :text_body

      t.timestamps
    end
  end
end
