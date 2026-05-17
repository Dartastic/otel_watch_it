# otel_watch_it example

```dart
// example/lib/main.dart

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:flutter/material.dart';
import 'package:otel_watch_it/otel_watch_it.dart';
import 'package:watch_it/watch_it.dart';

class AnalyticsService {
  void screenView(String name) {
    // pretend this hits a vendor SDK
  }
}

Future<void> main() async {
  // 1. Bring up OTel before runApp so trace context is already
  //    flowing when the first widget builds.
  await OTel.initialize(
    serviceName: 'watch-it-demo',
  );

  // 2. Register your services with GetIt as usual.
  di.registerSingleton<AnalyticsService>(AnalyticsService());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: HomePage());
  }
}

class HomePage extends WatchingWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // ✨ Span: `watch_it callOnce HomePage init`
    //
    //    Fires exactly once when this widget is first built; great
    //    for one-shot screen-view analytics, prefetches, etc.
    callOnceTraced('HomePage init', (ctx) {
      di<AnalyticsService>().screenView('home');
    });

    // ✨ Span: `watch_it dispose HomePage release`
    //
    //    Fires when the widget unmounts.
    onDisposeTraced('HomePage release', () {
      // tear down listeners, cancel subscriptions, etc.
    });

    return const Scaffold(body: Center(child: Text('Home')));
  }
}

class CheckoutScreen extends WatchingWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ✨ Span: `watch_it pushScope Checkout scope`
    //
    //    Pushes a new GetIt scope so anything registered inside the
    //    init callback is local to this screen. The dispose span
    //    fires when the widget unmounts and the scope is popped.
    pushScopeTraced(
      'Checkout scope',
      init: (getIt) {
        getIt.registerSingleton<String>('checkout-session-id');
      },
      dispose: () {
        // optional teardown
      },
    );

    return const Scaffold(body: Center(child: Text('Checkout')));
  }
}
```

## Trace shape

```
GET /screen home
  watch_it callOnce HomePage init
    AnalyticsService.screenView (your code)

(later, on dispose)
  watch_it dispose HomePage release

(when CheckoutScreen mounts)
  watch_it pushScope Checkout scope
    AnalyticsService.startCheckout (your code)

(when CheckoutScreen unmounts)
  watch_it push_scope_dispose Checkout scope
```
