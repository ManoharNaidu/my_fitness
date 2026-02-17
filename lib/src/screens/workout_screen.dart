import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/fitness_provider.dart';
import 'active_workout_screen.dart';

class WorkoutScreen extends StatelessWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FitnessProvider>(
      builder: (context, fitness, _) {
        return CustomScrollView(
          slivers: [
            const SliverAppBar(pinned: true, title: Text('Workout')),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _QuickStartCard(
                      onStart: () {
                        fitness.startEmptyWorkout();
                        Navigator.of(context).push(_activeWorkoutRoute());
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Text(
                          'Templates',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.builder(
                itemCount: fitness.templates.length,
                itemBuilder: (context, index) {
                  final template = fitness.templates[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(14),
                      title: Text(template.name),
                      subtitle: Text('${template.exercises.length} exercises'),
                      trailing: const Icon(Icons.play_arrow_rounded),
                      onTap: () {
                        fitness.startWorkoutFromTemplate(template.id);
                        Navigator.of(context).push(_activeWorkoutRoute());
                      },
                    ),
                  );
                },
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
        );
      },
    );
  }

  Route<void> _activeWorkoutRoute() {
    return MaterialPageRoute<void>(builder: (_) => const ActiveWorkoutScreen());
  }
}

class _QuickStartCard extends StatelessWidget {
  const _QuickStartCard({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF58E6A9), Color(0xFF36C2CF)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Start Workout',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Track sets, reps, rest timer, and notes with a Strong-inspired flow.',
            style: TextStyle(color: Colors.black87),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            onPressed: onStart,
            icon: const Icon(Icons.fitness_center),
            label: const Text('Quick Start'),
          ),
        ],
      ),
    );
  }
}
