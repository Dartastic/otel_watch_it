// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otel_watch_it/otel_watch_it.dart';
import 'package:watch_it/watch_it.dart';

class _Probe {
  int built = 0;
  int disposed = 0;
}

/// A `WatchingWidget` that runs [onBuild] every time it builds. Lets
/// us drive `callOnceTraced` / `pushScopeTraced` / `onDisposeTraced`
/// from a real widget without needing a full app.
class _Driver extends WatchingWidget {
  const _Driver({required this.onBuild});
  final void Function(BuildContext) onBuild;

  @override
  Widget build(BuildContext context) {
    onBuild(context);
    return const SizedBox.shrink();
  }
}

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_watch_it-test',
    );
    spans = harness.spans;
  });

  setUp(() async {
    harness.clear();
    await GetIt.instance.reset();
  });

  group('callOnceTraced', () {
    testWidgets('emits a span the first time the widget builds',
        (tester) async {
      final probe = _Probe();
      await tester.pumpWidget(_Driver(onBuild: (ctx) {
        callOnceTraced('HomePage init', (_) => probe.built++);
      }));

      expect(probe.built, 1);
      final span = spans.findSpanByName('watch_it callOnce HomePage init');
      expect(span, isNotNull);
      final attrs = {
        for (final a in span!.attributes.toList()) a.key: a.value,
      };
      expect(attrs['widget.lifecycle'], 'call_once');
      expect(attrs['widget.name'], 'HomePage init');
      expect(attrs['di.system'], 'get_it');
    });

    testWidgets('rebuild does not re-emit the span', (tester) async {
      final probe = _Probe();
      Widget builder() => _Driver(onBuild: (ctx) {
            callOnceTraced('Page init', (_) => probe.built++);
          });

      await tester.pumpWidget(builder());
      await tester.pumpWidget(builder());
      await tester.pumpWidget(builder());

      expect(probe.built, 1);
      expect(
        spans.findSpansByName('watch_it callOnce Page init'),
        hasLength(1),
      );
    });

    testWidgets('init exception is recorded + rethrown', (tester) async {
      Object? caught;
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        caught = details.exception;
      };
      addTearDown(() => FlutterError.onError = originalOnError);

      await tester.pumpWidget(_Driver(onBuild: (ctx) {
        callOnceTraced('Boom init', (_) => throw StateError('boom'));
      }));

      expect(caught, isA<StateError>());
      final span = spans.findSpanByName('watch_it callOnce Boom init');
      expect(span, isNotNull);
      expect(span!.status, SpanStatusCode.Error);
      final attrs = {for (final a in span.attributes.toList()) a.key: a.value};
      expect(attrs['error.type'], 'StateError');
    });

    testWidgets('disposer is traced on widget dispose', (tester) async {
      final probe = _Probe();
      await tester.pumpWidget(_Driver(onBuild: (ctx) {
        callOnceTraced(
          'Page',
          (_) => probe.built++,
          dispose: () => probe.disposed++,
        );
      }));
      await tester.pumpWidget(const SizedBox.shrink());

      expect(probe.disposed, 1);
      expect(
        spans.findSpanByName('watch_it call_once_dispose Page'),
        isNotNull,
      );
    });
  });

  group('pushScopeTraced', () {
    testWidgets('emits a span when the widget builds', (tester) async {
      await tester.pumpWidget(_Driver(onBuild: (ctx) {
        pushScopeTraced('Settings scope', init: (getIt) {
          getIt.registerSingleton<String>('settings-bag');
        });
      }));

      final span = spans.findSpanByName('watch_it pushScope Settings scope');
      expect(span, isNotNull);
      final attrs = {for (final a in span!.attributes.toList()) a.key: a.value};
      expect(attrs['widget.lifecycle'], 'push_scope');
      expect(attrs['di.scope.is_final'], false);
    });

    testWidgets('dispose runs a sibling span on widget tear-down',
        (tester) async {
      final probe = _Probe();
      await tester.pumpWidget(_Driver(onBuild: (ctx) {
        pushScopeTraced(
          'Settings scope',
          init: (_) {},
          dispose: () => probe.disposed++,
        );
      }));
      await tester.pumpWidget(const SizedBox.shrink());

      expect(probe.disposed, 1);
      expect(
        spans.findSpanByName('watch_it push_scope_dispose Settings scope'),
        isNotNull,
      );
    });
  });

  group('onDisposeTraced', () {
    testWidgets('runs and traces the disposer when the widget unmounts',
        (tester) async {
      final probe = _Probe();
      await tester.pumpWidget(_Driver(onBuild: (ctx) {
        onDisposeTraced('release subscription', () => probe.disposed++);
      }));
      await tester.pumpWidget(const SizedBox.shrink());

      expect(probe.disposed, 1);
      expect(
        spans.findSpanByName('watch_it dispose release subscription'),
        isNotNull,
      );
    });
  });

  group('suppression', () {
    testWidgets('runWithoutWatchItInstrumentation skips spans', (tester) async {
      await tester.pumpWidget(_Driver(onBuild: (ctx) {
        runWithoutWatchItInstrumentation(() {
          callOnceTraced('Suppressed init', (_) {});
        });
      }));
      expect(spans.findSpansStartingWith('watch_it'), isEmpty);
    });
  });
}
