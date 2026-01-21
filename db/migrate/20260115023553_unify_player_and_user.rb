class UnifyPlayerAndUser < ActiveRecord::Migration[7.2]
  def change
    # 1. Eliminar la tabla de usuarios vieja (admin)
    drop_table :users if table_exists?(:users)

    # 2. Renombrar la tabla principal de jugadores a usuarios (el nuevo estándar)
    rename_table :players, :users

    # 3. Añadir columna de rol a la nueva tabla usuarios
    add_column :users, :role, :integer, default: 0

    # 4. Renombrar las tablas relacionadas y sus columnas de referencia
    
    # PlayerAchievements -> UserAchievements
    rename_table :player_achievements, :user_achievements
    rename_column :user_achievements, :player_id, :user_id

    # PlayerAnswers -> UserAnswers
    rename_table :player_answers, :user_answers
    rename_column :user_answers, :player_id, :user_id

    # PlayerExams -> UserExams
    rename_table :player_exams, :user_exams
    rename_column :user_exams, :player_id, :user_id

    # PlayerExamAnswers -> UserExamAnswers
    rename_table :player_exam_answers, :user_exam_answers
    rename_column :user_exam_answers, :player_exam_id, :user_exam_id
  end
end
