class CreateLessons < ActiveRecord::Migration[8.0]
  def change
    create_table :lessons do |t|
      t.string :title, null: false
      t.string :duration
      t.integer :lesson_type, null: false, default: 0
      t.string :video_url
      t.text :text_content
      t.string :pdf_url
      t.integer :position, null: false, default: 0
      t.references :section, null: false, foreign_key: true

      t.timestamps
    end

    add_index :lessons, [ :section_id, :position ]
  end
end
