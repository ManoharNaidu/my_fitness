import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/fitness_models.dart';
import '../providers/fitness_provider.dart';
import '../utils/formatters.dart';

class ActiveWorkoutScreen extends StatelessWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FitnessProvider>(
      builder: (context, fitness, _) {
        if (!fitness.hasActiveWorkout) {
          return Scaffold(
            appBar: AppBar(title: const Text('Active Workout')),
            body: const Center(child: Text('No active workout in progress.')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(fitness.activeTemplate?.name ?? 'Workout'),
            actions: [
              TextButton(
                onPressed: () {
                  fitness.finishWorkout();
                  Navigator.of(context).pop();
                },
                child: const Text('Finish'),
              ),
            ],
          ),
          body: Column(
            children: [
              _Header(fitness: fitness),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                  itemCount: fitness.activeExercises.length,
                  itemBuilder: (context, index) {
                    final exercise = fitness.activeExercises[index];
                    final exerciseInfo = fitness.exerciseById(
                      exercise.exerciseId,
                    );

                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exerciseInfo.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 10),
                            ...List.generate(exercise.sets.length, (setIdx) {
                              final set = exercise.sets[setIdx];
                              return _SetRow(
                                setNo: setIdx + 1,
                                set: set,
                                onTap: () => _showSetEditor(
                                  context,
                                  fitness,
                                  exercise.exerciseId,
                                  setIdx,
                                  set,
                                ),
                                onToggle: () => fitness.toggleSetComplete(
                                  exercise.exerciseId,
                                  setIdx,
                                ),
                              );
                            }),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: () =>
                                  fitness.addSet(exercise.exerciseId),
                              icon: const Icon(Icons.add),
                              label: const Text('Add Set'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddExerciseSheet(context, fitness),
            icon: const Icon(Icons.add),
            label: const Text('Exercise'),
          ),
        );
      },
    );
  }

  Future<void> _showSetEditor(
    BuildContext context,
    FitnessProvider fitness,
    String exerciseId,
    int setIndex,
    WorkoutSet set,
  ) async {
    final repsController = TextEditingController(text: set.reps.toString());
    final weightController = TextEditingController(
      text: formatWeight(set.weight),
    );
    SetType currentType = set.type;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit Set',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: repsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Reps'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: weightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Weight (kg)'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<SetType>(
                    initialValue: currentType,
                    decoration: const InputDecoration(labelText: 'Set Type'),
                    items: SetType.values
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(e.name.toUpperCase()),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => currentType = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final reps =
                            int.tryParse(repsController.text) ?? set.reps;
                        final weight =
                            double.tryParse(weightController.text) ??
                            set.weight;
                        fitness.updateSet(
                          exerciseId: exerciseId,
                          setIndex: setIndex,
                          reps: reps,
                          weight: weight,
                          type: currentType,
                        );
                        Navigator.of(context).pop();
                      },
                      child: const Text('Save'),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showAddExerciseSheet(
    BuildContext context,
    FitnessProvider fitness,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return ListView.builder(
          itemCount: fitness.exercises.length,
          itemBuilder: (context, index) {
            final ex = fitness.exercises[index];
            return ListTile(
              title: Text(ex.name),
              subtitle: Text('${ex.primaryMuscle} • ${ex.equipment}'),
              trailing: const Icon(Icons.add_circle_outline),
              onTap: () {
                fitness.addExerciseToActiveWorkout(ex.id);
                Navigator.of(context).pop();
              },
            );
          },
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.fitness});

  final FitnessProvider fitness;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          _Badge(
            label: 'Elapsed',
            value: formatDuration(fitness.elapsedWorkoutDuration),
          ),
          const SizedBox(width: 10),
          _Badge(
            label: 'Rest',
            value: fitness.restSecondsRemaining > 0
                ? formatDuration(
                    Duration(seconds: fitness.restSecondsRemaining),
                  )
                : 'Ready',
          ),
          const Spacer(),
          IconButton(
            onPressed: fitness.startRestTimer,
            icon: const Icon(Icons.timer),
            tooltip: 'Start Rest',
          ),
          IconButton(
            onPressed: fitness.stopRestTimer,
            icon: const Icon(Icons.timer_off),
            tooltip: 'Stop Rest',
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF242428),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.white70),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({
    required this.setNo,
    required this.set,
    required this.onTap,
    required this.onToggle,
  });

  final int setNo;
  final WorkoutSet set;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Text('Set $setNo'),
            const Spacer(),
            Text('${set.reps} reps • ${formatWeight(set.weight)} kg'),
            const SizedBox(width: 8),
            Text(
              set.type.name,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
            Checkbox(value: set.completed, onChanged: (_) => onToggle()),
          ],
        ),
      ),
    );
  }
}
