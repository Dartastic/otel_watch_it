# Changelog

## [0.3.1-wip]

### Changed

- README: standard header naming the instrumented library, its supported platforms and project links; pubspec description to match.

## [0.3.0] - 2026-10-11

### Changed

- Requires `dartastic_opentelemetry_api >=1.0.0-rc.4 <1.0.0-rc.5`.
- **Breaking:** depends on `dartastic_opentelemetry_api` only, no
  longer on the SDK. The application chooses and initializes the
  OpenTelemetry SDK. Parameters and fields typed with SDK classes
  now use the API types (`APITracer`, `APISpan`, `APILogger`, ...);
  SDK instances are still accepted wherever an API type is expected.

## [0.2.0] - 2026-08-10

### Changed

- Raised dependency floors: `get_it` `^9.2.0`, `watch_it` `^2.4.0`
  (drops the discontinued transitive `functional_listener`).

## [0.1.0-beta.1] - 2026-05-16

### Added

- `callOnceTraced(name, init, {dispose})` — drop-in replacement for
  `watch_it`'s `callOnce` that wraps the one-shot init (and the
  optional disposer) in CLIENT-kind spans.
- `pushScopeTraced(name, {init, dispose, isFinal})` — drop-in
  replacement for `pushScope`; init and dispose each get their own
  CLIENT-kind span.
- `onDisposeTraced(name, dispose)` — drop-in replacement for
  `onDispose`.
- Local `WatchItSemantics` enum (implements `OTelSemantic`) for the
  `widget.lifecycle`, `widget.name`, `di.system`, and
  `di.scope.is_final` keys.
- Zone-scoped suppression via `runWithoutWatchItInstrumentation()`.
- Eight `flutter_test` widget tests using the canonical
  `_helpers/otel_test_harness.dart` (real OTel SDK pointed at an
  in-memory exporter).
