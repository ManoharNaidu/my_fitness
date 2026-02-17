# Strong-Inspired Fitness App (Flutter)

This project is a Strong-inspired workout tracker built with Flutter.

## Implemented Feature Set

### 1) Workout Flow
- Quick Start workout
- Start from templates (Push / Pull / Legs demo templates)
- Active workout screen with:
  - elapsed timer
  - rest timer controls
  - set logging (reps, weight, set type)
  - mark set complete
  - add sets
  - add exercises during workout
  - finish workout and push to history

### 2) App Structure & UX
- Bottom navigation shell (Workout / History / Exercises / Profile)
- Smooth tab transitions via `AnimatedSwitcher`
- Smooth route transition into active workout
- Clean dark UI theme and card-based layout

### 3) Insights / History
- Workout history list
- Session duration and volume summary
- Insight cards:
  - completed workouts
  - total volume
  - average duration
- 7-day trend preview chart (UI demo)

### 4) Exercise Library & Settings
- Exercise library list with quick-add to active workout
- Profile/settings screen:
  - completed workouts
  - adjustable default rest timer
  - sync status placeholder

## Current Architecture

```
lib/
  main.dart
  src/
    data/mock_fitness_repository.dart
    models/fitness_models.dart
    providers/fitness_provider.dart
    screens/
      home_shell_screen.dart
      workout_screen.dart
      active_workout_screen.dart
      history_screen.dart
      exercises_screen.dart
      profile_screen.dart
    theme/app_theme.dart
    utils/formatters.dart
```

- **State management:** `provider`
- **Data source:** local mock repository (in-memory)
- **Pattern:** UI screens + central provider + model layer

## Run the App

```bash
flutter pub get
flutter run
```

## Suggested Production API Design

Base URL: `/v1`

### Auth & User
- `POST /auth/register`
- `POST /auth/login`
- `GET /users/me`
- `PATCH /users/me/preferences` (units, rest timer default, theme)

### Exercises
- `GET /exercises?query=&muscle=&equipment=`
- `GET /exercises/{exerciseId}`
- `POST /exercises` (custom exercise)
- `PATCH /exercises/{exerciseId}`
- `DELETE /exercises/{exerciseId}`

### Templates / Routines
- `GET /templates`
- `POST /templates`
- `GET /templates/{templateId}`
- `PATCH /templates/{templateId}`
- `DELETE /templates/{templateId}`

### Workout Sessions
- `POST /sessions/start`
- `PATCH /sessions/{sessionId}` (live updates / autosave)
- `POST /sessions/{sessionId}/finish`
- `GET /sessions?from=&to=&templateId=`
- `GET /sessions/{sessionId}`

### Analytics
- `GET /analytics/overview?range=7d|30d|12w`
- `GET /analytics/volume?exerciseId=&range=`
- `GET /analytics/progression?exerciseId=&metric=1rm|volume|weight`

## Suggested Database Structure (PostgreSQL)

### Core Tables

1. `users`
- `id` (uuid, pk)
- `email` (unique)
- `password_hash`
- `display_name`
- `units` (kg/lb)
- `default_rest_seconds`
- `created_at`, `updated_at`

2. `exercises`
- `id` (uuid, pk)
- `owner_user_id` (nullable, null = global catalog)
- `name`
- `primary_muscle`
- `equipment`
- `is_custom`
- `created_at`, `updated_at`

3. `templates`
- `id` (uuid, pk)
- `user_id` (fk users.id)
- `name`
- `notes`
- `created_at`, `updated_at`

4. `template_exercises`
- `id` (uuid, pk)
- `template_id` (fk templates.id)
- `exercise_id` (fk exercises.id)
- `sort_order`

5. `template_sets`
- `id` (uuid, pk)
- `template_exercise_id` (fk template_exercises.id)
- `set_order`
- `target_reps`
- `target_weight`
- `set_type` (normal/warmup/failure/drop)

6. `sessions`
- `id` (uuid, pk)
- `user_id` (fk users.id)
- `template_id` (nullable fk templates.id)
- `template_name_snapshot`
- `status` (active/completed/cancelled)
- `started_at`
- `ended_at`
- `duration_seconds`
- `notes`

7. `session_exercises`
- `id` (uuid, pk)
- `session_id` (fk sessions.id)
- `exercise_id` (fk exercises.id)
- `sort_order`

8. `session_sets`
- `id` (uuid, pk)
- `session_exercise_id` (fk session_exercises.id)
- `set_order`
- `reps`
- `weight`
- `completed`
- `set_type`
- `rpe` (nullable)

### Useful Indexes
- `sessions(user_id, started_at desc)`
- `session_sets(session_exercise_id, set_order)`
- `exercises(owner_user_id, name)`
- `templates(user_id, updated_at desc)`

## Next Up (to reach full Strong-level parity)
- Supersets, warmup calculators, plate calculator
- Exercise PR pages and detailed charts
- Cloud sync conflict resolution
- Offline persistence (SQLite/Isar) + background sync
- Social/community and coaching features (if needed)
