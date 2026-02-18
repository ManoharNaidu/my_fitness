import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/providers/fitness_provider.dart';
import 'src/screens/auth_screen.dart';
import 'src/screens/home_shell_screen.dart';
import 'src/theme/app_theme.dart';

void main() {
  runApp(const MyFitnessApp());
}

class MyFitnessApp extends StatelessWidget {
  const MyFitnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FitnessProvider()..seed(),
      child: MaterialApp(
        title: 'My Fitness',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const _AppEntryScreen(),
      ),
    );
  }
}

class _AppEntryScreen extends StatelessWidget {
  const _AppEntryScreen();

  @override
  Widget build(BuildContext context) {
    return Consumer<FitnessProvider>(
      builder: (context, fitness, _) {
        if (fitness.isBootstrapping) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!fitness.isAuthenticated) {
          return const AuthScreen();
        }

        return const HomeShellScreen();
      },
    );
  }
}
