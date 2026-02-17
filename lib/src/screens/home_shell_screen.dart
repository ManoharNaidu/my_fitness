import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/fitness_provider.dart';
import 'active_workout_screen.dart';
import 'exercises_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'workout_screen.dart';

class HomeShellScreen extends StatelessWidget {
  const HomeShellScreen({super.key});

  static final _tabs = [
    WorkoutScreen(),
    HistoryScreen(),
    ExercisesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<FitnessProvider>(
      builder: (context, fitness, _) {
        return Scaffold(
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: KeyedSubtree(
              key: ValueKey(fitness.selectedTab),
              child: _tabs[fitness.selectedTab],
            ),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: fitness.selectedTab,
            onDestinationSelected: fitness.changeTab,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.fitness_center),
                label: 'Workout',
              ),
              NavigationDestination(
                icon: Icon(Icons.bar_chart),
                label: 'History',
              ),
              NavigationDestination(
                icon: Icon(Icons.menu_book),
                label: 'Exercises',
              ),
              NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
            ],
          ),
          floatingActionButton: fitness.hasActiveWorkout
              ? FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.of(context).push(_activeWorkoutRoute());
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Resume'),
                )
              : null,
        );
      },
    );
  }

  Route<void> _activeWorkoutRoute() {
    return PageRouteBuilder<void>(
      pageBuilder: (context, animation, secondaryAnimation) =>
          const ActiveWorkoutScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final offset =
            Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offset, child: child),
        );
      },
    );
  }
}
