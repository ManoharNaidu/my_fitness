import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/fitness_provider.dart';

class ExercisesScreen extends StatelessWidget {
  const ExercisesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FitnessProvider>(
      builder: (context, fitness, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Exercise Library')),
          body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: fitness.exercises.length,
            itemBuilder: (context, index) {
              final exercise = fitness.exercises[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(exercise.name),
                  subtitle: Text(
                    '${exercise.primaryMuscle} • ${exercise.equipment}',
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'start') {
                        if (!fitness.hasActiveWorkout) {
                          fitness.startEmptyWorkout();
                        }
                        fitness.addExerciseToActiveWorkout(exercise.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Exercise added to active workout.'),
                          ),
                        );
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'start', child: Text('Quick add')),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
