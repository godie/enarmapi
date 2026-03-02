# Cómo volver a PostgreSQL

Este proyecto está configurado para usar **MySQL** en development, test y production. Si en el futuro quieres volver a **PostgreSQL**, sigue estos pasos.

## 1. Gemfile

- **Quitar** (o mover solo a production) la gema `mysql2` del bloque principal.
- **Descomentar** la gema `pg` en el grupo `development, :test`.

Ejemplo:

```ruby
# Si solo production usara MySQL:
# group :production do
#   gem "mysql2", "~> 0.5"
# end

group :development, :test do
  # ...
  gem "pg"
end
```

Luego ejecuta:

```bash
bundle install
```

## 2. config/database.yml

Sustituir el bloque `default` y los entornos para usar el adapter de PostgreSQL.

**default (PostgreSQL):**

```yaml
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  timeout: 5000
  username: <%= ENV['DATABASE_USER'] || "postgres" %>
  password: <%= ENV['DATABASE_PASSWORD'] || "test" %>
  port: <%= ENV['DATABASE_PORT'] || "5432" %>
  host: <%= ENV['DATABASE_HOST'] || "127.0.0.1" %>

development:
  <<: *default
  database: enarmapi_development

test:
  <<: *default
  database: enarmapi_test

production:
  <<: *default
  database: enarmapi_production
  username: <%= ENV['DATABASE_USER'] %>
  password: <%= ENV['DATABASE_PASSWORD'] %>
  host: <%= ENV['DATABASE_HOST'] || "127.0.0.1" %>
```

## 3. compose.yml (Docker para development)

Cambiar el servicio de base de datos de MySQL a PostgreSQL y ajustar variables del `app`:

- **Servicio `database`:** imagen `postgres:14`, puerto `5432`, variables `POSTGRES_*`.
- **Servicio `app`:** `DATABASE_PORT: "5432"`, `DATABASE_USER: postgres`, `DATABASE_PASSWORD: test`, `DATABASE_NAME: enarmapi_development`.
- **Volumen:** nombre tipo `db_pg_data` y montar en `/var/lib/postgresql/data`.
- Opcional: volver a añadir el servicio **pgAdmin** si lo usabas.
- Opcional: si tenías un script de inicialización (por ejemplo `init.sql` en la raíz), puedes montarlo de nuevo en el servicio `database` con `./init.sql:/docker-entrypoint-init.d/init.sql` (PostgreSQL ejecuta los `.sql` de ese directorio al crear el contenedor).

Ejemplo mínimo:

```yaml
services:
  database:
    image: postgres:14
    volumes:
      - db_pg_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    environment:
      POSTGRES_PASSWORD: test
      POSTGRES_USER: postgres

  app:
    # ...
    environment:
      DATABASE_HOST: database
      DATABASE_USER: postgres
      DATABASE_PASSWORD: test
      DATABASE_NAME: enarmapi_development
      DATABASE_PORT: "5432"
      RAILS_ENV: development
    depends_on:
      - database

volumes:
  db_pg_data: {}
```

## 4. Levantar y migrar

Con Docker:

```bash
docker compose down -v   # opcional: borra volúmenes si quieres empezar de cero
docker compose up -d database
docker compose run --rm app bundle install
docker compose run --rm app bin/rails db:create
docker compose run --rm app bin/rails db:migrate
docker compose up app
```

Sin Docker (PostgreSQL instalado en tu máquina):

```bash
bundle install
bin/rails db:create
bin/rails db:migrate
bin/rails server
```

## 5. Migraciones y diferencias SQL

- Las migraciones de Rails suelen ser compatibles entre MySQL y PostgreSQL; revisa cualquier SQL crudo (`execute`, `raw SQL`) por diferencias de sintaxis o tipos.
- Si tienes migraciones con SQL específico de MySQL (por ejemplo `utf8mb4`, `LONGTEXT`), puede hacer falta adaptarlas o añadir migraciones condicionales por adapter.
- Después de cambiar de base de datos, es recomendable volver a crear y migrar en development/test (`db:drop db:create db:migrate`) o restaurar un dump si necesitas datos existentes.

## 6. Resumen de cambios

| Dónde           | MySQL (actual)     | PostgreSQL        |
|-----------------|--------------------|-------------------|
| **Gemfile**     | `mysql2`           | `pg`              |
| **database.yml** | adapter: mysql2, port 3306 | adapter: postgresql, port 5432 |
| **compose**     | image: mysql:8.0, puerto 3306 | image: postgres:14, puerto 5432 |
| **Variables app** | DATABASE_PORT=3306, USER enarm | DATABASE_PORT=5432, USER postgres |

Con estos pasos puedes volver a usar PostgreSQL en development (y, si lo configuras igual, en test y production) en cualquier momento.
