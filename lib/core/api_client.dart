import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'models.dart';

/// REST API client for ProofTask backend.
class ApiClient {
  ApiClient({
    required this.baseUrl,
    this.token,
  });

  final String baseUrl;
  final String? token;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  // ---------------------------------------------------------------- tasks

  Future<List<Task>> getTasks() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/tasks'),
      headers: _headers,
    );
    if (res.statusCode != 200) {
      throw ApiException('Failed to fetch tasks', res.statusCode);
    }
    final list = jsonDecode(res.body) as List;
    return list.map((j) => Task.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<Task> createTask({
    required String title,
    required String definition,
    DateTime? deadline,
    TaskPriority priority = TaskPriority.medium,
    String acceptanceCriteria = '',
    List<String> requiredEvidenceTypes = const [],
    String expectedOutcome = '',
    String verificationPolicy = 'any',
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/tasks'),
      headers: _headers,
      body: jsonEncode({
        'title': title,
        'definition': definition,
        if (deadline != null) 'deadline': deadline.toIso8601String(),
        'priority': priority.name,
        'acceptanceCriteria': acceptanceCriteria,
        'requiredEvidenceTypes': requiredEvidenceTypes,
        'expectedOutcome': expectedOutcome,
        'verificationPolicy': verificationPolicy,
      }),
    );
    if (res.statusCode != 201) {
      throw ApiException('Failed to create task', res.statusCode);
    }
    return Task.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<Task> getTask(String id) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/tasks/$id'),
      headers: _headers,
    );
    if (res.statusCode != 200) {
      throw ApiException('Task not found', res.statusCode);
    }
    return Task.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<Task> updateTask(String id, Map<String, dynamic> updates) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/api/tasks/$id'),
      headers: _headers,
      body: jsonEncode(updates),
    );
    if (res.statusCode != 200) {
      throw ApiException('Failed to update task', res.statusCode);
    }
    return Task.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> deleteTask(String id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/api/tasks/$id'),
      headers: _headers,
    );
    if (res.statusCode != 200) {
      throw ApiException('Failed to delete task', res.statusCode);
    }
  }

  Future<Task> clearChallenge(String id) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/tasks/$id/challenge/clear'),
      headers: _headers,
    );
    if (res.statusCode != 200) {
      throw ApiException('Failed to clear challenge', res.statusCode);
    }
    return Task.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> createSubtasks(
    String parentId,
    List<String> titles,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/tasks/$parentId/subtasks'),
      headers: _headers,
      body: jsonEncode({'titles': titles}),
    );
    if (res.statusCode != 201) {
      throw ApiException('Failed to create subtasks', res.statusCode);
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ---------------------------------------------------------- verification

  Future<VerifyResult> submitEvidence({
    required String taskId,
    required EvidenceType evidenceType,
    required String evidenceValue,
    Uint8List? evidenceBytes,
    String? evidenceMime,
    int strictness = 1,
    int roastLevel = 1,
    bool notToday = false,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/verify/$taskId/submit'),
      headers: _headers,
      body: jsonEncode({
        'evidenceType': evidenceType.name,
        'evidenceValue': evidenceValue,
        if (evidenceBytes != null)
          'evidenceBase64': base64Encode(evidenceBytes),
        if (evidenceMime != null) 'evidenceMime': evidenceMime,
        'strictness': strictness,
        'roastLevel': roastLevel,
        'notToday': notToday,
      }),
    );
    if (res.statusCode == 409) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      throw ApiException(body['error'] as String, res.statusCode);
    }
    if (res.statusCode != 200) {
      throw ApiException('Verification failed', res.statusCode);
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return VerifyResult(
      outcome: _parseOutcome(json['outcome'] as Map<String, dynamic>),
      task: Task.fromJson(json['task'] as Map<String, dynamic>),
    );
  }

  Future<VerifyResult> disputeVerdict({
    required String taskId,
    required String originalText,
    required String note,
    int strictness = 1,
    int roastLevel = 1,
    bool notToday = false,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/verify/$taskId/dispute'),
      headers: _headers,
      body: jsonEncode({
        'originalText': originalText,
        'note': note,
        'strictness': strictness,
        'roastLevel': roastLevel,
        'notToday': notToday,
      }),
    );
    if (res.statusCode != 200) {
      throw ApiException('Dispute failed', res.statusCode);
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return VerifyResult(
      outcome: _parseOutcome(json['outcome'] as Map<String, dynamic>),
      task: Task.fromJson(json['task'] as Map<String, dynamic>),
    );
  }

  Outcome _parseOutcome(Map<String, dynamic> j) => Outcome(
    verdict: Verdict.values.byName(j['verdict'] as String),
    confidence: (j['confidence'] as num).toDouble(),
    reasoning: j['reasoning'] as String,
    message: j['message'] as String,
    hash: j['hash'] as String,
    missing: List<String>.from(j['missing'] as List? ?? []),
    flags: List<String>.from(j['flags'] as List? ?? []),
    usedLlm: (j['usedAi'] as bool?) ?? false,
  );

  // ------------------------------------------------------------- auth

  Future<AuthResult> register({
    required String email,
    required String password,
    String displayName = '',
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'displayName': displayName,
      }),
    );
    if (res.statusCode != 201) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      throw ApiException(
        body['error'] as String? ?? 'Registration failed',
        res.statusCode,
      );
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return AuthResult(
      token: json['token'] as String,
      userId: json['userId'] as String,
    );
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      throw ApiException(
        body['error'] as String? ?? 'Login failed',
        res.statusCode,
      );
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return AuthResult(
      token: json['token'] as String,
      userId: json['userId'] as String,
    );
  }
}

class VerifyResult {
  const VerifyResult({required this.outcome, required this.task});
  final Outcome outcome;
  final Task task;
}

class AuthResult {
  const AuthResult({required this.token, required this.userId});
  final String token;
  final String userId;
}

class ApiException implements Exception {
  ApiException(this.message, this.statusCode);
  final String message;
  final int statusCode;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
