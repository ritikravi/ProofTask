import 'package:receipts/core/llm.dart';

typedef StructuredHandler = Map<String, dynamic> Function(
  String system,
  String user,
  List<ImagePart> images,
);

/// Programmable LLM for tests.
class FakeLlm implements LlmProvider {
  FakeLlm(this.onStructured, {this.completion = 'Roasted.'});
  final StructuredHandler onStructured;
  final String completion;
  final calls = <String>[];

  /// Always returns the same judge verdict.
  factory FakeLlm.judge(String verdict, double confidence) => FakeLlm(
    (_, _, _) => {
      'verdict': verdict,
      'confidence': confidence,
      'reasoning': 'because',
      'missing': <String>[],
      'red_flags': <String>[],
    },
  );

  @override
  Future<String> complete({
    required String system,
    required String user,
    double temperature = 0.9,
  }) async {
    calls.add('complete');
    return completion;
  }

  @override
  Future<Map<String, dynamic>> structured({
    required String system,
    required String user,
    required Map<String, dynamic> schema,
    List<ImagePart> images = const [],
    double temperature = 0.2,
  }) async {
    calls.add('structured');
    return onStructured(system, user, images);
  }
}
