import '../models/fitness_models.dart';

class MockFitnessRepository {
  List<Exercise> exercises() {
    return [
      Exercise(
        id: 'ex_bench',
        name: 'Barbell Bench Press',
        primaryMuscle: 'Chest',
        equipment: 'Barbell',
      ),
      Exercise(
        id: 'ex_row',
        name: 'Barbell Row',
        primaryMuscle: 'Back',
        equipment: 'Barbell',
      ),
      Exercise(
        id: 'ex_squat',
        name: 'Back Squat',
        primaryMuscle: 'Legs',
        equipment: 'Barbell',
      ),
      Exercise(
        id: 'ex_deadlift',
        name: 'Deadlift',
        primaryMuscle: 'Posterior Chain',
        equipment: 'Barbell',
      ),
      Exercise(
        id: 'ex_ohp',
        name: 'Overhead Press',
        primaryMuscle: 'Shoulders',
        equipment: 'Barbell',
      ),
      Exercise(
        id: 'ex_pullup',
        name: 'Pull-up',
        primaryMuscle: 'Back',
        equipment: 'Bodyweight',
      ),
    ];
  }

  List<WorkoutTemplate> templates() {
    return [
      WorkoutTemplate(
        id: 'tpl_push',
        name: 'Push Day',
        exercises: [
          WorkoutExercise(
            exerciseId: 'ex_bench',
            sets: [
              WorkoutSet(reps: 8, weight: 60),
              WorkoutSet(reps: 8, weight: 60),
              WorkoutSet(reps: 6, weight: 65),
            ],
          ),
          WorkoutExercise(
            exerciseId: 'ex_ohp',
            sets: [
              WorkoutSet(reps: 8, weight: 35),
              WorkoutSet(reps: 8, weight: 35),
              WorkoutSet(reps: 6, weight: 37.5),
            ],
          ),
        ],
      ),
      WorkoutTemplate(
        id: 'tpl_pull',
        name: 'Pull Day',
        exercises: [
          WorkoutExercise(
            exerciseId: 'ex_row',
            sets: [
              WorkoutSet(reps: 10, weight: 50),
              WorkoutSet(reps: 10, weight: 50),
              WorkoutSet(reps: 8, weight: 55),
            ],
          ),
          WorkoutExercise(
            exerciseId: 'ex_pullup',
            sets: [
              WorkoutSet(reps: 8, weight: 0),
              WorkoutSet(reps: 7, weight: 0),
              WorkoutSet(reps: 6, weight: 0),
            ],
          ),
        ],
      ),
      WorkoutTemplate(
        id: 'tpl_legs',
        name: 'Leg Day',
        exercises: [
          WorkoutExercise(
            exerciseId: 'ex_squat',
            sets: [
              WorkoutSet(reps: 8, weight: 80),
              WorkoutSet(reps: 8, weight: 82.5),
              WorkoutSet(reps: 6, weight: 85),
            ],
          ),
          WorkoutExercise(
            exerciseId: 'ex_deadlift',
            sets: [
              WorkoutSet(reps: 5, weight: 100),
              WorkoutSet(reps: 5, weight: 105),
            ],
          ),
        ],
      ),
    ];
  }
}
