import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/fitness_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FitnessProvider>(
      builder: (context, fitness, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Profile & Settings')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const _ProfileHeader(),
              const SizedBox(height: 16),
              if (fitness.apiEnabled)
                Card(
                  child: ListTile(
                    title: const Text('Signed In As'),
                    subtitle: Text(
                      fitness.currentUser != null
                          ? '${fitness.currentUser!.displayName} (${fitness.currentUser!.email})'
                          : 'Unknown user',
                    ),
                  ),
                ),
              Card(
                child: ListTile(
                  title: const Text('Completed Workouts'),
                  trailing: Text('${fitness.workoutsCompleted}'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Default Rest Timer'),
                  subtitle: Text('${fitness.restDurationSeconds} sec'),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Adjust Rest Duration'),
                      Slider(
                        value: fitness.restDurationSeconds.toDouble(),
                        min: 30,
                        max: 300,
                        divisions: 27,
                        label: '${fitness.restDurationSeconds}s',
                        onChanged: (value) {
                          fitness.setRestDuration(value.round());
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.cloud_sync),
                  title: const Text('Cloud Sync Status'),
                  subtitle: Text(
                    fitness.apiEnabled
                        ? 'Connected to API (${fitness.workoutsCompleted} synced workouts)'
                        : 'Local mock mode (offline-first fallback)',
                  ),
                ),
              ),
              if (fitness.lastSyncError != null)
                Card(
                  color: Colors.red.withValues(alpha: 0.12),
                  child: ListTile(
                    leading: const Icon(Icons.warning_amber_rounded),
                    title: const Text('Last Sync Error'),
                    subtitle: Text(fitness.lastSyncError!),
                  ),
                ),
              if (fitness.apiEnabled)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: ElevatedButton.icon(
                    onPressed: () => fitness.logout(),
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F22),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          CircleAvatar(radius: 26, child: Icon(Icons.person)),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Fitness User',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Intermediate • 4x / week',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
