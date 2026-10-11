import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receipts/app/app.dart';
import 'package:receipts/core/storage.dart';
import 'package:receipts/features/challenges/challenge_generator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

Future<void> _boot(
  WidgetTester tester, {
  required bool onboarded,
  FakeLlm? llm,
}) async {
  SharedPreferences.setMockInitialValues({'onboarded': onboarded});
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = const Size(900, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        llmProvider.overrideWithValue(llm),
      ],
      child: ReceiptsApp(
        theme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _addTask(WidgetTester tester, String title) async {
  await tester.tap(find.byTooltip('New task'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField).first, title);
  await tester.tap(find.text('Add task'));
  await tester.pumpAndSettle();
}

Future<void> _openTaskAndSubmitText(WidgetTester tester, String title) async {
  await tester.tap(find.text(title));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Show me the receipts'));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byType(TextField).first,
    'I finished the report with revenue and churn tables and emailed the PDF to finance.',
  );
  await tester.pump();
  await tester.tap(find.widgetWithText(FilledButton, 'Show me the receipts'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('first run shows onboarding, then the task list', (tester) async {
    await _boot(tester, onboarded: false);
    expect(find.text('No receipts, no done.'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Weak proof gets roasted.'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start without a key'));
    await tester.pumpAndSettle();
    expect(
      find.text('Nothing to prove. Suspiciously peaceful.'),
      findsOneWidget,
    );
  });

  testWidgets('empty state, then a task can be created', (tester) async {
    await _boot(tester, onboarded: true);
    expect(
      find.text('Nothing to prove. Suspiciously peaceful.'),
      findsOneWidget,
    );
    await _addTask(tester, 'Write report');
    expect(find.text('Write report'), findsOneWidget);
    expect(find.text('Nothing to prove. Suspiciously peaceful.'), findsNothing);
  });

  testWidgets('task title is validated', (tester) async {
    await _boot(tester, onboarded: true);
    await _addTask(tester, 'a');
    expect(find.text('Give it a real name.'), findsOneWidget);
  });

  testWidgets('passing proof completes the task', (tester) async {
    await _boot(tester, onboarded: true, llm: FakeLlm.judge('pass', 0.95));
    await _addTask(tester, 'Write report');
    await _openTaskAndSubmitText(tester, 'Write report');
    expect(find.text('Fine. That counts.'), findsOneWidget);
    await tester.tap(find.text('Back to tasks'));
    await tester.pumpAndSettle();
    expect(find.textContaining('1-day streak'), findsOneWidget);
  });

  testWidgets('failing proof locks the task until the pledge is typed', (
    tester,
  ) async {
    await _boot(tester, onboarded: true, llm: FakeLlm.judge('fail', 0.9));
    await _addTask(tester, 'Write report');
    await _openTaskAndSubmitText(tester, 'Write report');
    expect(find.text('Nope.'), findsOneWidget);
    expect(find.text('Dispute'), findsOneWidget);

    await tester.tap(find.text('Face your challenge'));
    await tester.pumpAndSettle();
    expect(find.text('Type the pledge'), findsOneWidget);
    expect(find.text('Not an exact match yet'), findsOneWidget);

    await tester.enterText(find.byType(TextField), pledgeText);
    await tester.pump();
    await tester.tap(find.text('Pledge accepted. Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Show me the receipts'), findsOneWidget);
    expect(find.text('Face your challenge'), findsNothing);
  });

  testWidgets('dispute can turn a weak verdict into a pass', (tester) async {
    var calls = 0;
    final llm = FakeLlm((_, _, _) {
      calls++;
      return {
        'verdict': calls == 1 ? 'weak' : 'pass',
        'confidence': 0.95,
        'reasoning': 'r',
        'missing': <String>[],
        'red_flags': <String>[],
      };
    });
    await _boot(tester, onboarded: true, llm: llm);
    await _addTask(tester, 'Write report');
    await _openTaskAndSubmitText(tester, 'Write report');
    expect(find.text('Technically evidence. Technically.'), findsOneWidget);

    await tester.tap(find.text('Dispute'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      'The PDF was attached and the finance team replied.',
    );
    await tester.tap(find.text('Appeal'));
    await tester.pumpAndSettle();
    expect(find.text('Fine. That counts.'), findsOneWidget);
    expect(find.text('Dispute'), findsNothing);
  });

  testWidgets('short proof cannot be submitted', (tester) async {
    await _boot(tester, onboarded: true);
    await _addTask(tester, 'Write report');
    await tester.tap(find.text('Write report'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show me the receipts'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'done');
    await tester.pump();
    final btn = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Show me the receipts'),
    );
    expect(btn.onPressed, isNull);
  });
}
