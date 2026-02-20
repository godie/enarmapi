# Enarm API

## 1. Overview

Enarm API is a backend application designed to support a medical quiz and training platform. It provides functionalities for managing users, medical categories, clinical cases, questions, exams, and player progress.

## 2. Prerequisites

To run this project, you will need the following software installed:

-   Docker
-   Docker Compose (Recommended for local development, optional if you manage services like PostgreSQL separately)

## 3. Getting Started

### 3.1. Clone the Repository

```bash
git clone https://github.com/godie/enarmapi.git enarmapi
cd enarmapi
```

### 3.2. Configuration

-   **Database:** Database connection details are defined in `config/database.yml`. These settings can be overridden using environment variables (e.g., `DATABASE_HOST`, `DATABASE_USER`, `DATABASE_PASSWORD`, `DATABASE_PORT`, `DATABASE_DB`).
-   **Rails Master Key:** The application uses Rails encrypted credentials (`config/credentials.yml.enc`).
    -   The `RAILS_MASTER_KEY` environment variable must be available to the application when it runs.

### 3.3. Building and Running with Docker Compose (Development)

1.  **Prepare services:**
    ```bash
    docker-compose up -d database admin
    ```
2.  **Wait for the database** to initialize.
3.  **Prepare the database:**
    ```bash
    docker-compose run --rm app bundle exec rails db:prepare
    ```
4.  **Start the application:**
    ```bash
    docker-compose up -d app
    ```
5.  Access the application at `http://localhost:3000`.

## 4. Running Tests

Tests should be run against the test database.

```bash
docker-compose run --rm app bundle exec rails test
```

## 5. API Documentation

This document outlines the available API endpoints for the Enarm API application.

### Health Check

*   **GET /up**
    *   **Description:** Returns a 200 status if the application is running correctly.
    *   **Authentication:** Not required.

### Authentication

*   **POST /users/login**
    *   **Description:** Authenticates a user with email/username and password. Returns a JWT token and user info.
    *   **Parameters:** `email`, `password`.
    *   **Authentication:** Not required.

*   **POST /users/google_login**
    *   **Description:** Authenticates or creates a user using Google credentials.
    *   **Parameters:** `google_id`, `email`, `name`.
    *   **Authentication:** Not required.

### Users & Stats

*   **GET /users**
    *   **Description:** Retrieves a list of users.
    *   **Authentication:** Admin.
*   **POST /users**
    *   **Description:** Creates a new user (Signup).
    *   **Authentication:** Not required.
*   **GET /users/:id**
    *   **Description:** Retrieves a specific user.
    *   **Authentication:** Owner or Admin.
*   **PATCH/PUT /users/:id**
    *   **Description:** Updates a specific user.
    *   **Authentication:** Owner or Admin.
*   **DELETE /users/:id**
    *   **Description:** Deletes a specific user.
    *   **Authentication:** Admin.
*   **GET /users/me/stats**
    *   **Description:** Retrieves statistics for the authenticated user (accuracy, total answers, points).
    *   **Authentication:** Required.

### Leaderboard

*   **GET /leaderboard**
    *   **Description:** Retrieves the top 10 users ranked by achievement points.
    *   **Authentication:** Not required.

### Categories

*   **GET /categories**
    *   **Description:** Retrieves a list of categories.
*   **POST /categories**
    *   **Description:** Creates a new category.
    *   **Authentication:** Admin.
*   **GET /categories/:id**
    *   **Description:** Retrieves a specific category.
*   **PATCH/PUT /categories/:id**
    *   **Description:** Updates a specific category.
    *   **Authentication:** Admin.
*   **DELETE /categories/:id**
    *   **Description:** Deletes a specific category.
    *   **Authentication:** Admin.

### Clinical Cases

*   **GET /clinical_cases**
    *   **Description:** Retrieves a list of clinical cases.
*   **POST /clinical_cases**
    *   **Description:** Creates a new clinical case.
    *   **Authentication:** Admin.
*   **GET /clinical_cases/:id**
    *   **Description:** Retrieves a specific clinical case including its questions.
*   **PATCH/PUT /clinical_cases/:id**
    *   **Description:** Updates a specific clinical case.
    *   **Authentication:** Admin.
*   **DELETE /clinical_cases/:id**
    *   **Description:** Deletes a specific clinical case.
    *   **Authentication:** Admin.

### Questions

*   **GET /questions**
    *   **Description:** Retrieves a list of questions.
*   **POST /questions**
    *   **Description:** Creates a new question.
    *   **Authentication:** Admin.
*   **GET /questions/:id**
    *   **Description:** Retrieves a specific question with its answers.
*   **PATCH/PUT /questions/:id**
    *   **Description:** Updates a specific question.
    *   **Authentication:** Admin.
*   **DELETE /questions/:id**
    *   **Description:** Deletes a specific question.
    *   **Authentication:** Admin.

### Practice Answers

*   **POST /user_answers** (Alias: `/player_answers`)
    *   **Description:** Submits answers for questions in practice mode. Returns immediate feedback and explanations.
    *   **Request body:** `{ "user_answers": [{ "question_id": 1, "answer_id": 2 }, ...] }`
    *   **Authentication:** Required.
*   **GET /user_answers** (Alias: `/player_answers`)
    *   **Description:** Retrieves the history of answers for the authenticated user.
    *   **Authentication:** Required.

### Exams

*   **GET /exams**
    *   **Description:** Retrieves a list of available exams.
*   **POST /exams**
    *   **Description:** Creates a new exam.
    *   **Authentication:** Admin.
*   **GET /exams/:id**
    *   **Description:** Retrieves a specific exam.
*   **PATCH/PUT /exams/:id**
    *   **Description:** Updates a specific exam.
    *   **Authentication:** Admin.
*   **DELETE /exams/:id**
    *   **Description:** Deletes a specific exam.
    *   **Authentication:** Admin.

### User Exam Attempts

*   **GET /user_exams**
    *   **Description:** Retrieves the history of exams taken by the authenticated user.
*   **POST /user_exams**
    *   **Description:** Starts a new exam attempt.
    *   **Parameters:** `exam_id`.
*   **GET /user_exams/:id**
    *   **Description:** Retrieves details of a specific exam attempt, including questions.
*   **PATCH/PUT /user_exams/:id**
    *   **Description:** Submits answers for an exam and completes it.
    *   **Parameters:** `{ "answers": [{ "exam_question_id": 1, "answer_id": 2 }, ...] }`

### Achievements

*   **GET /achievements**
    *   **Description:** Retrieves a list of all available achievements.
*   **GET /users/:user_id/achievements** (Alias: `/players/:player_id/achievements`)
    *   **Description:** Retrieves achievements earned by a specific user.
    *   **Authentication:** Owner or Admin.

### AI Integration

*   **POST /ai/generate_question**
    *   **Description:** Generates a new medical question using AI based on a prompt. Includes explanations for answers.
    *   **Parameters:** `prompt`.
    *   **Authentication:** Admin.
*   **POST /ai/generate_clinical_case**
    *   **Description:** Generates a new clinical case with associated questions using AI.
    *   **Parameters:** `prompt`.
    *   **Authentication:** Admin.
