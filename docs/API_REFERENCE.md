# Enarm API Reference

## Base URL

- Local: `http://localhost:3000`

## Common Headers

- `Content-Type: application/json` for `POST`, `PATCH`, and `PUT` with JSON body.
- `Authorization: Bearer <JWT>` for protected endpoints.

Example:

```http
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
Content-Type: application/json
```

## Authentication and Users

### POST `/users/login`
- Purpose: Login with email/username + password.
- Required headers: `Content-Type: application/json`
- Status codes: `200`, `401`
- Example response (`200`):
```json
{
  "id": 12,
  "name": "Ana",
  "email": "ana@example.com",
  "username": "ana",
  "role": "player",
  "preferences": {},
  "token": "jwt-token"
}
```

### POST `/users/google_login`
- Purpose: Login/signup with Google identity.
- Required headers: `Content-Type: application/json`
- Body: `google_id`, `email`, `name`
- Status codes: `200`, `201`, `422`
- Example response (`201`):
```json
{
  "id": 15,
  "name": "Google User",
  "email": "google.user@example.com",
  "username": null,
  "role": "player",
  "preferences": {},
  "token": "jwt-token"
}
```

### POST `/users/facebook_login`
- Purpose: Login/signup with Facebook identity.
- Required headers: `Content-Type: application/json`
- Body: `facebook_id`, `email`, `name`
- Status codes: `200`, `201`, `422`
- Example response (`200`):
```json
{
  "id": 9,
  "name": "FB User",
  "email": "fb.user@example.com",
  "username": "fbuser",
  "role": "player",
  "preferences": {},
  "token": "jwt-token"
}
```

### GET `/users`
- Purpose: List users (admin only).
- Required headers: `Authorization: Bearer <JWT>`
- Status codes: `200`, `401`, `403`
- Example response (`200`):
```json
[
  { "id": 1, "email": "admin@example.com", "role": "admin" },
  { "id": 2, "email": "player@example.com", "role": "player" }
]
```

### POST `/users`
- Purpose: Register a new user (or return existing by email).
- Required headers: `Content-Type: application/json`
- Status codes: `200`, `201`, `422`, `400`
- Example response (`201`):
```json
{
  "id": 22,
  "name": "Nuevo Usuario",
  "email": "nuevo@example.com",
  "username": "nuevo",
  "role": "player",
  "preferences": {},
  "token": "jwt-token"
}
```

### GET `/users/:id`
- Purpose: Get user profile (owner/admin).
- Required headers: `Authorization: Bearer <JWT>`
- Status codes: `200`, `401`, `404`
- Example response (`200`):
```json
{
  "id": 22,
  "name": "Nuevo Usuario",
  "email": "nuevo@example.com",
  "username": "nuevo",
  "role": "player",
  "preferences": {},
  "token": "jwt-token"
}
```

### PUT/PATCH `/users/:id`
- Purpose: Update user profile (owner/admin).
- Required headers: `Authorization: Bearer <JWT>`, `Content-Type: application/json`
- Status codes: `200`, `401`, `404`, `422`
- Example response (`200`):
```json
{
  "id": 22,
  "name": "Nuevo Nombre",
  "email": "nuevo@example.com",
  "username": "nuevo",
  "role": "player",
  "preferences": {},
  "token": "jwt-token"
}
```

### DELETE `/users/:id`
- Purpose: Delete user (admin only).
- Required headers: `Authorization: Bearer <JWT>`
- Status codes: `204`, `401`, `403`, `404`
- Example response (`204`): no body.

### GET `/users/me/stats`
- Purpose: Get current user stats.
- Required headers: `Authorization: Bearer <JWT>`
- Status codes: `200`, `401`
- Example response (`200`):
```json
{
  "total_answers": 120,
  "correct_answers": 89,
  "incorrect_answers": 31,
  "accuracy_percentage": 74.17,
  "questions_answered": 90,
  "last_activity": "2026-02-28T15:41:00Z",
  "total_points": 350
}
```

### GET `/users/me/contributions`
- Purpose: Get clinical cases created by current user.
- Required headers: `Authorization: Bearer <JWT>`
- Status codes: `200`, `401`
- Example response (`200`):
```json
{
  "contributions": [
    { "id": 4, "name": "Caso clínico 1", "category_id": 2 }
  ]
}
```

## Legacy Player Aliases

