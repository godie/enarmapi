
#!/bin/bash
# Script para configurar la base de datos de testing

set -e

echo "🔧 Configurando base de datos de testing..."

# Verificar si PostgreSQL está corriendo
if ! pg_isready -h "${DATABASE_HOST:-127.0.0.1}" -p "${DATABASE_PORT:-5432}" > /dev/null 2>&1; then
  echo "⚠️  PostgreSQL no está corriendo en ${DATABASE_HOST:-127.0.0.1}:${DATABASE_PORT:-5432}"
  echo ""
  echo "Opciones:"
  echo "1. Iniciar PostgreSQL con Docker Compose:"
  echo "   docker-compose up -d database"
  echo ""
  echo "2. O iniciar PostgreSQL localmente"
  echo ""
  read -p "¿Deseas iniciar la base de datos con Docker Compose? (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker-compose up -d database
    echo "⏳ Esperando a que la base de datos esté lista..."
    sleep 5
  else
    echo "❌ Por favor inicia PostgreSQL manualmente y vuelve a ejecutar este script"
    exit 1
  fi
fi

echo "✅ PostgreSQL está corriendo"

# Preparar la base de datos de test
echo "📦 Preparando base de datos de test..."
RAILS_ENV=test bundle exec rails db:test:prepare

echo "✅ Base de datos de test configurada correctamente"
echo ""
echo "Ahora puedes ejecutar los tests con:"
echo "  bundle exec rails test"
