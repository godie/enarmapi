# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

puts "--- Seeding Categories and Clinical Cases ---"
# Ensure 'Urgencias' category is created or found reliably
urgencias_category = Category.find_or_create_by!(name: 'Urgencias') do |cat|
  puts "Creating category: Urgencias"
  # Add description if your model supports it and you want a default
  # cat.description = "Casos clínicos y preguntas relacionadas con urgencias médicas."
end
puts "Using category: #{urgencias_category.name} (ID: #{urgencias_category.id})"

# Create a clinical case associated with the 'Urgencias' category
if urgencias_category
  ClinicalCase.find_or_create_by!(name: 'Caso de Trauma Básico', category: urgencias_category) do |cc|
    cc.description = 'Paciente llega a urgencias después de un accidente de tráfico.'
    puts "Creating clinical case: #{cc.name} in category #{urgencias_category.name}"
  end
else
  puts "ERROR: Could not find or create 'Urgencias' category. Skipping clinical case creation."
end
puts "--- Categories and Clinical Cases Seeding Completed ---"


# --- Admin User Creation ---
# The following code creates an admin user.
# For this to work effectively in development or deployment,
# ensure you have set the following environment variables:
# ADMIN_EMAIL, ADMIN_USERNAME, ADMIN_PASSWORD

admin_email = ENV.fetch('ADMIN_EMAIL', 'admin@example.com')
admin_username = ENV.fetch('ADMIN_USERNAME', 'admin')
admin_password = ENV.fetch('ADMIN_PASSWORD', 'password') # Ensure this is a strong password in production

puts "Attempting to create or find admin user: #{admin_username} (#{admin_email})"

admin_user = User.find_or_initialize_by(email: admin_email)

if admin_user.new_record?
  admin_user.username = admin_username
  admin_user.password = admin_password
  admin_user.password_confirmation = admin_password
  # If there were an is_admin flag, it would be set here, e.g.:
  # user.is_admin = true
  if admin_user.save
    puts "Admin user '#{admin_username}' created successfully with email '#{admin_email}'."
  else
    puts "ERROR: Could not create admin user '#{admin_username}'. Errors: #{admin_user.errors.full_messages.join(", ")}"
  end
else
  puts "Admin user '#{admin_username}' with email '#{admin_email}' already exists. Ensuring password is set if in development/test."
  # Optionally, update password in development/test if it might have changed
  # Be cautious with this in production environments.
  if Rails.env.development? || Rails.env.test?
    admin_user.password = admin_password
    admin_user.password_confirmation = admin_password
    if admin_user.save
      puts "Password for admin user '#{admin_username}' has been updated (dev/test only)."
    else
      puts "ERROR: Could not update password for admin user '#{admin_username}'. Errors: #{admin_user.errors.full_messages.join(", ")}"
    end
  end
end
# --- End Admin User Creation ---

# --- Achievements Seeding ---
puts "\n--- Seeding Achievements ---"

achievements_data = [
  {
    name: "Pionero del Saber",
    description: "Completa tu primer examen en cualquier categoría.",
    criteria: { type: "exams_completed", count: 1 },
    points: 10,
    icon_url: "default_icon_pioneer.png"
  },
  {
    name: "Estudiante Dedicado",
    description: "Completa 5 exámenes en total.",
    criteria: { type: "exams_completed", count: 5 },
    points: 50,
    icon_url: "default_icon_dedicated_student.png"
  },
  {
    name: "Maratonista de Exámenes",
    description: "Completa 10 exámenes en total.",
    criteria: { type: "exams_completed", count: 10 },
    points: 100,
    icon_url: "default_icon_marathoner.png"
  },
  {
    name: "Maestro de Urgencias",
    description: "Obtén una precisión del 80% o más en la categoría 'Urgencias' después de al menos 2 exámenes en ella.",
    # category_id will be populated dynamically below
    criteria: { type: "category_accuracy", category_name: "Urgencias", accuracy_threshold: 80, min_exams_in_category: 2 },
    points: 75,
    icon_url: "default_icon_urgencias_master.png"
  }
  # {
  #   name: "Racha Imparable",
  #   description: "Consigue una racha de 10 respuestas correctas seguidas.",
  #   criteria: { type: "correct_streak", count: 10 },
  #   points: 60,
  #   icon_url: "default_icon_unstoppable_streak.png"
  # }
]

# Dynamically find and inject category_id for category-specific achievements
urgencias_seed_category = Category.find_by(name: 'Urgencias') # Use the same category created earlier

if urgencias_seed_category
  achievements_data.each do |ach_data|
    # Ensure criteria is a hash
    ach_data[:criteria] = {} unless ach_data[:criteria].is_a?(Hash)

    if ach_data[:criteria][:type] == "category_accuracy" && ach_data[:criteria][:category_name] == "Urgencias"
      ach_data[:criteria][:category_id] = urgencias_seed_category.id
      ach_data[:criteria].delete(:category_name) # Remove temporary key used for seeding
      puts "Configured 'Maestro de Urgencias' with category_id: #{urgencias_seed_category.id}"
    end
  end
else
  puts "WARN: Category 'Urgencias' not found during achievement seeding. 'Maestro de Urgencias' may not be configured correctly or will be skipped."
  # Option: remove the achievement if the category is critical
  achievements_data.reject! { |ach_data| ach_data[:name] == "Maestro de Urgencias" }
end


achievements_data.each do |ach_data|
  achievement = Achievement.find_or_initialize_by(name: ach_data[:name])
  achievement.description = ach_data[:description]
  achievement.criteria = ach_data[:criteria]
  achievement.points = ach_data[:points]
  achievement.icon_url = ach_data[:icon_url]

  if achievement.new_record?
    if achievement.save
      puts "Created achievement: #{achievement.name}"
    else
      puts "ERROR creating achievement #{achievement.name}: #{achievement.errors.full_messages.join(", ")}"
    end
  elsif achievement.changed? # If it exists, update if data is different
    if achievement.save
      puts "Updated achievement: #{achievement.name}"
    else
      puts "ERROR updating achievement #{achievement.name}: #{achievement.errors.full_messages.join(", ")}"
    end
  else
    puts "Achievement #{achievement.name} already exists and is up-to-date."
  end
end

puts "--- Achievements Seeding Completed ---"
