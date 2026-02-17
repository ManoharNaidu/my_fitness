import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../data/api_fitness_repository.dart';
import '../data/mock_fitness_repository.dart';
import '../models/fitness_models.dart';

class FitnessProvider extends ChangeNotifier {
  final MockFitnessRepository _repository = MockFitnessRepository();
  final ApiFitnessRepository _apiRepository = ApiFitnessRepository();

  List<Exercise> exercises = [];
  List<WorkoutTemplate> templates = [];
  final List<WorkoutSession> history = [];

  int selectedTab = 0;
  WorkoutTemplate? _activeTemplate;
  List<WorkoutExercise> _activeExercises = [];
  DateTime? _workoutStartedAt;
  DateTime? _restUntil;
  Timer? _ticker;
  int? _activeSessionId;
  bool _apiEnabled = false;
  String? _lastSyncError;

  int restDurationSeconds = 90;

  WorkoutTemplate? get activeTemplate => _activeTemplate;
  List<WorkoutExercise> get activeExercises => _activeExercises;
  bool get hasActiveWorkout => _workoutStartedAt != null;
  bool get apiEnabled => _apiEnabled;
  String? get lastSyncError => _lastSyncError;

  Duration get elapsedWorkoutDuration {
    if (_workoutStartedAt == null) return Duration.zero;
    return DateTime.now().difference(_workoutStartedAt!);
  }

  int get restSecondsRemaining {
    if (_restUntil == null) return 0;
    return max(0, _restUntil!.difference(DateTime.now()).inSeconds);
  }

  void seed() {
    if (AppConfig.enableApi) {
      _seedMockData();
      unawaited(_loadFromApi());
      return;
    }

    _seedMockData();
  }

  void _seedMockData() {
    exercises = _repository.exercises();
    templates = _repository.templates();
    history.clear();

    final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
    history.add(
      WorkoutSession(
        id: 'session_seed_1',
        templateName: 'Push Day',
        startedAt: twoDaysAgo,
        endedAt: twoDaysAgo.add(const Duration(minutes: 58)),
        exercises: _cloneExercises(
          templates.first.exercises,
          allCompleted: true,
        ),
      ),
    );

    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    history.add(
      WorkoutSession(
        id: 'session_seed_2',
        templateName: 'Leg Day',
        startedAt: yesterday,
        endedAt: yesterday.add(const Duration(minutes: 70)),
        exercises: _cloneExercises(
          templates.last.exercises,
          allCompleted: true,
        ),
      ),
    );

    notifyListeners();
  }

  Future<void> _loadFromApi() async {
    try {
      await _apiRepository.authenticateDemo();
      final results = await Future.wait<dynamic>([
        _apiRepository.fetchExercises(),
        _apiRepository.fetchTemplates(),
        _apiRepository.fetchHistory(),
        _apiRepository.fetchDefaultRestSeconds(),
      ]);

      exercises = results[0] as List<Exercise>;
      templates = results[1] as List<WorkoutTemplate>;
      history
        ..clear()
        ..addAll(results[2] as List<WorkoutSession>);
      restDurationSeconds = results[3] as int;
      _apiEnabled = true;
      _lastSyncError = null;
      notifyListeners();
    } catch (e) {
      _apiEnabled = false;
      _lastSyncError = e.toString();
      notifyListeners();
    }
  }

  void changeTab(int index) {
    selectedTab = index;
    notifyListeners();
  }

  Exercise exerciseById(String id) {
    return exercises.firstWhere((e) => e.id == id);
  }

  void startWorkoutFromTemplate(String templateId) {
    final template = templates.firstWhere((t) => t.id == templateId);
    _activeTemplate = template;
    _activeExercises = _cloneExercises(template.exercises, allCompleted: false);
    _workoutStartedAt = DateTime.now();
    _startTicker();
    _lastSyncError = null;
    _activeSessionId = null;

    if (_apiEnabled) {
      unawaited(_startSessionOnApi(template));
    }

    notifyListeners();
  }

  void startEmptyWorkout() {
    _activeTemplate = WorkoutTemplate(
      id: 'quick_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Quick Workout',
      exercises: [],
    );
    _activeExercises = [];
    _workoutStartedAt = DateTime.now();
    _startTicker();
    _lastSyncError = null;
    _activeSessionId = null;

    if (_apiEnabled) {
      unawaited(_startSessionOnApi(_activeTemplate!));
    }

    notifyListeners();
  }

  void addExerciseToActiveWorkout(String exerciseId) {
    if (!hasActiveWorkout) return;
    final exists = _activeExercises.any((e) => e.exerciseId == exerciseId);
    if (exists) return;

    _activeExercises.add(
      WorkoutExercise(
        exerciseId: exerciseId,
        sets: [WorkoutSet(reps: 10, weight: 0)],
      ),
    );
    _syncActiveSession();
    notifyListeners();
  }

  void addSet(String exerciseId) {
    final exercise = _activeExercises.firstWhere(
      (e) => e.exerciseId == exerciseId,
    );
    final last = exercise.sets.isNotEmpty
        ? exercise.sets.last
        : WorkoutSet(reps: 8, weight: 0);
    exercise.sets.add(WorkoutSet(reps: last.reps, weight: last.weight));
    _syncActiveSession();
    notifyListeners();
  }

  void updateSet({
    required String exerciseId,
    required int setIndex,
    required int reps,
    required double weight,
    required SetType type,
  }) {
    final exercise = _activeExercises.firstWhere(
      (e) => e.exerciseId == exerciseId,
    );
    final target = exercise.sets[setIndex];
    target
      ..reps = reps
      ..weight = weight
      ..type = type;
    _syncActiveSession();
    notifyListeners();
  }