- `POST /players/login` -> same as `/users/login`
- `POST /players/google_login` -> same as `/users/google_login`
- `POST /players/facebook_login` -> same as `/users/facebook_login`
- `GET /players/:player_id/achievements` -> same data contract as `/users/:user_id/achievements`

## Categories

### GET `/categories`
- Purpose: List categories.
- Required headers: none
- Status codes: `200`
- Example response (`200`):
```json
[
  { "id": 1, "name": "Cardiología", "description": "..." }
]
```

### POST `/categories`
- Purpose: Create category (admin only).
- Required headers: `Authorization: Bearer <JWT>`, `Content-Type: application/json`
- Status codes: `201`, `401`, `403`, `422`, `400`
- Example response (`201`):
```json
{ "id": 8, "name": "Neurología", "description": "..." }
```

### GET `/categories/:id`
- Purpose: Get category detail.
- Required headers: none
- Status codes: `200`, `404`
- Example response (`200`):
```json
{ "id": 1, "name": "Cardiología", "description": "..." }
```

### PUT/PATCH `/categories/:id`
- Purpose: Update category (admin only).
- Required headers: `Authorization: Bearer <JWT>`, `Content-Type: application/json`
- Status codes: `200`, `401`, `403`, `404`, `422`
- Example response (`200`):
```json
{ "id": 1, "name": "Cardiología", "description": "Actualizada" }
```

### DELETE `/categories/:id`
- Purpose: Route exists for deleting categories.
- Required headers: `Authorization: Bearer <JWT>`
- Status codes: currently inconsistent in code because `destroy` action is not implemented in `CategoriesController`.
- Example response: implementation pending.

## Clinical Cases

### GET `/clinical_cases`
- Purpose: List clinical cases, paginated, with optional filters by `category_id` and name search (`q`).
- Required headers: `Authorization: Bearer <JWT>`
- Status codes: `200`, `401`
- Example response (`200`):
```json
{
  "current_page": 1,
  "per_page": 30,
  "total_entries": 120,
  "clinical_cases": [{ "id": 10, "name": "Caso 10", "status": "approved" }]
}
```

Optional query params:

- `page`: page number
- `category_id`: filter by specialty/category
- `q`: case-insensitive match against clinical case name

### GET `/categories/:category_id/clinical_cases`
- Purpose: List clinical cases for a category.
- Required headers: `Authorization: Bearer <JWT>`
- Status codes: `200`, `401`
- Example response (`200`): same shape as `/clinical_cases`.

### GET `/clinical_cases/:id`
- Purpose: Get one clinical case with nested questions/answers.
- Required headers: `Authorization: Bearer <JWT>`
- Status codes: `200`, `401`, `404`
- Example response (`200`):
```json
{
  "id": 10,
  "name": "Caso 10",
  "questions": [
    {
      "id": 88,
      "text": "Pregunta",
      "answers": [{ "id": 301, "text": "Respuesta A", "is_correct": false }]
    }
  ]
}
```

### POST `/clinical_cases`
- Purpose: Create clinical case (authenticated user; non-admin is forced to `pending`).
- Required headers: `Authorization: Bearer <JWT>`, `Content-Type: application/json`
- Status codes: `201`, `401`, `422`, `400`
- Example response (`201`):
```json
{
  "id": 101,
  "name": "clinical_case_a1b2",
  "status": "pending",
  "category_id": 2
}
```

Image validation rules (when uploading image):

- Allowed MIME types: `image/png`, `image/jpeg`
- Max size: `5 MB`
- Validation errors are returned as `422` in `image` field.

### PUT/PATCH `/clinical_cases/:id`
- Purpose: Update clinical case (admin only).
- Required headers: `Authorization: Bearer <JWT>`, `Content-Type: application/json`
- Status codes: `200`, `401`, `403`, `404`, `422`
- Example response (`200`):
```json
{ "id": 101, "name": "Caso actualizado", "status": "approved" }
```

Image validation rules for update are the same as create:

- Allowed MIME types: `image/png`, `image/jpeg`
- Max size: `5 MB`

### DELETE `/clinical_cases/:id`
- Purpose: Delete clinical case (admin only).
- Required headers: `Authorization: Bearer <JWT>`
- Status codes: `204`, `401`, `403`, `404`
- Example response (`204`): no body.

## Questions

