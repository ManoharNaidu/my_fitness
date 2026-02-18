import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/fitness_models.dart';

class ApiUser {
  ApiUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.units,
    required this.defaultRestSeconds,
  });

  final int id;
  final String email;
  final String displayName;
  final String units;
  final int defaultRestSeconds;
}

class AuthResult {
  AuthResult({required this.accessToken, required this.user});

  final String accessToken;
  final ApiUser user;
}

class ApiFitnessRepository {
  ApiFitnessRepository({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;
  String? _accessToken;

  bool get isAuthenticated => _accessToken != null && _accessToken!.isNotEmpty;

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final res = await _client.post(
      Uri.parse('${AppConfig.apiBaseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    _ensureOk(res);
    final data = _decodeMap(res.body);
    final accessToken = data['access_token'] as String?;
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('Login succeeded but no access token was returned.');
    }

    _accessToken = accessToken;
    final user = _parseApiUser(data['user'] as Map<String, dynamic>?);
    return AuthResult(accessToken: accessToken, user: user);
  }

  Future<AuthResult> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final res = await _client.post(
      Uri.parse('${AppConfig.apiBaseUrl}/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'display_name': displayName,
      }),
    );

    _ensureOk(res);
    final data = _decodeMap(res.body);
    final accessToken = data['access_token'] as String?;
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception(
        'Registration succeeded but no access token was returned.',
      );
    }

