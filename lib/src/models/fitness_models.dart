enum SetType { normal, warmup, failure, drop }

class Exercise {
  Exercise({
    required this.id,
    required this.name,
    required this.primaryMuscle,
    required this.equipment,
  });

  final String id;
  final String name;
  final String primaryMuscle;
  final String equipment;
}

class WorkoutSet {
  WorkoutSet({
    required this.reps,
    required this.weight,
    this.completed = false,
    this.type = SetType.normal,
  });

  int reps;
  double weight;
  bool completed;
  SetType type;
}

class WorkoutExercise {
  WorkoutExercise({required this.exerciseId, required this.sets});

  final String exerciseId;
  final List<WorkoutSet> sets;
}

class WorkoutTemplate {
  WorkoutTemplate({
    required this.id,
    required this.name,
    required this.exercises,
  });

  final String id;
  String name;
  final List<WorkoutExercise> exercises;
}

class WorkoutSession {
  WorkoutSession({
    required this.id,
    required this.templateName,
    required this.startedAt,
    required this.endedAt,
    required this.exercises,
  });

  final String id;
  final String templateName;
  final DateTime startedAt;
  final DateTime endedAt;
  final List<WorkoutExercise> exercises;
}
