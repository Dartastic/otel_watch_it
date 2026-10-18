<!-- dartastic-header:start -->
# OpenTelemetry instrumentation for `watch_it`

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![OpenTelemetry Specification](https://img.shields.io/badge/OpenTelemetry-Specification-blueviolet)](https://opentelemetry.io/docs/specs/otel/)

`otel_watch_it` is an [OpenTelemetry](https://opentelemetry.io/) instrumentation for `watch_it` that
easily adds standard observability to applications that use `watch_it`.  This package depends on 
[dartastic_opentelemetry_api](https://pub.dev/packages/dartastic_opentelemetry_api).

This package can be used with any OTel backend because it's compliant with the OpenTelemetry Specification.

This package supports Android, iOS, Linux, macOS, Web and Windows, for versions of `watch_it` that support those platforms. It is WASM-ready.

This Apache-2.0 package is professionally maintained and supported with 💙 by Michael Bushe,
Dart and Flutter Maintainer at OpenTelemetry and the creator of [dartastic_opentelemetry](https://pub.dev/packages/dartastic_opentelemetry)
and [dartastic_opentelemetry_api](https://pub.dev/packages/dartastic_opentelemetry_api). This package is professionally supported by
[Dartastic.io](https://dartastic.io).

---
## Dartastic.io: AI Code Healing and Real User Monitoring for Flutter

**See what your users experience. Find problems with Flutter apps in production. Fix them with AI.**

[Dartastic.io](https://dartastic.io) brings AI code healing, real user monitoring, and OpenTelemetry observability together in one platform built for Dart and Flutter. (Patents pending)

![Dartastic AI answering "Why did crashes jump after the last release?" over a Flutter App Health dashboard](https://dartastic.io/img/pub-dev/HomePageCrashesQuestion.png)

### Dartastic AI — From Production Problems to Code Fixes

Dartastic AI analyzes production telemetry alongside your application source code to diagnose problems and propose fixes.

- **Investigate production issues** using crashes, errors, traces, metrics, and real user telemetry.
- **Find the offending code** by connecting observed problems with your application's source in Dartastic Pub or your source code repos.
- **Generate code patches** that address the underlying problems.
- **Create actionable issues** in your issue tracker, complete with findings and the proposed code patch.

### Dartastic RUM — See What Your Users See

Understand how people actually experience your Flutter application.

- **Replay user sessions** in the Dartastic Observatory session player.
- **Choose your replay fidelity**, from privacy-preserving widget outlines to pixel-level reproductions of the user experience.
- **Investigate real user problems** using session replay and production observability data.

![Dartastic RUM Session Replay](https://dartastic.io/img/pub-dev/session-replay.png)

### Dartastic Observatory — Observability Built for Flutter

A complete observability backend where Flutter and Dart are first-class citizens.

- **Flutter-specific dashboards** for application performance, health, and reliability.
- **Alerts and notifications** through email, Slack, and PagerDuty.
- **Dartastic Cloud Observatory** — Start with a 30-day free trial on isolated, shared infrastructure, as low as $39/mo.
- **Dartastic Hosted Observatory** — Run the observability stack in a private managed environment, sized from Mini to Enterprise XL.
- **Dartastic Self-Hosted Observatory** — The whole platform inside your own network. Your keys, your cluster, with nothing leaving your perimeter.

### Dartastic Native OTel Runtime — Native OpenTelemetry Performance

Collect production telemetry without burdening Flutter's main isolate.

- **Native OpenTelemetry runtime** that moves telemetry processing off the main isolate.
- **Native crash reporting** for problems that Dart can't catch.
- **Widget performance diagnostics** to identify janky widgets.
- **On-device PII filtering** before sensitive data leaves your application.
- **Source-level error diagnostics** powered by the Dartastic Symbolizer API.
- **Platform-native metrics** for iOS, Android, and Linux, including iOS MetricKit and Android Vitals.
- **OpenTelemetry compatibility** — Send telemetry to Dartastic Observatory or any OpenTelemetry platform.

### Dartastic Labs — OpenTelemetry Integrations

Instrument more of your application without writing everything yourself.

- **650+ open-source integrations** for Dart and Flutter libraries and services, including Dio, Shelf, Logger, Anthropic, AWS, Azure, and Stripe. Look for otel_* on pub.dev.

### More Dartastic Tools

**[Dartastic Pub](https://dartastic.io/pub)**

A private Dart package registry for sharing packages and plugins with your team, partners, and customers.

**[Dartastic Symbolizer](https://dartastic.io/symbolizer)**

Turn production errors into lines of source code through a web API, while keeping your source code artifacts private.

### Professional Support and Training

Dartastic.io offers commercial support for the open-source `dartastic_opentelemetry` and `dartastic_opentelemetry_api` packages and the complete Dartastic product suite.

- **Professional support** with available around-the-clock coverage and response times under four hours on qualifying plans.
- **OpenTelemetry training** for teams instrumenting Dart, Flutter, mobile, and web applications.

### Open Standards. No Mandatory Backend.

The Dartastic OpenTelemetry API and SDK are open source and standards-based. You can use them independently of Dartastic's commercial services and send telemetry to any compatible OpenTelemetry backend.

Dartastic's commercial products add native performance, advanced diagnostics, session replay, AI-assisted remediation, and managed observability services.

**[Explore Dartastic.io](https://dartastic.io)**

---
<!-- dartastic-header:end -->

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
  watch_it: ^2.4.0
  otel_watch_it: ^0.3.1
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
