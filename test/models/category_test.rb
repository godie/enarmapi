require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  def setup
    # Limpiar datos si es necesario
    ClinicalCase.destroy_all
    Category.destroy_all
  end
  # Test de validaciones
  test "should be valid with valid attributes" do
    category = Category.new(name: "Cardiología")
    assert category.valid?
  end

  test "should not be valid without a name" do
    category = Category.new(name: nil)
    assert_not category.valid?
    assert_includes category.errors[:name], "can't be blank"
  end

  test "should not be valid with empty name" do
    category = Category.new(name: "")
    assert_not category.valid?
    assert_includes category.errors[:name], "can't be blank"
  end

  test "should not be valid with duplicate name" do
    Category.create!(name: "Neurología")
    duplicate_category = Category.new(name: "Neurología")
    assert_not duplicate_category.valid?
    assert_includes duplicate_category.errors[:name], "has already been taken"
  end

  test "should be valid with duplicate name but different case" do
    Category.create!(name: "Pediatría")
    category = Category.new(name: "PEDIATRÍA")
    assert_not category.valid?
    assert_includes category.errors[:name], "has already been taken"
  end

  test "should trim whitespace from name" do
    category = Category.create!(name: "  Oftalmología  ")
    assert_equal "Oftalmología", category.name
  end

  # Test de asociaciones
  test "should have many clinical cases" do
    category =Category.create!(name: "  test category  ")
    assert_respond_to category, :clinical_cases
  end

  test "should destroy dependent clinical cases" do
    category = Category.create!(name: "Dermatología")
    clinical_case = category.clinical_cases.create!(
      name: "Caso de melanoma",
      description: "Paciente con lesión pigmentada"
    )

    assert_difference "ClinicalCase.count", -1 do
      category.destroy
    end
  end

  # Test de scopes
  test "should order by name alphabetically by default" do
    Category.destroy_all
    cardio = Category.create!(name: "Cardiología")
    neuro = Category.create!(name: "Neurología")
    dermato = Category.create!(name: "Dermatología")

    assert_equal [ cardio, dermato, neuro ], Category.alphabetical
  end

  test "should find categories with clinical cases" do
    category_with_cases = Category.create!(name: "Ginecología")
    category_without_cases = Category.create!(name: "Radiología")

    category_with_cases.clinical_cases.create!(
      name: "Caso obstétrico",
      description: "Embarazo de alto riesgo"
    )

    assert_includes Category.with_clinical_cases, category_with_cases
    assert_not_includes Category.with_clinical_cases, category_without_cases
  end

  # Test de métodos de instancia
  test "should count clinical cases" do
    category = Category.create!(name: "Traumatología")
    assert_equal 0, category.clinical_cases_count

    2.times do |i|
      category.clinical_cases.create!(
        name: "Caso #{i}",
        description: "Descripción #{i}"
      )
    end

    assert_equal 2, category.clinical_cases_count
  end

  test "should count total questions through clinical cases" do
    category = Category.create!(name: "Psiquiatría")
    case1 = category.clinical_cases.create!(
      name: "Caso de depresión",
      description: "Paciente con síntomas depresivos"
    )
    case2 = category.clinical_cases.create!(
      name: "Caso de ansiedad",
      description: "Paciente con trastorno de ansiedad"
    )

    # Agregar preguntas a cada caso
    3.times { case1.questions.create!(text: "Pregunta") }
    2.times { case2.questions.create!(text: "Pregunta") }

    assert_equal 5, category.total_questions_count
  end

  # Test de métodos de clase
  test "should find most used categories" do
    Category.destroy_all
    popular = Category.create!(name: "Medicina Interna")
    less_popular = Category.create!(name: "Medicina Nuclear")
    unpopular = Category.create!(name: "Medicina Deportiva")

    5.times do
      popular.clinical_cases.create!(
        name: "Caso",
        description: "Descripción"
      )
    end

    2.times do
      less_popular.clinical_cases.create!(
        name: "Caso",
        description: "Descripción"
      )
    end

    most_used = Category.most_used(2)
    assert_equal 2, most_used.length
    assert_equal popular, most_used.first
    assert_equal less_popular, most_used.second
  end

  # Test de callbacks
  test "should capitalize name before saving" do
    category = Category.create!(name: "medicina general")
    assert_equal "Medicina General", category.name
  end

  # Test de formato JSON
  test "should return correct json representation" do
    category = Category.create!(name: "Oncología")
    category.clinical_cases.create!(
      name: "Caso oncológico",
      description: "Descripción"
    )

    json = category.as_json(include_stats: true)
    assert_equal "Oncología", json["name"]
    assert_equal 1, json[:clinical_cases_count]
  end
end
