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

ActiveRecord::Schema[7.2].define(version: 2025_07_01_005122) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "achievements", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.jsonb "criteria"
    t.string "icon_url"
    t.integer "points"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "answers", force: :cascade do |t|
    t.string "text"
    t.text "description"
    t.boolean "is_correct"
    t.bigint "question_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["question_id"], name: "index_answers_on_question_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "description"
  end

  create_table "clinical_cases", force: :cascade do |t|
    t.bigint "category_id", null: false
    t.text "description"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_clinical_cases_on_category_id"
  end

  create_table "exam_questions", force: :cascade do |t|
    t.bigint "exam_id", null: false
    t.bigint "question_id", null: false
    t.integer "position"
    t.integer "points"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["exam_id", "question_id"], name: "index_exam_questions_on_exam_id_and_question_id", unique: true
    t.index ["exam_id"], name: "index_exam_questions_on_exam_id"
    t.index ["question_id"], name: "index_exam_questions_on_question_id"
  end

  create_table "exams", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.integer "time_limit"
    t.integer "passing_score"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "category_id", null: false
    t.index ["category_id"], name: "index_exams_on_category_id"
  end

  create_table "player_achievements", force: :cascade do |t|
    t.bigint "player_id", null: false
    t.bigint "achievement_id", null: false
    t.datetime "achieved_at"
    t.jsonb "progress"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["achievement_id"], name: "index_player_achievements_on_achievement_id"
    t.index ["player_id"], name: "index_player_achievements_on_player_id"
  end

  create_table "player_answers", force: :cascade do |t|
    t.bigint "player_id", null: false
    t.bigint "question_id", null: false
    t.bigint "answer_id", null: false
    t.boolean "is_correct"
    t.integer "time_taken"
    t.string "mode", default: "practice"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["answer_id"], name: "index_player_answers_on_answer_id"
    t.index ["player_id", "question_id", "created_at"], name: "idx_on_player_id_question_id_created_at_0ff3be30cd"
    t.index ["player_id"], name: "index_player_answers_on_player_id"
    t.index ["question_id"], name: "index_player_answers_on_question_id"
  end

  create_table "player_exam_answers", force: :cascade do |t|
    t.bigint "player_exam_id", null: false
    t.bigint "exam_question_id", null: false
    t.bigint "answer_id", null: false
    t.boolean "is_correct"
    t.integer "points_earned"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["answer_id"], name: "index_player_exam_answers_on_answer_id"
    t.index ["exam_question_id"], name: "index_player_exam_answers_on_exam_question_id"
    t.index ["player_exam_id", "exam_question_id"], name: "index_player_exam_question_unique", unique: true
    t.index ["player_exam_id"], name: "index_player_exam_answers_on_player_exam_id"
  end

  create_table "player_exams", force: :cascade do |t|
    t.bigint "player_id", null: false
    t.bigint "exam_id", null: false
    t.datetime "started_at"
    t.datetime "completed_at"
    t.integer "score"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["exam_id"], name: "index_player_exams_on_exam_id"
    t.index ["player_id"], name: "index_player_exams_on_player_id"
  end

  create_table "players", force: :cascade do |t|
    t.string "email"
    t.string "facebook_id"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "questions", force: :cascade do |t|
    t.text "text"
    t.bigint "clinical_case_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "category_id"
    t.index ["category_id"], name: "index_questions_on_category_id"
    t.index ["clinical_case_id"], name: "index_questions_on_clinical_case_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "username"
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "answers", "questions"
  add_foreign_key "clinical_cases", "categories"
  add_foreign_key "exam_questions", "exams"
  add_foreign_key "exam_questions", "questions"
  add_foreign_key "exams", "categories"
  add_foreign_key "player_achievements", "achievements"
  add_foreign_key "player_achievements", "players"
  add_foreign_key "player_answers", "answers"
  add_foreign_key "player_answers", "players"
  add_foreign_key "player_answers", "questions"
  add_foreign_key "player_exam_answers", "answers"
  add_foreign_key "player_exam_answers", "exam_questions"
  add_foreign_key "player_exam_answers", "player_exams"
  add_foreign_key "player_exams", "exams"
  add_foreign_key "player_exams", "players"
  add_foreign_key "questions", "categories"
  add_foreign_key "questions", "clinical_cases"
end
