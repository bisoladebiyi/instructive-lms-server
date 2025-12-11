class CreateEnrollments < ActiveRecord::Migration[8.0]
  def change
    create_table :enrollments do |t|
      t.references :student, null: false, foreign_key: { to_table: :users }
      t.references :course, null: false, foreign_key: true
      t.integer :progress, null: false, default: 0
      t.datetime :enrolled_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.datetime :completed_at

      t.timestamps
    end

    add_index :enrollments, [ :student_id, :course_id ], unique: true
  end
end