### GET `/questions`
- Purpose: List questions, paginated, optionally filtered by `clinical_case_id` or `category_id` (admin only).
- Required headers: `Authorization: Bearer <JWT>`
- Status codes: `200`, `401`, `403`, `404`
- Example response (`200`):
```json
{
  "current_page": 1,
  "per_page": 30,
  "total_entries": 200,
  "questions": [
    {
      "id": 55,
      "text": "Pregunta",
      "clinical_case_id": 98,
      "answers": [{ "id": 1, "text": "A", "is_correct": false }]
    }
  ]
}
```

### GET `/questions/:id`
- Purpose: Get one question with answers (admin only).
- Required headers: `Authorization: Bearer <JWT>`
- Status codes: `200`, `401`, `403`, `404`
- Example response (`200`):
```json
{
  "id": 55,
  "text": "Pregunta",
  "answers": [{ "id": 1, "text": "A", "is_correct": false }]
}
```

### POST `/questions`
- Purpose: Create question with optional nested answers (admin only).
- Required headers: `Authorization: Bearer <JWT>`, `Content-Type: application/json`
- Status codes: `201`, `401`, `403`, `422`, `400`
- Example response (`201`):
```json
{ "id": 56, "text": "Nueva pregunta" }
```

### PUT/PATCH `/questions/:id`
- Purpose: Update question (admin only).
- Required headers: `Authorization: Bearer <JWT>`, `Content-Type: application/json`
- Status codes: `200`, `401`, `403`, `404`, `422`
- Example response (`200`):
```json
{ "id": 56, "text": "Pregunta actualizada" }
```

### DELETE `/questions/:id`
- Purpose: Delete question (admin only).
- Required headers: `Authorization: Bearer <JWT>`
- Status codes: `204`, `401`, `403`, `404`
- Example response (`204`): no body.

## Exams

### GET `/exams`
- Purpose: List exams with exam questions (admin only).
- Required headers: `Authorization: Bearer <JWT>`
- Status codes: `200`, `401`, `403`
- Example response (`200`):
```json
[
  {
    "id": 2,
    "name": "Simulacro ENARM",
    "exam_questions": [{ "id": 11, "question_id": 55, "position": 1 }]
  }
]
```

### GET `/exams/:id`
- Purpose: Get one exam (admin only).
- Required headers: `Authorization: Bearer <JWT>`
- Status codes: `200`, `401`, `403`, `404`
- Example response (`200`):
```json
{
  "id": 2,
  "name": "Simulacro ENARM",
  "exam_questions": [{ "id": 11, "question_id": 55, "position": 1 }]
}
```

### POST `/exams`
- Purpose: Create exam (admin only).
- Required headers: `Authorization: Bearer <JWT>`, `Content-Type: application/json`
- Status codes: `201`, `401`, `403`, `422`, `400`
- Example response (`201`):
```json
{ "id": 3, "name": "Examen nuevo", "category_id": 1 }
```

### PUT/PATCH `/exams/:id`
- Purpose: Update exam (admin only).
- Required headers: `Authorization: Bearer <JWT>`, `Content-Type: application/json`
- Status codes: `200`, `401`, `403`, `404`, `422`
- Example response (`200`):
```json
{ "id": 3, "name": "Examen actualizado" }
```

### DELETE `/exams/:id`
- Purpose: Delete exam (admin only).
- Required headers: `Authorization: Bearer <JWT>`
- Status codes: `204`, `401`, `403`, `404`
- Example response (`204`): no body.

## Practice Answers

### POST `/user_answers` (alias: `/player_answers`)
- Purpose: Submit one or more practice answers and get feedback.
- Required headers: `Authorization: Bearer <JWT>`, `Content-Type: application/json`
- Status codes: `201`, `401`, `422`, `400`
- Example response (`201`):
```json
{
  "message": "Respuestas guardadas correctamente!",
  "results": [
    {
      "question_id": 55,
      "answer_id": 1,
      "is_correct": false,
      "explanation": "Explicación de la opción elegida",
      "correct_answer": {
        "id": 2,
        "text": "Opción correcta",
        "explanation": "Explicación correcta"
      }
    }
  ],
  "unlocked_achievements": [{ "id": 3, "name": "Racha de 10" }]
}
```

### GET `/user_answers` (alias: `/player_answers`)
- Purpose: Get answer history of authenticated user.
- Required headers: `Authorization: Bearer <JWT>`
- Status codes: `200`, `401`
- Example response (`200`):
```json
[
  { "id": 1, "question_id": 55, "answer_id": 1, "is_correct": false }
]
```

## User Exams

