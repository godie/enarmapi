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

ActiveRecord::Schema[8.1].define(version: 2026_02_18_160100) do
  create_table "achievements", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "criteria"
    t.text "description"
    t.string "icon_url"
    t.string "name"
    t.integer "points"
    t.datetime "updated_at", null: false
  end

  create_table "answers", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "is_correct"
    t.bigint "question_id", null: false
    t.string "text"
    t.datetime "updated_at", null: false
    t.index ["question_id"], name: "index_answers_on_question_id"
  end

  create_table "categories", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "clinical_cases", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name"
    t.integer "status", default: 0
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["category_id"], name: "index_clinical_cases_on_category_id"
    t.index ["status"], name: "index_clinical_cases_on_status"
    t.index ["user_id"], name: "index_clinical_cases_on_user_id"
  end

  create_table "exam_questions", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "exam_id", null: false
    t.integer "points"
    t.integer "position"
    t.bigint "question_id", null: false
    t.datetime "updated_at", null: false
    t.index ["exam_id", "question_id"], name: "index_exam_questions_on_exam_id_and_question_id", unique: true
    t.index ["exam_id"], name: "index_exam_questions_on_exam_id"
    t.index ["question_id"], name: "index_exam_questions_on_question_id"
  end

  create_table "exams", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.boolean "active", default: true
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name"
    t.integer "passing_score"
    t.integer "time_limit"
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_exams_on_category_id"
  end

  create_table "questions", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "category_id"
    t.bigint "clinical_case_id"
    t.datetime "created_at", null: false
    t.text "text"
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_questions_on_category_id"
    t.index ["clinical_case_id"], name: "index_questions_on_clinical_case_id"
  end

  create_table "user_achievements", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "achieved_at"
    t.bigint "achievement_id", null: false
    t.datetime "created_at", null: false
    t.json "progress"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["achievement_id"], name: "index_user_achievements_on_achievement_id"
    t.index ["user_id"], name: "index_user_achievements_on_user_id"
  end

  create_table "user_answers", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "answer_id", null: false
    t.datetime "created_at", null: false
    t.boolean "is_correct"
    t.string "mode", default: "practice"
    t.bigint "question_id", null: false
    t.integer "time_taken"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["answer_id"], name: "index_user_answers_on_answer_id"
    t.index ["question_id"], name: "index_user_answers_on_question_id"
    t.index ["user_id", "question_id", "created_at"], name: "index_user_answers_on_user_id_and_question_id_and_created_at"
    t.index ["user_id"], name: "index_user_answers_on_user_id"
  end

  create_table "user_exam_answers", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "answer_id", null: false
    t.datetime "created_at", null: false
    t.bigint "exam_question_id", null: false
    t.boolean "is_correct"
    t.integer "points_earned"
    t.datetime "updated_at", null: false
    t.bigint "user_exam_id", null: false
    t.index ["answer_id"], name: "index_user_exam_answers_on_answer_id"
    t.index ["exam_question_id"], name: "index_user_exam_answers_on_exam_question_id"
    t.index ["user_exam_id", "exam_question_id"], name: "index_player_exam_question_unique", unique: true
    t.index ["user_exam_id"], name: "index_user_exam_answers_on_user_exam_id"
  end

  create_table "user_exams", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.bigint "exam_id", null: false
    t.integer "score"
    t.datetime "started_at"
    t.string "status"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["exam_id"], name: "index_user_exams_on_exam_id"
    t.index ["user_id"], name: "index_user_exams_on_user_id"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "facebook_id"
    t.string "google_id"
    t.string "name"
    t.string "password_digest"
    t.json "preferences"
    t.integer "role", default: 0
    t.datetime "updated_at", null: false
    t.string "username"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["facebook_id"], name: "index_users_on_facebook_id", unique: true
    t.index ["google_id"], name: "index_users_on_google_id", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "answers", "questions"
  add_foreign_key "clinical_cases", "categories"
  add_foreign_key "clinical_cases", "users"
  add_foreign_key "exam_questions", "exams"
  add_foreign_key "exam_questions", "questions"
  add_foreign_key "exams", "categories"
  add_foreign_key "questions", "categories"
  add_foreign_key "questions", "clinical_cases"
  add_foreign_key "user_achievements", "achievements"
  add_foreign_key "user_achievements", "users"
  add_foreign_key "user_answers", "answers"
  add_foreign_key "user_answers", "questions"
  add_foreign_key "user_answers", "users"
  add_foreign_key "user_exam_answers", "answers"
  add_foreign_key "user_exam_answers", "exam_questions"
  add_foreign_key "user_exam_answers", "user_exams"
  add_foreign_key "user_exams", "exams"
  add_foreign_key "user_exams", "users"
end
