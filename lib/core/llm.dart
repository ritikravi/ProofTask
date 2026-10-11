import 'dart:convert';

import 'package:dio/dio.dart';

class LlmException implements Exception {
  LlmException(this.message);
  final String message;
  @override
  String toString() => 'LlmException: $message';
}

class ImagePart {
  const ImagePart({required this.mime, required this.base64});
  final String mime;
  final String base64;
}

abstract interface class LlmProvider {
  /// Forces a JSON object matching [schema].
  Future<Map<String, dynamic>> structured({
    required String system,
    required String user,
    required Map<String, dynamic> schema,
    List<ImagePart> images = const [],
    double temperature = 0.2,
  });

  Future<String> complete({
    required String system,
    required String user,
    double temperature = 0.9,
  });
}

/// Anthropic Messages API, called directly from the device (BYOK).
class AnthropicProvider implements LlmProvider {
  AnthropicProvider(this.apiKey, {Dio? dio, this.model = 'claude-haiku-5-5'})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://api.anthropic.com',
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 40),
              ),
            );

  final String apiKey;
  final String model;
  final Dio _dio;

  Future<Map<String, dynamic>> _post(Map<String, dynamic> body) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/v1/messages',
        data: body,
        options: Options(
          headers: {
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
            // Required for browser (web) calls; harmless on mobile.
            'anthropic-dangerous-direct-browser-access': 'true',
            'content-type': 'application/json',
          },
        ),
      );
      return res.data!;
    } on DioException catch (e) {
      final detail = e.response?.data;
      throw LlmException(
        'HTTP ${e.response?.statusCode ?? '?'}: ${detail ?? e.message}',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> structured({
    required String system,
    required String user,
    required Map<String, dynamic> schema,
    List<ImagePart> images = const [],
    double temperature = 0.2,
  }) async {
    final data = await _post({
      'model': model,
      'max_tokens': 600,
      'temperature': temperature,
      'system': system,
      'messages': [
        {
          'role': 'user',
          'content': images.isEmpty
              ? user
              : [
                  for (final i in images)
                    {
                      'type': 'image',
                      'source': {
                        'type': 'base64',
                        'media_type': i.mime,
                        'data': i.base64,
                      },
                    },
                  {'type': 'text', 'text': user},
                ],
        },
      ],
      'tools': [
        {
          'name': 'submit_verdict',
          'description': 'Submit the structured result.',
          'input_schema': schema,
        },
      ],
      'tool_choice': {'type': 'tool', 'name': 'submit_verdict'},
    });
    for (final block in (data['content'] as List)) {
      if (block is Map && block['type'] == 'tool_use') {
        return Map<String, dynamic>.from(block['input'] as Map);
      }
    }
    throw LlmException('No tool_use block in response');
  }

  @override
  Future<String> complete({
    required String system,
    required String user,
    double temperature = 0.9,
  }) async {
    final data = await _post({
      'model': model,
      'max_tokens': 200,
      'temperature': temperature,
      'system': system,
      'messages': [
        {'role': 'user', 'content': user},
      ],
    });
    final buf = StringBuffer();
    for (final block in (data['content'] as List)) {
      if (block is Map && block['type'] == 'text') buf.write(block['text']);
    }
    final out = buf.toString().trim();
    if (out.isEmpty) throw LlmException('Empty completion');
    return out;
  }
}

/// Grok (xAI) provider — OpenAI-compatible chat completions API with tool
/// calling and vision support.
///
/// Default model is [grok-2-vision-1212] which handles both text and images.
/// Set [model] to 'grok-3-mini' for a cheaper text-only option.
class GrokProvider implements LlmProvider {
  GrokProvider(
    this.apiKey, {
    Dio? dio,
    this.model = 'grok-2-vision-1212',
  }) : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://api.x.ai',
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 60),
              ),
            );

  final String apiKey;
  final String model;
  final Dio _dio;

  Future<Map<String, dynamic>> _post(Map<String, dynamic> body) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/v1/chat/completions',
        data: body,
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
      );
      return res.data!;
    } on DioException catch (e) {
      final detail = e.response?.data;
      throw LlmException(
        'HTTP ${e.response?.statusCode ?? '?'}: ${detail ?? e.message}',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> structured({
    required String system,
    required String user,
    required Map<String, dynamic> schema,
    List<ImagePart> images = const [],
    double temperature = 0.2,
  }) async {
    // Build user message content — plain string or multi-part for vision
    final dynamic userContent = images.isEmpty
        ? user
        : [
            for (final img in images)
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:${img.mime};base64,${img.base64}',
                },
              },
            {'type': 'text', 'text': user},
          ];

    final data = await _post({
      'model': model,
      'temperature': temperature,
      'max_tokens': 600,
      'messages': [
        {'role': 'system', 'content': system},
        {'role': 'user', 'content': userContent},
      ],
      'tools': [
        {
          'type': 'function',
          'function': {
            'name': 'submit_verdict',
            'description': 'Submit the structured result.',
            'parameters': schema,
          },
        },
      ],
      'tool_choice': {
        'type': 'function',
        'function': {'name': 'submit_verdict'},
      },
    });

    final choices = data['choices'] as List?;
    final msg = choices?.firstOrNull?['message'] as Map?;
    final toolCalls = msg?['tool_calls'] as List?;
    final call = toolCalls?.firstOrNull as Map?;
    final args = call?['function']?['arguments'];
    if (args == null) throw LlmException('No tool_call in Grok response');

    // Grok returns arguments as a JSON string (OpenAI spec)
    if (args is Map) return Map<String, dynamic>.from(args);
    return Map<String, dynamic>.from(
      jsonDecode(args as String) as Map,
    );
  }

  @override
  Future<String> complete({
    required String system,
    required String user,
    double temperature = 0.9,
  }) async {
    final data = await _post({
      'model': model,
      'temperature': temperature,
      'max_tokens': 200,
      'messages': [
        {'role': 'system', 'content': system},
        {'role': 'user', 'content': user},
      ],
    });
    final choices = data['choices'] as List?;
    final content =
        choices?.firstOrNull?['message']?['content'] as String? ?? '';
    final out = content.trim();
    if (out.isEmpty) throw LlmException('Empty Grok completion');
    return out;
  }
}
