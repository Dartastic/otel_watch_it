// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:watch_it/watch_it.dart' as wi;

import 'otel_watch_it_suppression.dart';

const _tracerName = 'otel_watch_it';
const _diSystem = 'get_it';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

/// Typed attribute keys for watch_it lifecycle spans.
///
/// `watch_it` events don't yet have OTel semantic conventions; these
/// `widget.*` / `di.*` keys are package-local until a proposal lands.
enum WatchItSemantics implements OTelSemantic {
  /// `widget.lifecycle` — `call_once` / `push_scope` / `dispose`.
  widgetLifecycle('widget.lifecycle'),

  /// `widget.name` — caller-supplied name; lets traces line up with
  /// the widget surface (since `BuildContext` doesn't carry one).
  widgetName('widget.name'),

  /// `di.system` — always `get_it` for watch_it spans (watch_it is
  /// a Flutter binding on top of GetIt).
  diSystem('di.system'),

  /// `di.scope.is_final` — mirrors GetIt's `isFinal` flag on
  /// `pushNewScope` (a final scope cannot be popped).
  diScopeIsFinal('di.scope.is_final');

  const WatchItSemantics(this.key);

  @override
  final String key;

  @override
  String toString() => key;
}

/// Drop-in replacement for `watch_it`'s [wi.callOnce] that wraps the
/// `init` function in a CLIENT-kind span.
///
/// Pass a [name] — the watch_it `callOnce` API only takes a closure,
/// so the trace would otherwise have nothing to identify it by. A
/// good convention is the widget's class name plus a verb, e.g.
/// `'HomePage init'` or `'CheckoutScreen prefetch'`.
///
/// ```dart
/// class HomePage extends WatchingWidget {
///   @override
///   Widget build(BuildContext context) {
///     callOnceTraced('HomePage init', (ctx) {
///       di<AnalyticsService>().screenView('home');
///     });
///     return ...;
///   }
/// }
/// ```
void callOnceTraced(
  String name,
  void Function(BuildContext context) init, {
  void Function()? dispose,
}) {
  if (watchItInstrumentationSuppressed()) {
    wi.callOnce(init, dispose: dispose);
    return;
  }
  wi.callOnce(
    (ctx) {
      final span = _tracer().startSpan(
        'watch_it callOnce $name',
        kind: SpanKind.client,
        attributes: OTel.attributesFromMap(<String, Object>{
          WatchItSemantics.widgetLifecycle.key: 'call_once',
          WatchItSemantics.widgetName.key: name,
          WatchItSemantics.diSystem.key: _diSystem,
        }),
      );
      try {
        init(ctx);
      } catch (e, st) {
        span.addAttributes(
          OTel.attributes([
            OTel.attributeString(
              ErrorAttributes.errorType.key,
              e.runtimeType.toString(),
            ),
          ]),
        );
        span.recordException(e, stackTrace: st);
        span.setStatus(SpanStatusCode.Error, e.toString());
        rethrow;
      } finally {
        span.end();
      }
    },
    dispose: dispose == null
        ? null
        : () =>
            _spanDispose(name, lifecycle: 'call_once_dispose', body: dispose),
  );
}

/// Drop-in replacement for `watch_it`'s [wi.pushScope]. The `init`
/// callback (which runs once when the scope is pushed) is wrapped in
/// a CLIENT-kind span, and the optional `dispose` callback is wrapped
/// in a sibling span when the scope is popped.
///
/// Pass a [name] for trace identification — see [callOnceTraced].
void pushScopeTraced(
  String name, {
  void Function(GetIt getIt)? init,
  void Function()? dispose,
  bool isFinal = false,
}) {
  if (watchItInstrumentationSuppressed()) {
    wi.pushScope(init: init, dispose: dispose, isFinal: isFinal);
    return;
  }
  wi.pushScope(
    init: init == null
        ? null
        : (getIt) {
            final span = _tracer().startSpan(
              'watch_it pushScope $name',
              kind: SpanKind.client,
              attributes: OTel.attributesFromMap(<String, Object>{
                WatchItSemantics.widgetLifecycle.key: 'push_scope',
                WatchItSemantics.widgetName.key: name,
                WatchItSemantics.diSystem.key: _diSystem,
                WatchItSemantics.diScopeIsFinal.key: isFinal,
              }),
            );
            try {
              init(getIt);
            } catch (e, st) {
              span.addAttributes(
                OTel.attributes([
                  OTel.attributeString(
                    ErrorAttributes.errorType.key,
                    e.runtimeType.toString(),
                  ),
                ]),
              );
              span.recordException(e, stackTrace: st);
              span.setStatus(SpanStatusCode.Error, e.toString());
              rethrow;
            } finally {
              span.end();
            }
          },
    dispose: dispose == null
        ? null
        : () =>
            _spanDispose(name, lifecycle: 'push_scope_dispose', body: dispose),
    isFinal: isFinal,
  );
}

/// Drop-in replacement for `watch_it`'s [wi.onDispose] that wraps the
/// disposer in a CLIENT-kind span.
void onDisposeTraced(String name, void Function() dispose) {
  if (watchItInstrumentationSuppressed()) {
    wi.onDispose(dispose);
    return;
  }
  wi.onDispose(() {
    _spanDispose(name, lifecycle: 'dispose', body: dispose);
  });
}

void _spanDispose(
  String name, {
  required String lifecycle,
  required void Function() body,
}) {
  final span = _tracer().startSpan(
    'watch_it $lifecycle $name',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(<String, Object>{
      WatchItSemantics.widgetLifecycle.key: lifecycle,
      WatchItSemantics.widgetName.key: name,
      WatchItSemantics.diSystem.key: _diSystem,
    }),
  );
  try {
    body();
  } catch (e, st) {
    span.addAttributes(
      OTel.attributes([
        OTel.attributeString(
          ErrorAttributes.errorType.key,
          e.runtimeType.toString(),
        ),
      ]),
    );
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
