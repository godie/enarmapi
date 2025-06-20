# test/support/authentication_helpers.rb
module AuthenticationHelpers
  def admin_auth_headers(admin_user = nil)
    # If no specific admin user is provided, try to use the 'admin' fixture.
    # This requires users.yml to have an 'admin:' entry.
    admin = admin_user || users(:admin) # Assuming you have a fixture named 'admin' in users.yml

    unless admin
      # Fallback to creating one if fixtures are not set up or 'admin' is missing
      admin = User.create!(
        username: "test_admin_#{SecureRandom.hex(3)}",
        email: "test_admin_#{SecureRandom.hex(3)}@example.com",
        password: "password",
        password_confirmation: "password"
      )
    end

    token = JsonWebToken.encode(user_id: admin.id)
    { 'Authorization': "Bearer #{token}" }
  end

  def player_auth_headers(player_user = nil)
    player = player_user || players(:player_one)
    unless player
      player =  Player.create!(
        email: "test_player#{SecureRandom.hex(3)}@example.com",
        facebook_id: "#{SecureRandom.hex(16)}",
        name: "test_player_#{SecureRandom.hex(3)}"
      )
    end
    token = JsonWebToken.encode(player_id: player.id)
    { 'Authorization': "Bearer #{token}" }
  end
end
