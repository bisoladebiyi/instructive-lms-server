# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_12_06_000007) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "courses", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.string "category"
    t.string "duration"
    t.string "banner_image"
    t.text "learning_points", default: [], array: true
    t.bigint "instructor_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "published_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_courses_on_category"
    t.index ["instructor_id", "status"], name: "index_courses_on_instructor_id_and_status"
    t.index ["instructor_id"], name: "index_courses_on_instructor_id"
    t.index ["status"], name: "index_courses_on_status"
  end

  create_table "enrollments", force: :cascade do |t|
    t.bigint "student_id", null: false
    t.bigint "course_id", null: false
    t.integer "progress", default: 0, null: false
    t.datetime "enrolled_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_enrollments_on_course_id"
    t.index ["student_id", "course_id"], name: "index_enrollments_on_student_id_and_course_id", unique: true
    t.index ["student_id"], name: "index_enrollments_on_student_id"
  end

  create_table "lesson_completions", force: :cascade do |t|
    t.bigint "student_id", null: false
    t.bigint "lesson_id", null: false
    t.datetime "completed_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lesson_id"], name: "index_lesson_completions_on_lesson_id"
    t.index ["student_id", "lesson_id"], name: "index_lesson_completions_on_student_id_and_lesson_id", unique: true
    t.index ["student_id"], name: "index_lesson_completions_on_student_id"
  end

  create_table "lessons", force: :cascade do |t|
    t.string "title", null: false
    t.string "duration"
    t.integer "lesson_type", default: 0, null: false
    t.string "video_url"
    t.text "text_content"
    t.string "pdf_url"
    t.integer "position", default: 0, null: false
    t.bigint "section_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["section_id", "position"], name: "index_lessons_on_section_id_and_position"
    t.index ["section_id"], name: "index_lessons_on_section_id"
  end

  create_table "sections", force: :cascade do |t|
    t.string "title", null: false
    t.integer "position", default: 0, null: false
    t.bigint "course_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id", "position"], name: "index_sections_on_course_id_and_position"
    t.index ["course_id"], name: "index_sections_on_course_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.integer "role", default: 0, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "phone"
    t.text "bio"
    t.string "avatar"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "courses", "users", column: "instructor_id"
  add_foreign_key "enrollments", "courses"
  add_foreign_key "enrollments", "users", column: "student_id"
  add_foreign_key "lesson_completions", "lessons"
  add_foreign_key "lesson_completions", "users", column: "student_id"
  add_foreign_key "lessons", "sections"
  add_foreign_key "sections", "courses"
end
