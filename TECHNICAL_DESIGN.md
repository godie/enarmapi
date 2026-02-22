# Technical Design - New Modules

This document outlines the architecture for the new Flashcards and Specialist Connection modules.

## 1. Flashcards Module (Spaced Repetition System)

### Data Model
*   **`Flashcard`**: Stores the content of the cards.
    *   `front`: Text (Question/Fact)
    *   `back`: Text (Answer/Explanation)
    *   `category_id`: Reference to a medical category.
    *   `user_id`: Reference to the creator (optional, for user-generated content).
*   **`UserFlashcard`**: Tracks a user's progress with a specific card.
    *   `user_id`: Reference to the student.
    *   `flashcard_id`: Reference to the card.
    *   `next_review`: DateTime when the card should be shown again.
    *   `interval`: Number of days until next review.
    *   `ease_factor`: Multiplier for the interval (default: 2.5).
    *   `repetitions`: Consecutive correct answers.
    *   `status`: (new, learning, reviewing, mastered).

### API Endpoints
*   `GET /flashcards`: List available flashcards (filterable by category).
*   `GET /flashcards/due`: Get flashcards due for review for the current user.
*   `POST /flashcards/:id/review`: Submit a review (rating from 1-5) and update SRS parameters.

---

## 2. Specialist Connection Module

### Data Model
*   **`User` Role Expansion**: Add `specialist` to the `role` enum.
*   **`SpecialistProfile`**: Detailed info for doctors offering advice.
    *   `user_id`: Reference to the user.
    *   `specialty`: String.
    *   `bio`: Text.
    *   `enarm_score`: Integer (optional, for validation).
    *   `is_verified`: Boolean (admin-set).
*   **`Message`**: Simple messaging system for connection.
    *   `sender_id`: Reference to User.
    *   `receiver_id`: Reference to User.
    *   `content`: Text.
    *   `read_at`: DateTime (null if unread).

### API Endpoints
*   `GET /specialists`: List verified specialists with their profiles.
*   `GET /specialists/:id`: Detail view of a specialist.
*   `POST /messages`: Send a message to another user (specialist or student).
*   `GET /messages`: List conversations for the current user.
*   `GET /messages/:user_id`: History of messages with a specific user.

---

## 3. Future Scalability: Payments
*   When a student wants to "unlock" advanced mentorship, the `SpecialistProfile` can include a `price_per_consultation` and integrate with a payment gateway (e.g., Stripe) in a future phase.
