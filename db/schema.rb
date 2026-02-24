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

ActiveRecord::Schema[8.1].define(version: 2026_02_22_040006) do
  create_table "achievements", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "criteria"
    t.text "description"
    t.string "icon_url"
    t.string "name"
    t.integer "points"
    t.datetime "updated_at", null: false
  end

  create_table "active_storage_attachments", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
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

  create_table "flashcards", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.text "back"
    t.bigint "category_id"
    t.datetime "created_at", null: false
    t.text "front"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["category_id"], name: "index_flashcards_on_category_id"
    t.index ["user_id"], name: "index_flashcards_on_user_id"
  end

  create_table "messages", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "read_at"
    t.integer "receiver_id", null: false
    t.integer "sender_id", null: false
    t.datetime "updated_at", null: false
    t.index ["receiver_id"], name: "index_messages_on_receiver_id"
    t.index ["sender_id"], name: "index_messages_on_sender_id"
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

  create_table "specialist_profiles", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.text "bio"
    t.datetime "created_at", null: false
    t.integer "enarm_score"
    t.boolean "is_verified", default: false
    t.string "specialty"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_specialist_profiles_on_user_id"
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

  create_table "user_flashcards", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.float "ease_factor", default: 2.5
    t.bigint "flashcard_id", null: false
    t.integer "interval", default: 0
    t.datetime "next_review"
    t.integer "repetitions", default: 0
    t.string "status", default: "new"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["flashcard_id"], name: "index_user_flashcards_on_flashcard_id"
    t.index ["user_id", "flashcard_id"], name: "index_user_flashcards_on_user_id_and_flashcard_id", unique: true
    t.index ["user_id"], name: "index_user_flashcards_on_user_id"
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

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "answers", "questions"
  add_foreign_key "clinical_cases", "categories"
  add_foreign_key "clinical_cases", "users"
  add_foreign_key "exam_questions", "exams"
  add_foreign_key "exam_questions", "questions"
  add_foreign_key "exams", "categories"
  add_foreign_key "flashcards", "categories"
  add_foreign_key "flashcards", "users"
  add_foreign_key "questions", "categories"
  add_foreign_key "questions", "clinical_cases"
  add_foreign_key "specialist_profiles", "users"
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
  add_foreign_key "user_flashcards", "flashcards"
  add_foreign_key "user_flashcards", "users"
end
