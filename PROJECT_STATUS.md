# Project Status and Improvements - Enarm API

This document provides an updated overview of the Enarm API project, its current state, architecture, and identified opportunities.

## Current State (Updated February 2025)

### Project Overview
Enarm API is a specialized backend for medical training, focusing on the ENARM (Examen Nacional para Aspirantes a Residencias Médicas). It supports complex medical case management, AI-driven content generation, and gamified learning.

### Technology Stack
*   **Backend:** Ruby on Rails 8.1.2 (Latest stable)
*   **Database:** MySQL 8.0 (Configured for `utf8mb4` for medical symbols and emojis)
*   **Web Server:** Puma 6.6+ (Configured for 3 threads by default)
*   **Authentication:** JWT (JSON Web Tokens) with support for Email/Password and Google Login.
*   **AI Integration:** Gemini AI (Google) for question generation, clinical case creation, and bulk PDF parsing.
*   **Containerization:** Docker & Docker Compose.

### Key Features
*   **Medical Content Hierarchy:** Categories -> Clinical Cases -> Questions -> Answers.
*   **Exam System:** Support for custom exams, time limits, passing scores, and attempt tracking.
*   **AI Engine:**
    *   Individual question/case generation via prompt.
    *   Bulk exam creation from PDF files (using Gemini-1.5-Flash).
*   **Gamification:** Achievement system and global Leaderboard based on performance.
*   **User Statistics:** Detailed tracking of accuracy, total answers, and category-specific progress.

### Database Schema (Active Tables)
*   `users`: Handles both `player` and `admin` roles. Includes `preferences` (JSON) and social IDs.
*   `categories`: Medical specialties.
*   `clinical_cases`: Narrative-based medical scenarios.
*   `questions` & `answers`: The core quiz components.
*   `exams` & `exam_questions`: Structured assessments.
*   `user_answers`: History of student performance in practice mode.
*   `user_exams` & `user_exam_answers`: History and results of formal exam attempts.
*   `achievements` & `user_achievements`: Gamification data.

---

## Technical Assessment

### Server Capacity
*   **Current Setup:** 1 Puma worker with 3 threads.
*   **Estimated Throughput:** On a standard T3.micro/small instance, this setup can handle approximately 40-60 requests per second (RPS) for standard API endpoints, depending on database I/O.
*   **Scalability:** Horizontal scaling can be easily achieved via Docker/Kubernetes. Vertical scaling is possible by increasing `RAILS_MAX_THREADS` and `WEB_CONCURRENCY` (workers) in the environment.

### Optimization Status
*   **Database:** Foreign keys are indexed. Composite indices are used for performance-critical queries (e.g., `user_answers`). Charset is `utf8mb4`.
*   **Code:**
    *   Uses Omakase Ruby styling (RuboCop).
    *   AI operations are abstracted into a service layer.
    *   JWT for stateless authentication, reducing DB load for session management.
*   **Identified Bottlenecks:** AI-powered endpoints are synchronous. High-volume PDF parsing can block Puma threads for several seconds.

### Optimization Recommendations
1.  **Background Jobs:** Move AI PDF parsing and large-scale exam generation to a background worker (e.g., Sidekiq or Rails 8's Solid Queue).
2.  **Caching:** Implement low-level caching for medical content that doesn't change frequently (categories, standardized clinical cases).
3.  **Connection Pool:** Ensure `RAILS_MAX_THREADS` matches the database pool size in `database.yml` (currently both default to 5 in `database.yml` and 3 in `puma.rb`).

---

## Planned Enhancements (Roadmap)

1.  **Flashcards Module:** Spaced repetition system for high-yield medical facts.
2.  **Specialist Network:** Connecting students with doctors who have already passed the ENARM for mentoring and advice.
3.  **Monetization Foundation:** Infrastructure to allow specialists to offer consulting services (starting with direct messaging).
4.  **Performance Improvements:** Implementation of background jobs for heavy AI tasks.