    _accessToken = accessToken;
    final user = _parseApiUser(data['user'] as Map<String, dynamic>?);
    return AuthResult(accessToken: accessToken, user: user);
  }

  Future<AuthResult> authenticateDemo() {
    return login(email: AppConfig.demoEmail, password: AppConfig.demoPassword);
  }

  Future<ApiUser> fetchCurrentUser() async {
    final res = await _client.get(
      Uri.parse('${AppConfig.apiBaseUrl}/users/me'),
      headers: _authHeaders,
    );
    _ensureOk(res);
    return _parseApiUser(_decodeMap(res.body));
  }

  void logout() {
    _accessToken = null;
  }

  Future<int> fetchDefaultRestSeconds() async {
    final res = await _client.get(
      Uri.parse('${AppConfig.apiBaseUrl}/users/me'),
      headers: _authHeaders,
    );
    _ensureOk(res);
    final data = _decodeMap(res.body);
    return (data['default_rest_seconds'] as num?)?.toInt() ?? 90;
  }

  Future<void> updateDefaultRestSeconds(int seconds) async {
    final res = await _client.patch(
      Uri.parse('${AppConfig.apiBaseUrl}/users/me/preferences'),
      headers: _authHeaders,
      body: jsonEncode({'default_rest_seconds': seconds}),
    );
    _ensureOk(res);
  }

  Future<List<Exercise>> fetchExercises() async {
    final res = await _client.get(
      Uri.parse('${AppConfig.apiBaseUrl}/exercises'),
      headers: _authHeaders,
    );
    _ensureOk(res);

    final raw = jsonDecode(res.body) as List<dynamic>;
    return raw.map((item) {
      final map = item as Map<String, dynamic>;
      return Exercise(
        id: '${map['id']}',
        name: map['name'] as String? ?? 'Exercise',
        primaryMuscle: map['primary_muscle'] as String? ?? '',
        equipment: map['equipment'] as String? ?? '',
      );
    }).toList();
  }

  Future<List<WorkoutTemplate>> fetchTemplates() async {
    final res = await _client.get(
      Uri.parse('${AppConfig.apiBaseUrl}/templates'),
      headers: _authHeaders,
    );
    _ensureOk(res);

    final raw = jsonDecode(res.body) as List<dynamic>;
    return raw.map((item) {
      final templateMap = item as Map<String, dynamic>;
      final exercisesRaw = templateMap['exercises'] as List<dynamic>? ?? [];

      final exercises = exercisesRaw.map((exerciseItem) {
        final exerciseMap = exerciseItem as Map<String, dynamic>;
        final setsRaw = exerciseMap['sets'] as List<dynamic>? ?? [];

        final sets = setsRaw.map((setItem) {
          final setMap = setItem as Map<String, dynamic>;
          return WorkoutSet(
            reps: (setMap['target_reps'] as num?)?.toInt() ?? 0,
            weight: (setMap['target_weight'] as num?)?.toDouble() ?? 0,
            completed: false,
            type: _parseSetType(setMap['set_type'] as String?),
          );
        }).toList();

        return WorkoutExercise(
          exerciseId: '${exerciseMap['exercise_id']}',
          sets: sets,
        );
      }).toList();

      return WorkoutTemplate(
        id: '${templateMap['id']}',
        name: templateMap['name'] as String? ?? 'Template',
        exercises: exercises,
      );
    }).toList();
  }

  Future<List<WorkoutSession>> fetchHistory() async {
    final res = await _client.get(
      Uri.parse('${AppConfig.apiBaseUrl}/sessions'),
      headers: _authHeaders,
    );
    _ensureOk(res);

    final raw = jsonDecode(res.body) as List<dynamic>;
    return raw
        .map((item) => item as Map<String, dynamic>)
        .where((s) => (s['status'] as String? ?? '') == 'completed')
        .map(_parseSession)
        .toList();
  }

  Future<int> startSession({
    int? templateId,
    required String templateName,
    required List<WorkoutExercise> exercises,
  }) async {
    final res = await _client.post(
      Uri.parse('${AppConfig.apiBaseUrl}/sessions/start'),
      headers: _authHeaders,
      body: jsonEncode({
        'template_id': templateId,
        'template_name_snapshot': templateName,
        'exercises': _serializeExercises(exercises),
      }),
    );
    _ensureOk(res);
    final data = _decodeMap(res.body);
    return (data['id'] as num).toInt();
  }

  Future<void> updateSession({
    required int sessionId,
    required List<WorkoutExercise> exercises,
  }) async {
    final res = await _client.patch(
      Uri.parse('${AppConfig.apiBaseUrl}/sessions/$sessionId'),
      headers: _authHeaders,
      body: jsonEncode({'exercises': _serializeExercises(exercises)}),
    );
    _ensureOk(res);
  }

  Future<WorkoutSession> finishSession(int sessionId) async {
    final res = await _client.post(
      Uri.parse('${AppConfig.apiBaseUrl}/sessions/$sessionId/finish'),
      headers: _authHeaders,
    );
    _ensureOk(res);
    return _parseSession(_decodeMap(res.body));
  }

  List<Map<String, dynamic>> _serializeExercises(
    List<WorkoutExercise> exercises,
  ) {
    return exercises.asMap().entries.map((entry) {
      final sortOrder = entry.key;
      final exercise = entry.value;
      final exerciseId = int.tryParse(exercise.exerciseId);

      return {
        'exercise_id': exerciseId ?? 0,
        'sort_order': sortOrder,
        'sets': exercise.sets.asMap().entries.map((setEntry) {
          final setOrder = setEntry.key + 1;
          final set = setEntry.value;
          return {
            'set_order': setOrder,
            'reps': set.reps,
            'weight': set.weight,
            'completed': set.completed,
            'set_type': set.type.name,
          };
        }).toList(),
      };
    }).toList();
  }

  WorkoutSession _parseSession(Map<String, dynamic> sessionMap) {
    final exerciseRaw = sessionMap['exercises'] as List<dynamic>? ?? [];
    final exercises = exerciseRaw.map((exerciseItem) {
      final exerciseMap = exerciseItem as Map<String, dynamic>;
      final setsRaw = exerciseMap['sets'] as List<dynamic>? ?? [];

      final sets = setsRaw.map((setItem) {
        final setMap = setItem as Map<String, dynamic>;
        return WorkoutSet(
          reps: (setMap['reps'] as num?)?.toInt() ?? 0,
          weight: (setMap['weight'] as num?)?.toDouble() ?? 0,
          completed: (setMap['completed'] as bool?) ?? false,
          type: _parseSetType(setMap['set_type'] as String?),
        );
      }).toList();

      return WorkoutExercise(
        exerciseId: '${exerciseMap['exercise_id']}',
        sets: sets,
      );
    }).toList();

    final startedAtRaw = sessionMap['started_at'] as String?;
    final endedAtRaw = sessionMap['ended_at'] as String?;

    final startedAt = startedAtRaw != null
        ? DateTime.parse(startedAtRaw).toLocal()
        : DateTime.now();
    final endedAt = endedAtRaw != null
        ? DateTime.parse(endedAtRaw).toLocal()
        : startedAt.add(
            Duration(
              seconds: (sessionMap['duration_seconds'] as num?)?.toInt() ?? 0,
            ),
          );

    return WorkoutSession(
      id: '${sessionMap['id']}',
      templateName:
          sessionMap['template_name_snapshot'] as String? ?? 'Workout',
      startedAt: startedAt,
      endedAt: endedAt,
      exercises: exercises,
    );
  }

  Map<String, String> get _authHeaders {
    if (_accessToken == null || _accessToken!.isEmpty) {
      throw Exception('Not authenticated. Call authenticateDemo() first.');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_accessToken',
    };
  }

  Map<String, dynamic> _decodeMap(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('Unexpected API response shape.');
  }

  void _ensureOk(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw Exception(
      'API request failed (${response.statusCode}): ${response.body}',
    );
  }

  SetType _parseSetType(String? raw) {
    return SetType.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => SetType.normal,
    );
  }

  ApiUser _parseApiUser(Map<String, dynamic>? userMap) {
    if (userMap == null) {
      throw Exception('API did not return user details.');
    }

    return ApiUser(
      id: (userMap['id'] as num?)?.toInt() ?? 0,
      email: userMap['email'] as String? ?? '',
      displayName: userMap['display_name'] as String? ?? 'User',
      units: userMap['units'] as String? ?? 'kg',
      defaultRestSeconds:
          (userMap['default_rest_seconds'] as num?)?.toInt() ?? 90,
    );
  }
}
