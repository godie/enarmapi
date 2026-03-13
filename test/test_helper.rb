ENV["RAILS_ENV"] ||= "test"

# Start SimpleCov before loading Rails
require "simplecov"
SimpleCov.start "rails" do
  add_group "Models", "app/models"
  add_group "Controllers", "app/controllers"
  add_group "Services", "app/services"
  add_group "Jobs", "app/jobs"

  # Falla si la cobertura es menor a 80%
  minimum_coverage 80

  # Falla si la cobertura baja respecto a la última ejecución (coverage/ está en .gitignore, así que la referencia varía por máquina)
  # refuse_coverage_drop

  # Ignorar archivos de configuración y migraciones
  add_filter "/config/"
  add_filter "/db/"
  add_filter "/test/"
end

require_relative "../config/environment"
require "rails/test_help"
require "mocha/minitest"
require "minitest/mock"
require "webmock/minitest"

# Configure WebMock to allow localhost connections for database
WebMock.disable_net_connect!(allow_localhost: true)

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    # Nota: Si tienes problemas con tests paralelos, puedes desactivarlos con:
    # parallelize(workers: 1)
    parallelize(workers: :number_of_processors)

    parallelize_setup do |worker|
      SimpleCov.command_name "#{SimpleCov.command_name}-#{worker}"
    end

    parallelize_teardown do |worker|
      SimpleCov.result
    end

    # IMPORTANTE: DatabaseCleaner y use_transactional_tests no deben usarse juntos
    # Si usas DatabaseCleaner, desactiva las transacciones
    # Si usas transacciones, no necesitas DatabaseCleaner
    # Opción 1: Usar transacciones (más rápido, recomendado para la mayoría de casos)
    self.use_transactional_tests = true

    # Opción 2: Usar DatabaseCleaner (necesario solo si usas múltiples conexiones de DB o threads)
    # self.use_transactional_tests = false
    # DatabaseCleaner.strategy = :transaction
    # setup do
    #   DatabaseCleaner.start
    # end
    # teardown do
    #   DatabaseCleaner.clean
    # end

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    # Descomenta si necesitas cargar fixtures automáticamente:
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

# Include custom test helpers
Dir[Rails.root.join("test/support/**/*.rb")].each { |f| require f }

class ActionDispatch::IntegrationTest
  include AuthenticationHelpers

  # Helper para hacer requests JSON más fácilmente
  def json_response
    JSON.parse(response.body)
  end

  # Helper para verificar respuestas JSON
  def assert_json_response(expected_status = :success)
    assert_response expected_status
    assert_equal "application/json; charset=utf-8", response.content_type
  end
end
