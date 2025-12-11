class CreateSections < ActiveRecord::Migration[8.0]
  def change
    create_table :sections do |t|
      t.string :title, null: false
      t.integer :position, null: false, default: 0
      t.references :course, null: false, foreign_key: true

      t.timestamps
    end

    add_index :sections, [ :course_id, :position ]
  end
end
