# Enarm API

## 1. Overview

Enarm API is a backend application designed to support a medical quiz and training platform. It provides functionalities for managing users, players, medical categories, clinical cases, questions, exams, and player answers.

## 2. Prerequisites

To run this project, you will need the following software installed:

-   Docker
-   Docker Compose (Recommended for local development, optional if you manage services like PostgreSQL separately)

## 3. Getting Started

### 3.1. Clone the Repository

```bash
git clone <your_repository_url> # Replace <your_repository_url> with the actual URL
cd enarm-api # Or your repository's directory name
```

### 3.2. Configuration

-   **Database:** Database connection details are defined in `config/database.yml`. These settings can be overridden using environment variables (e.g., `DATABASE_HOST`, `DATABASE_USER`, `DATABASE_PASSWORD`, `DATABASE_PORT`, `DATABASE_DB`). The `compose.yml` example below pre-configures these for the `app` service.
-   **Rails Master Key:** The application uses Rails encrypted credentials (`config/credentials.yml.enc`).
    -   If you have an existing `config/master.key` file or the `RAILS_MASTER_KEY` environment variable set, the application will use it to decrypt credentials.
    -   If you need to generate a new master key (e.g., for a fresh setup or to modify credentials):
        ```bash
        # To generate a new key and edit credentials (if you don't have a key yet):
        # docker-compose run --rm app rails credentials:edit
        # This will generate a config/master.key and open the credentials file in an editor.
        # Make sure to save the generated key.
        ```
    -   The `RAILS_MASTER_KEY` environment variable must be available to the application when it runs.

### 3.3. Building and Running with Docker (Production-like)

This method is suitable for running the application as a standalone container, assuming you have an external PostgreSQL database or another way to provide the database service.

```bash
# Build the Docker image
docker build -t enarm_api .

# Run the Docker container
# Replace placeholders with your actual configuration.
docker run -d -p 3000:3000 \
  -e RAILS_ENV=production \
  -e RAILS_MASTER_KEY=<your_rails_master_key> \
  -e DATABASE_HOST=<your_db_host> \
  -e DATABASE_USER=<your_db_user> \
  -e DATABASE_PASSWORD=<your_db_password> \
  -e DATABASE_DB=<your_production_db_name> \
  enarm_api
```

**Note:**
-   Ensure your database is accessible from the Docker container.
-   The `Dockerfile` is optimized for production, so development gems are not included.

### 3.4. Building and Running with Docker Compose (Development)

The provided `compose.yml` in the repository is a good starting point for setting up a development environment. It typically includes the database (PostgreSQL) and pgAdmin. You'll need to add the Rails `app` service to it.

**Example `compose.yml` structure (you might need to merge this with your existing `compose.yml`):**

```yaml
version: '3.8'
services:
  database:
    image: postgres:14
    container_name: enarm_db
    ports:
      - "5432:5432" # Exposes PostgreSQL to the host
    environment:
      POSTGRES_USER: test
      POSTGRES_PASSWORD: test
      POSTGRES_DB: enarmapi_development # Default DB for development
    volumes:
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql # Optional: if you have an init.sql
      - postgres_data:/var/lib/postgresql/data # Persists DB data

  admin: # pgAdmin service (optional)
    image: dpage/pgadmin4
    container_name: enarm_pgadmin
    environment:
      PGADMIN_DEFAULT_EMAIL: "admin@example.com"
      PGADMIN_DEFAULT_PASSWORD: "admin"
    ports:
      - "5050:80" # Access pgAdmin on http://localhost:5050
    depends_on:
      - database

  app: # Rails application service
    build:
      context: .
      dockerfile: Dockerfile # Assumes Dockerfile is in the root
    container_name: enarm_app
    command: bundle exec rails s -p 3000 -b '0.0.0.0'
    volumes:
      - .:/usr/src/app # Mounts current directory to app directory in container for live code changes
      - bundle_cache:/usr/local/bundle # Persist bundle cache
    ports:
      - "3000:3000" # Access Rails app on http://localhost:3000
    depends_on:
      - database
    environment:
      RAILS_ENV: development
      DATABASE_HOST: database # Connects to the 'database' service name
      DATABASE_USER: test
      DATABASE_PASSWORD: test
      DATABASE_DB: enarmapi_development
      DATABASE_PORT: 5432
      RAILS_MASTER_KEY: ${RAILS_MASTER_KEY_DEV:-$(cat config/master.key || echo "pleas_provide_a_master_key")} # Loads from env var or master.key
      BUNDLE_WITHOUT: "" # Ensure development gems are installed

volumes:
  postgres_data: # Defines the volume for PostgreSQL data
  bundle_cache: # Defines the volume for bundle cache
```

