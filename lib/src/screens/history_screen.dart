import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/fitness_provider.dart';
import '../utils/formatters.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FitnessProvider>(
      builder: (context, fitness, _) {
        final avgDuration = fitness.averageDuration();

        return CustomScrollView(
          slivers: [
            const SliverAppBar(pinned: true, title: Text('History & Insights')),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Workouts',
                            value: '${fitness.workoutsCompleted}',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(
                            label: 'Total Volume',
                            value:
                                '${fitness.totalVolume.toStringAsFixed(0)} kg',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _StatCard(
                      label: 'Avg Session Duration',
                      value: formatDuration(avgDuration),
                    ),
                    const SizedBox(height: 14),
                    _VolumePreview(volume: fitness.totalVolume),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.builder(
                itemCount: fitness.history.length,
                itemBuilder: (context, index) {
                  final session = fitness.history[index];
                  final duration = session.endedAt.difference(
                    session.startedAt,
                  );
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(14),
                      title: Text(session.templateName),
                      subtitle: Text(
                        '${session.startedAt.toLocal().toString().split(' ').first} • ${session.exercises.length} exercises • ${formatDuration(duration)}',
                      ),
                      trailing: Text(
                        '${fitness.sessionVolume(session).toStringAsFixed(0)} kg',
                      ),
                    ),
                  );
                },
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 18)),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F22),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}

class _VolumePreview extends StatelessWidget {
  const _VolumePreview({required this.volume});

  final double volume;

  @override
  Widget build(BuildContext context) {
    final bars = [0.45, 0.55, 0.4, 0.7, 0.52, 0.85, 0.65];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F22),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('7-Day Volume Trend'),
          const SizedBox(height: 8),
          SizedBox(
            height: 78,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: bars
                  .map(
                    (b) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: FractionallySizedBox(
                          alignment: Alignment.bottomCenter,
                          heightFactor: b,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xFF58E6A9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          Text('Current total: ${volume.toStringAsFixed(0)} kg'),
        ],
      ),
    );
  }
}
