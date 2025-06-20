# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

category = Category.create(name: 'Urgencias')

ClinicalCase.create(name: 'one case', description: 'es un caso clinico', category: category)

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