**Instructions:**

1.  **Master Key:** Ensure you have a `config/master.key` file or that `config/credentials.yml.enc` is present and you have the corresponding key. If not, generate one (see section 3.2). For the `compose.yml` example above, it tries to read `config/master.key`. You can also set `RAILS_MASTER_KEY_DEV` in a `.env` file.
2.  **Update `compose.yml`:** Modify your `compose.yml` to include the `app` service as shown above. Adjust `RAILS_MASTER_KEY` as needed.
3.  **Build the app image:**
    ```bash
    docker-compose build app
    ```
4.  **Start services:**
    ```bash
    docker-compose up -d database admin # Start database and pgAdmin in detached mode
    ```
5.  **Wait for the database** to initialize (a few seconds).
6.  **Prepare the database** (create, migrate, seed):
    ```bash
    docker-compose run --rm app bundle exec rails db:prepare
    ```
7.  **Start the application:**
    ```bash
    docker-compose up -d app
    ```
8.  Access the application at `http://localhost:3000`.
9.  Access pgAdmin (if used) at `http://localhost:5050`.

### 3.5. Database Initialization

The `db:prepare` command is generally recommended as it handles database creation (if not exists), runs migrations, and also attempts to load seeds if the database is empty.

-   **With Docker Compose (after `docker-compose up -d database`):**
    ```bash
    docker-compose run --rm app bundle exec rails db:prepare
    ```
-   **With Standalone Docker Container (after `docker run ...`):**
    Identify your container name or ID (e.g., using `docker ps`).
    ```bash
    docker exec <container_name_or_id> bundle exec rails db:prepare
    ```
    If you need to run seeds explicitly:
    ```bash
    docker exec <container_name_or_id> bundle exec rails db:seed
    ```

## 4. Running Tests

Tests should be run against the test database.

-   **With Docker Compose:**
    1.  Prepare the test database:
        ```bash
        docker-compose run --rm app bundle exec rails db:prepare RAILS_ENV=test
        ```
    2.  Run tests:
        ```bash
        docker-compose run --rm app bundle exec rails test
        ```

-   **With Standalone Docker Container:**
    1.  Prepare the test database:
        ```bash
        docker exec <container_name_or_id> bundle exec rails db:prepare RAILS_ENV=test
        ```
    2.  Run tests:
        ```bash
        docker exec <container_name_or_id> bundle exec rails test
        ```

## 5. API Documentation

This document outlines the available API endpoints for the Enarm API application.

### Health Check

*   **GET /up**
    *   **Controller & Action:** `rails/health#show`
    *   **Description:** Returns a 200 status if the application is running correctly. Used for uptime monitoring.
    *   **Authentication:** Not required.

### Authentication

*   **POST /auth_user**
    *   **Controller & Action:** `auth#auth_user`
    *   **Description:** Authenticates a user and returns a JWT token.
    *   **Request Parameters:** Likely `email` and `password`.
    *   **Authentication:** Not required (this endpoint is for obtaining authentication).

### Users

*   **GET /users**
    *   **Controller & Action:** `users#index`
    *   **Description:** Retrieves a list of users.
    *   **Authentication:** Likely required (Admin).
*   **POST /users**
    *   **Controller & Action:** `users#create`
    *   **Description:** Creates a new user.
    *   **Request Parameters:** User attributes (e.g., `name`, `email`, `password`, `password_confirmation`).
    *   **Authentication:** May not be required for signup, or admin only.
