ENV["RAILS_ENV"] ||= "test"
require "simplecov"

SimpleCov.start "rails" do
  add_group "Models", "app/models"
  add_group "Controllers", "app/controllers"
  
  # Falla si la cobertura es menor a 80%
  minimum_coverage 80
  
  # Falla si la cobertura baja
  refuse_coverage_drop
end
require_relative "../config/environment"
require "rails/test_help"


module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)
    self.use_transactional_tests = true
    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    # fixtures :all
    # fixtures :categories, :clinical_cases

    # Add more helper methods to be used by all tests here...
  end
end

# Include custom test helpers
Dir[Rails.root.join('test/support/**/*.rb')].each { |f| require f }

class ActionDispatch::IntegrationTest
  include AuthenticationHelpers
end
