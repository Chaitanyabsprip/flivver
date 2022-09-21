# Flivver

[![style: very good analysis](https://img.shields.io/badge/style-very_good_analysis-B22C89.svg)](https://pub.dev/packages/very_good_analysis)

A clean solution to handling callbacks for custom events as a dart library.
Are you tired of maintaining initialisation and dispose api of multiple packages in single method?
This package helps you modularise event callbacks, allowing for clean, readable and composable code.

Flivver API promotes:

- testability
- composability
- ability to create custom events
- type safety

## Example

See `example/example.dart` for a complete example.

- Register a service

```dart
  EventHandler.I.registerEventService<MyEventService>(
    MyEventService(),
  );
  EventHandler.I.registerEventServiceLazy<MyOtherEventService>(
    () => MyOtherEventService(),
  );
```

- Unregister a service

```dart
  EventHandler.I.unregisterEventService(MyEventService());
  // Or
  EventHandler.I.unregisterEventService<MyEventService>();
```

- Unregister all services or reset the singleton

```dart
  EventHandler.I.reset()
  // Or
  EventHandler.newInstance();
```

- Create Event Service

```dart
class DependencyInjectionService implements EventService {
  @override
  void call<Event extends Object>(Event currentEvent) {
    if (currentEvent is StartupEvent) {
      // initialising non-auth dependencies
    } else if (currentEvent is LogInEvent || currentEvent is SignInEvent) {
      // initialising auth dependencies
    } else if (currentEvent is LogOutEvent) {
      // clearing dependencies
    }
  }
}
```

## Events

Flivver only cares about the type, `Events` can be classes or enums.
Events can be anything, every service is associated with a list of events for
which it will be called.

## Event Service

Event services are classes that implement the `EventService`.
These services are registered with the `EventHandler` against selected events.
It has one `call` method that will be called for events that the service was
registered against.