  void toggleSetComplete(String exerciseId, int setIndex) {
    final exercise = _activeExercises.firstWhere(
      (e) => e.exerciseId == exerciseId,
    );
    final target = exercise.sets[setIndex];
    target.completed = !target.completed;
    if (target.completed) {
      startRestTimer();
    }
    _syncActiveSession();
    notifyListeners();
  }

  void startRestTimer([int? seconds]) {
    _restUntil = DateTime.now().add(
      Duration(seconds: seconds ?? restDurationSeconds),
    );
    _startTicker();
    notifyListeners();
  }

  void stopRestTimer() {
    _restUntil = null;
    notifyListeners();
  }

  void setRestDuration(int seconds) {
    restDurationSeconds = seconds;
    if (_apiEnabled) {
      unawaited(_syncUserPreferencesOnApi());
    }
    notifyListeners();
  }

  void finishWorkout() {
    if (!hasActiveWorkout) return;

    if (_apiEnabled && _activeSessionId != null) {
      unawaited(_finishSessionOnApi(_activeSessionId!));
      return;
    }

    history.insert(
      0,
      WorkoutSession(
        id: 'session_${DateTime.now().millisecondsSinceEpoch}',
        templateName: _activeTemplate?.name ?? 'Quick Workout',
        startedAt: _workoutStartedAt!,
        endedAt: DateTime.now(),
        exercises: _cloneExercises(_activeExercises, allCompleted: false),
      ),
    );
    cancelWorkout(notify: false);
    notifyListeners();
  }

  void cancelWorkout({bool notify = true}) {
    _activeTemplate = null;
    _activeExercises = [];
    _workoutStartedAt = null;
    _restUntil = null;
    _activeSessionId = null;
    _ticker?.cancel();
    _ticker = null;
    if (notify) notifyListeners();
  }

  Future<void> _startSessionOnApi(WorkoutTemplate template) async {
    try {
      final sessionId = await _apiRepository.startSession(
        templateId: int.tryParse(template.id),
        templateName: template.name,
        exercises: _activeExercises,
      );
      _activeSessionId = sessionId;
      _syncActiveSession();
      _lastSyncError = null;
      notifyListeners();
    } catch (e) {
      _lastSyncError = e.toString();
      notifyListeners();
    }
  }

  void _syncActiveSession() {
    if (!_apiEnabled || _activeSessionId == null || !hasActiveWorkout) return;
    unawaited(_syncActiveSessionOnApi());
  }

  Future<void> _syncActiveSessionOnApi() async {
    final sessionId = _activeSessionId;
    if (sessionId == null) return;

    try {
      await _apiRepository.updateSession(
        sessionId: sessionId,
        exercises: _activeExercises,
      );
      _lastSyncError = null;
      notifyListeners();
    } catch (e) {
      _lastSyncError = e.toString();
      notifyListeners();
    }
  }

  Future<void> _finishSessionOnApi(int sessionId) async {
    try {
      await _apiRepository.updateSession(
        sessionId: sessionId,
        exercises: _activeExercises,
      );
      final completed = await _apiRepository.finishSession(sessionId);
      history.insert(0, completed);
      _lastSyncError = null;
      cancelWorkout(notify: false);
      notifyListeners();
    } catch (e) {
      _lastSyncError = e.toString();
      history.insert(
        0,
        WorkoutSession(
          id: 'session_${DateTime.now().millisecondsSinceEpoch}',
          templateName: _activeTemplate?.name ?? 'Quick Workout',
          startedAt: _workoutStartedAt!,
          endedAt: DateTime.now(),
          exercises: _cloneExercises(_activeExercises, allCompleted: false),
        ),
      );
      cancelWorkout(notify: false);
      notifyListeners();
    }
  }

  Future<void> _syncUserPreferencesOnApi() async {
    try {
      await _apiRepository.updateDefaultRestSeconds(restDurationSeconds);
      _lastSyncError = null;
      notifyListeners();
    } catch (e) {
      _lastSyncError = e.toString();
      notifyListeners();
    }
  }

  int get workoutsCompleted => history.length;

  double get totalVolume {
    return history.fold(0, (sum, session) => sum + sessionVolume(session));
  }

  double sessionVolume(WorkoutSession session) {
    return session.exercises.fold(
      0,
      (sum, ex) =>
          sum +
          ex.sets.fold(0, (setSum, set) => setSum + (set.weight * set.reps)),
    );
  }

  Duration averageDuration() {
    if (history.isEmpty) return Duration.zero;
    final totalSecs = history
        .map((s) => s.endedAt.difference(s.startedAt).inSeconds)
        .fold<int>(0, (a, b) => a + b);
    return Duration(seconds: totalSecs ~/ history.length);
  }

  List<WorkoutExercise> _cloneExercises(
    List<WorkoutExercise> source, {
    required bool allCompleted,
  }) {
    return source
        .map(
          (e) => WorkoutExercise(
            exerciseId: e.exerciseId,
            sets: e.sets
                .map(
                  (s) => WorkoutSet(
                    reps: s.reps,
                    weight: s.weight,
                    completed: allCompleted ? true : s.completed,
                    type: s.type,
                  ),
                )
                .toList(),
          ),
        )
        .toList();
  }

  void _startTicker() {
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (_restUntil != null && restSecondsRemaining == 0) {
        _restUntil = null;
      }

      if (!hasActiveWorkout && _restUntil == null) {
        _ticker?.cancel();
        _ticker = null;
        return;
      }

      notifyListeners();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
