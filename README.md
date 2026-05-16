# otel_watch_it

OpenTelemetry instrumentation for
[`package:watch_it`](https://pub.dev/packages/watch_it) —
Thomas Burkhart's reactive binding between Flutter widgets and
`get_it`.

`watch_it`'s value-observation calls (`watchIt`, `watchValue`,
`watchPropertyValue`, `watchStream`, `watchFuture`) are read-side and
fire every rebuild — spanning them would produce gigabytes of
low-value traces. **This package instruments the *lifecycle* calls**
instead: the one-shot `callOnce` init, the DI-scope `pushScope` init
and dispose, and the explicit `onDispose` hook. These are the moments
where widget mount/unmount can hide slow work, and they're often the
first questions you ask when a screen feels slow.

## Install

```yaml
dependencies:
  watch_it: ^1.4.0
  otel_watch_it: ^0.1.0
```

## Use

Drop-in replacements take a span name as the first argument (since
the underlying widget can't be inferred from a `BuildContext`):

```dart
import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_watch_it/otel_watch_it.dart';
import 'package:watch_it/watch_it.dart';

class HomePage extends WatchingWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    callOnceTraced('HomePage init', (ctx) {
      di<AnalyticsService>().screenView('home');
    });

    onDisposeTraced('HomePage release', () {
      // tear-down work runs inside the span
    });

    return const Scaffold(body: ...);
  }
}

class CheckoutScreen extends WatchingWidget {
  @override
  Widget build(BuildContext context) {
    pushScopeTraced(
      'Checkout scope',
      init: (getIt) {
        getIt.registerSingleton<String>('checkout-session-id');
      },
      dispose: () {
        // optional teardown
      },
    );
    return const Scaffold(body: ...);
  }
}
```

See [`example/example.md`](example/example.md) for a full runnable
sample.

## Span shape

| Function              | Span name                                  | `widget.lifecycle`     |
|-----------------------|--------------------------------------------|------------------------|
| `callOnceTraced`      | `watch_it callOnce <name>`                 | `call_once`            |
| `callOnceTraced` dispose | `watch_it call_once_dispose <name>`     | `call_once_dispose`    |
| `pushScopeTraced`     | `watch_it pushScope <name>`                | `push_scope`           |
| `pushScopeTraced` dispose | `watch_it push_scope_dispose <name>`    | `push_scope_dispose`   |
| `onDisposeTraced`     | `watch_it dispose <name>`                  | `dispose`              |

All spans carry:

| Attribute               | Source                                |
|-------------------------|---------------------------------------|
| `widget.name`           | the caller-supplied name              |
| `widget.lifecycle`      | the lifecycle phase (see table)       |
| `di.system`             | hardcoded `get_it`                    |
| `di.scope.is_final`     | only on `pushScope` (mirrors flag)    |
| `error.type`            | exception class on throw              |

These keys are package-local (no upstream OTel semconv exists yet
for widget lifecycle); they're stable across the 0.x line.

## What we don't span

`watch_it`'s observation API — `watchIt`, `watchValue`,
`watchPropertyValue`, `watchStream`, `watchFuture`, `watch` — runs
on every rebuild. Spanning those would dwarf the rest of your
traces. If you need visibility into a specific reactive expression,
wrap the *producer* of the value (e.g. the stream / future you
register in `get_it`), not the read.

## Suppression

```dart
runWithoutWatchItInstrumentation(() {
  callOnceTraced('hot-path init', (_) { ... });  // skipped
});
```

## See also

- [`otel_get_it`](https://pub.dev/packages/otel_get_it) —
  GetIt itself (registration / `allReady` / `reset`).

## License

Apache 2.0 — copyright Mindful Software LLC.
