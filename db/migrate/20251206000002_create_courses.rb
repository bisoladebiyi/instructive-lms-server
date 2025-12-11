class CreateCourses < ActiveRecord::Migration[8.0]
  def change
    create_table :courses do |t|
      t.string :title, null: false
      t.text :description
      t.string :category
      t.string :duration
      t.string :banner_image
      t.text :learning_points, array: true, default: []
      t.references :instructor, null: false, foreign_key: { to_table: :users }
      t.integer :status, null: false, default: 0
      t.datetime :published_at

      t.timestamps
    end

    add_index :courses, :status
    add_index :courses, :category
    add_index :courses, [ :instructor_id, :status ]
  end
end