*   **GET /users/:id**
    *   **Controller & Action:** `users#show`
    *   **Description:** Retrieves a specific user.
    *   **Authentication:** Likely required (Owner or Admin).
*   **PATCH/PUT /users/:id**
    *   **Controller & Action:** `users#update`
    *   **Description:** Updates a specific user.
    *   **Request Parameters:** User attributes to update.
    *   **Authentication:** Likely required (Owner or Admin).
*   **DELETE /users/:id**
    *   **Controller & Action:** `users#destroy`
    *   **Description:** Deletes a specific user.
    *   **Authentication:** Likely required (Owner or Admin).

### Players

*   **GET /players**
    *   **Controller & Action:** `players#index`
    *   **Description:** Retrieves a list of players.
    *   **Authentication:** Likely required.
*   **POST /players**
    *   **Controller & Action:** `players#create`
    *   **Description:** Creates a new player.
    *   **Request Parameters:** Player attributes (e.g., `name`, `user_id`).
    *   **Authentication:** Likely required.
*   **GET /players/:id**
    *   **Controller & Action:** `players#show`
    *   **Description:** Retrieves a specific player.
    *   **Authentication:** Likely required.
*   **PATCH/PUT /players/:id**
    *   **Controller & Action:** `players#update`
    *   **Description:** Updates a specific player.
    *   **Request Parameters:** Player attributes to update.
    *   **Authentication:** Likely required.
*   **DELETE /players/:id**
    *   **Controller & Action:** `players#destroy`
    *   **Description:** Deletes a specific player.
    *   **Authentication:** Likely required.

### Categories

*   **GET /categories**
    *   **Controller & Action:** `categories#index`
    *   **Description:** Retrieves a list of categories.
    *   **Authentication:** Not likely required or user-level.
*   **POST /categories**
    *   **Controller & Action:** `categories#create`
    *   **Description:** Creates a new category.
    *   **Request Parameters:** Category attributes (e.g., `name`, `description`).
    *   **Authentication:** Likely required (Admin).
*   **GET /categories/:id**
    *   **Controller & Action:** `categories#show`
    *   **Description:** Retrieves a specific category.
    *   **Authentication:** Not likely required or user-level.
*   **PATCH/PUT /categories/:id**
    *   **Controller & Action:** `categories#update`
    *   **Description:** Updates a specific category.
    *   **Request Parameters:** Category attributes to update.
    *   **Authentication:** Likely required (Admin).
*   **DELETE /categories/:id**
    *   **Controller & Action:** `categories#destroy`
    *   **Description:** Deletes a specific category.
    *   **Authentication:** Likely required (Admin).

### Clinical Cases

*   **GET /clinical_cases**
    *   **Controller & Action:** `clinical_cases#index`
    *   **Description:** Retrieves a list of clinical cases.
    *   **Authentication:** Likely required.
*   **POST /clinical_cases**
    *   **Controller & Action:** `clinical_cases#create`
    *   **Description:** Creates a new clinical case.
    *   **Request Parameters:** Clinical case attributes (e.g., `title`, `description`, `category_id`).
    *   **Authentication:** Likely required (Admin/Content Creator).
*   **GET /clinical_cases/:id**
    *   **Controller & Action:** `clinical_cases#show`
    *   **Description:** Retrieves a specific clinical case.
    *   **Authentication:** Likely required.
*   **PATCH/PUT /clinical_cases/:id**
    *   **Controller & Action:** `clinical_cases#update`
    *   **Description:** Updates a specific clinical case.
    *   **Request Parameters:** Clinical case attributes to update.
    *   **Authentication:** Likely required (Admin/Content Creator).
*   **DELETE /clinical_cases/:id**
    *   **Controller & Action:** `clinical_cases#destroy`
    *   **Description:** Deletes a specific clinical case.
    *   **Authentication:** Likely required (Admin/Content Creator).

### Questions (Nested under Clinical Cases)