### GET `/user_exams`
- Purpose: List exam attempts of authenticated user.
- Required headers: `Authorization: Bearer <JWT>`
- Status codes: `200`, `401`
- Example response (`200`):
```json
[
  { "id": 7, "exam_id": 2, "status": "completed", "score": 68.5 }
]
```

### GET `/user_exams/:id`
- Purpose: Get one exam attempt with exam content + submitted answers.
- Required headers: `Authorization: Bearer <JWT>`
- Status codes: `200`, `401`, `404`
- Example response (`200`):
```json
{
  "id": 7,
  "status": "in_progress",
  "exam": {
    "id": 2,
    "exam_questions": [
      {
        "id": 11,
        "question": {
          "id": 55,
          "text": "Pregunta",
          "answers": [{ "id": 1, "text": "A", "is_correct": false }]
        }
      }
    ]
  },
  "user_exam_answers": []
}
```

### POST `/user_exams`
- Purpose: Start a new exam attempt.
- Required headers: `Authorization: Bearer <JWT>`, `Content-Type: application/json`
- Body: `exam_id`
- Status codes: `201`, `401`, `404`, `422`
- Example response (`201`):
```json
{
  "id": 8,
  "exam_id": 2,
  "status": "in_progress",
  "started_at": "2026-02-28T16:00:00Z"
}
```

### PUT/PATCH `/user_exams/:id`
- Purpose: Submit answers and complete exam attempt.
- Required headers: `Authorization: Bearer <JWT>`, `Content-Type: application/json`
- Status codes: `200`, `401`, `404`, `422`, `500`
- Example response (`200`):
```json
{
  "user_exam": { "id": 8, "status": "completed", "score": 72.0 },
  "score": 72.0,
  "unlocked_achievements": [{ "id": 5, "name": "Primer examen" }]
}
```

## Achievements

### GET `/achievements`
- Purpose: List achievement catalog.
- Required headers: none
- Status codes: `200`
- Example response (`200`):
```json
[
  { "id": 1, "name": "Primer paso", "description": "Responder 1 pregunta", "points": 10 }
]
```

### POST `/achievements`
- Purpose: Create achievement (admin only).
- Required headers: `Authorization: Bearer <JWT>`, `Content-Type: application/json`
- Status codes: `201`, `401`, `403`, `422`, `400`
- Example response (`201`):
```json
{ "id": 12, "name": "Racha 50", "description": "50 correctas", "points": 100 }
```

### PUT/PATCH `/achievements/:id`
- Purpose: Update achievement (admin only).
- Required headers: `Authorization: Bearer <JWT>`, `Content-Type: application/json`
- Status codes: `200`, `401`, `403`, `404`, `422`
- Example response (`200`):
```json
{ "id": 12, "name": "Racha 50", "description": "50 correctas seguidas", "points": 120 }
```

### DELETE `/achievements/:id`
- Purpose: Delete achievement (admin only).
- Required headers: `Authorization: Bearer <JWT>`
- Status codes: `204`, `401`, `403`, `404`
- Example response (`204`): no body.

### GET `/users/:user_id/achievements`
- Purpose: List achievements unlocked by a user.
- Required headers: none
- Status codes: `200`, `404`
- Example response (`200`):
```json
[
  {
    "id": 1,
    "name": "Primer paso",
    "description": "Responder 1 pregunta",
    "points": 10,
    "achieved_at": "2026-02-10T10:00:00Z",
    "progress": 100
  }
]
```

## Flashcards

### GET `/flashcards`
- Purpose: List flashcards (optional `category_id` filter).
- Required headers: `Authorization: Bearer <JWT>`
- Status codes: `200`, `401`
- Example response (`200`):
```json
[
  { "id": 1, "question": "¿Qué es choque séptico?", "category_id": 2 }
]
```

### GET `/flashcards/:id`
- Purpose: Get one flashcard by ID.
- Required headers: `Authorization: Bearer <JWT>`
- Status codes: `200`, `401`, `404`
- Example response (`200`):
```json
{
  "id": 1,
  "question": "¿Qué es choque séptico?",
  "answer": "Disfunción orgánica por respuesta desregulada a infección",
  "category_id": 2
}
```

### GET `/flashcards/due`
- Purpose: List due flashcards for spaced repetition.
- Required headers: `Authorization: Bearer <JWT>`
- Status codes: `200`, `401`
- Example response (`200`):
```json
[
  {
    "id": 14,
    "flashcard_id": 1,
    "next_review_at": "2026-02-28T18:00:00Z",
    "flashcard": { "id": 1, "question": "¿Qué es choque séptico?" }
  }
]
```