*   **GET /clinical_cases/:clinical_case_id/questions**
    *   **Controller & Action:** `questions#index`
    *   **Description:** Retrieves a list of questions for a specific clinical case.
    *   **Authentication:** Likely required.
*   **POST /clinical_cases/:clinical_case_id/questions**
    *   **Controller & Action:** `questions#create`
    *   **Description:** Creates a new question for a specific clinical case.
    *   **Request Parameters:** Question attributes (e.g., `text`, `options`, `correct_answer_index`, `clinical_case_id`).
    *   **Authentication:** Likely required (Admin/Content Creator).
*   **GET /clinical_cases/:clinical_case_id/questions/:id**
    *   **Controller & Action:** `questions#show`
    *   **Description:** Retrieves a specific question.
    *   **Authentication:** Likely required.
*   **PATCH/PUT /clinical_cases/:clinical_case_id/questions/:id**
    *   **Controller & Action:** `questions#update`
    *   **Description:** Updates a specific question.
    *   **Request Parameters:** Question attributes to update.
    *   **Authentication:** Likely required (Admin/Content Creator).
*   **DELETE /clinical_cases/:clinical_case_id/questions/:id**
    *   **Controller & Action:** `questions#destroy`
    *   **Description:** Deletes a specific question.
    *   **Authentication:** Likely required (Admin/Content Creator).

### Player Answers

*   **POST /player_answers**
    *   **Controller & Action:** `player_answers#create`
    *   **Description:** Submits an answer from a player for a question, likely within an exam context.
    *   **Request Parameters:** (e.g., `player_id`, `question_id`, `answer_id`, `exam_id`).
    *   **Authentication:** Likely required (Player).
*   **GET /player_answers**
    *   **Controller & Action:** `player_answers#index`
    *   **Description:** Retrieves a list of player answers, possibly filtered by player or exam.
    *   **Authentication:** Likely required (Player or Admin).

### Exams

*   **GET /exams**
    *   **Controller & Action:** `exams#index`
    *   **Description:** Retrieves a list of exams.
    *   **Authentication:** Likely required.
*   **POST /exams**
    *   **Controller & Action:** `exams#create`
    *   **Description:** Creates a new exam.
    *   **Request Parameters:** Exam attributes (e.g., `name`, `category_id`, list of `question_ids`).
    *   **Authentication:** Likely required (Admin/Content Creator).
*   **GET /exams/:id**
    *   **Controller & Action:** `exams#show`
    *   **Description:** Retrieves a specific exam, possibly including its questions.
    *   **Authentication:** Likely required.
*   **PATCH/PUT /exams/:id**
    *   **Controller & Action:** `exams#update`
    *   **Description:** Updates a specific exam.
    *   **Request Parameters:** Exam attributes to update.
    *   **Authentication:** Likely required (Admin/Content Creator).
*   **DELETE /exams/:id**
    *   **Controller & Action:** `exams#destroy`
    *   **Description:** Deletes a specific exam.
    *   **Authentication:** Likely required (Admin/Content Creator).

### Achievements (Gamification)

*   **GET /achievements**
    *   **Controller & Action:** `achievements#index`
    *   **Description:** Retrieves a list of all available achievements in the system.
    *   **Authentication:** Likely not required or user-level.
    *   **Response Fields (example):** `id`, `name`, `description`, `icon_url`, `points`. (Excludes `criteria`, `created_at`, `updated_at`).

*   **GET /players/:player_id/achievements**
    *   **Controller & Action:** `players/achievements#index`
    *   **Description:** Retrieves a list of achievements earned by a specific player.
    *   **Authentication:** Likely required (Owner or Admin).
    *   **Response Fields (example per achievement):** `id`, `name`, `description`, `icon_url`, `points`, `achieved_at`, `progress`. (Excludes `criteria` from base achievement, `created_at`, `updated_at`).

*Note: "Likely required" for authentication means that while not explicitly defined in routes.rb, standard practice for these types of actions would involve authentication and authorization checks in the respective controllers.*