### POST `/flashcards/:id/review`
- Purpose: Submit review quality score for a flashcard.
- Required headers: `Authorization: Bearer <JWT>`, `Content-Type: application/json`
- Body: `quality` (0-5)
- Status codes: `200`, `401`, `404`, `422`
- Example response (`200`):
```json
{
  "id": 14,
  "flashcard_id": 1,
  "interval": 3,
  "ease_factor": 2.5,
  "next_review_at": "2026-03-03T18:00:00Z"
}
```

## Specialists

### GET `/specialists`
- Purpose: List verified specialists.
- Required headers: `Authorization: Bearer <JWT>`
- Status codes: `200`, `401`
- Example response (`200`):
```json
[
  {
    "id": 3,
    "name": "Dra. Rivera",
    "specialist_profile": { "specialty": "Ginecología", "is_verified": true }
  }
]
```

### GET `/specialists/:id`
- Purpose: Get specialist profile.
- Required headers: `Authorization: Bearer <JWT>`
- Status codes: `200`, `401`, `404`
- Example response (`200`):
```json
{
  "id": 3,
  "name": "Dra. Rivera",
  "specialist_profile": { "specialty": "Ginecología", "is_verified": true }
}
```

## Messages

### GET `/messages`
- Purpose: List users with conversations with current user.
- Required headers: `Authorization: Bearer <JWT>`
- Status codes: `200`, `401`
- Example response (`200`):
```json
[
  { "id": 4, "name": "Dr. López", "email": "drlopez@example.com" }
]
```

### GET `/messages/:id`
- Purpose: Get conversation with user `:id` and mark received messages as read.
- Required headers: `Authorization: Bearer <JWT>`
- Status codes: `200`, `401`
- Example response (`200`):
```json
[
  { "id": 11, "sender_id": 2, "receiver_id": 4, "content": "Hola", "read_at": "2026-02-28T16:05:00Z" }
]
```

### POST `/messages`
- Purpose: Send message to another user.
- Required headers: `Authorization: Bearer <JWT>`, `Content-Type: application/json`
- Status codes: `201`, `401`, `422`, `400`
- Example response (`201`):
```json
{
  "id": 20,
  "sender_id": 2,
  "receiver_id": 4,
  "content": "Gracias por la asesoría"
}
```

## AI Endpoints (Admin)

### POST `/ai/generate_question`
- Purpose: Generate a medical question from prompt.
- Required headers: `Authorization: Bearer <JWT>`, `Content-Type: application/json`
- Status codes: `200`, `401`, `403`
- Example response (`200`):
```json
{
  "question": "Paciente con dolor torácico...",
  "answers": [{ "text": "A", "is_correct": true }]
}
```

### POST `/ai/generate_clinical_case`
- Purpose: Generate clinical case from prompt.
- Required headers: `Authorization: Bearer <JWT>`, `Content-Type: application/json`
- Status codes: `200`, `401`, `403`
- Example response (`200`):
```json
{
  "clinical_case": {
    "name": "Caso generado",
    "questions": [{ "text": "Pregunta 1" }]
  }
}
```

### POST `/ai/bulk_create_exam`
- Purpose: Parse PDF and create exam + questions + clinical cases.
- Required headers: `Authorization: Bearer <JWT>`
- Content type: `multipart/form-data`
- Required form fields: `file`, `category_id`
- Status codes: `201`, `400`, `401`, `403`, `422`
- Example response (`201`):
```json
{
  "id": 9,
  "name": "Examen desde PDF",
  "exam_questions": [
    {
      "id": 90,
      "question": {
        "id": 500,
        "text": "Pregunta importada",
        "answers": [{ "id": 1001, "text": "A", "is_correct": false }]
      }
    }
  ]
}
```

## Leaderboard and Health

### GET `/leaderboard`
- Purpose: Top 10 users by achievement points.
- Required headers: none
- Status codes: `200`
- Example response (`200`):
```json
[
  { "id": 2, "name": "Ana", "username": "ana", "total_points": 420 }
]
```

### GET `/up`
- Purpose: Health check endpoint.
- Required headers: none
- Status codes: `200`
- Example response (`200`):
```json
{ "status": "ok" }
```

## Error Format (Common)

- Unauthorized:
```json
{ "error": "No autorizado" }
```
- Forbidden:
```json
{ "error": "Acceso restringido a administradores" }
```
- Validation:
```json
{ "errors": ["Campo X no puede estar en blanco"] }
```
