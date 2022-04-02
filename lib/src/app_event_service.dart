import 'dart:collection';

import 'package:meta/meta.dart';

import 'exceptions.dart';

/// Function that returns a EventService instance of type [T]
typedef ServiceFactory<T> = T Function();

/// A Service class that handles registration of [EventService]s.
///
/// Usage:
/// ```dart
///   AppEventService.I.registerEventService<MyEventService>(
///     MyEventService(),
///   );
///   AppEventService.I.registerEventService<MyOtherEventService>(
///     MyOtherEventService(),
///   );
///   AppEventService.I.unregisterEventService(MyEventService());
///   AppEventService.I.unregisterEventService<MyEventService>();
/// ```
abstract class AppEventService<Event extends Enum> {
  /// Resets the global singleton.
  factory AppEventService.newInstance() =>
      _instance = _AppEventDelegate<Event>();

  static late AppEventService _instance;

  /// Short form to access the singleton instance.
  static AppEventService get I {
    try {
      return _instance;
    } catch (e) {
      throw const AppEventServiceNotInitialised();
    }
  }

  /// Access the singleton instance.
  static AppEventService get instance => I;

  /// Calls the registered [EventService]\(s) for the given event.
  void call(Event currentEvent);

  /// Test if a service of a Type [T] or instance [service] is registered.
  bool isRegistered<T extends EventService>([EventService? service]);

  /// Registers a [service] against type [T] by passing an
  /// instance of [T].
  ///
  /// [events] is the list of events that the [service] will be called for.
  void registerEventService<T extends EventService>(
    T service, {
    required List<Event> events,
  });

  /// Registers a [serviceFactory] against type [T] that will be initialized on
  /// the first event in [events].
  ///
  /// [events] is the list of Events that the [serviceFactory] will be called
  /// for.
  /// [initializeOn] is the event on which the [serviceFactory] will be called
  /// to get the instance of [T service].
  ///
  /// Throws [EventServiceAlreadyRegisteredException] when a service of type [T]
  /// is already registered.
  void registerEventServiceLazy<T extends EventService>(
    ServiceFactory<T> serviceFactory, {
    required List<Event> events,
    required Event initializeOn,
  });

  /// Unregisters all services.
  void reset();

  /// Unregister a service by the instance of registered [service] or the
  /// implelmentation type [T] of the registered service.
  void unregisterEventService<T extends EventService>([EventService? service]);
}

/// Implement this class to register a startup service with [AppEventService].
// ignore: one_member_abstracts
abstract class EventService {
  /// Calls this [EventService]s for the given event.
  void call<Event extends Enum>(Event currentEvent);
}

class _AppEventDelegate<Event extends Enum> implements AppEventService<Event> {
  _AppEventDelegate();

  final LinkedHashMap<_TypedEvent, _TypedServiceFactory> _services =
      LinkedHashMap.from(<_TypedEvent, _TypedServiceFactory>{});

  @override
  void call(Event currentEvent) {
    for (final serviceOrFactory in _services.values) {
      serviceOrFactory(currentEvent);
    }
  }

  @override
  bool isRegistered<T extends EventService>([EventService? service]) {
    return _services.containsKey(_TypedEvent<T, Event>(const [])) ||
        _services.containsValue(service);
  }

  @override
  void registerEventService<T extends EventService>(
    T service, {
    required List<Event> events,
  }) {
    _register<T>(
      service: service,
      events: events,
    );
  }

  @override
  void registerEventServiceLazy<T extends EventService>(
    ServiceFactory<T> serviceFactory, {
    required Event initializeOn,
    required List<Event> events,
  }) {
    _register<T>(
      serviceFactory: serviceFactory,
      events: events,
      initializeOn: initializeOn,
    );
  }

  @override
  void reset() {
    _services.clear();
  }

  @override
  void unregisterEventService<T extends EventService>([EventService? service]) {
    if (_services.containsKey(_TypedEvent<T, Event>(const [])) ||
        _services.containsValue(service)) {
      _services.remove(_TypedEvent<T, Event>(const []));
    } else {
      throw EventServiceNotRegisteredException(
        'No service registered for type $T or $service',
      );
    }
  }

  void _register<T extends EventService>({
    T? service,
    ServiceFactory<T>? serviceFactory,
    required List<Event> events,
    Event? initializeOn,
  }) {
    if (_services.containsKey(_TypedEvent<T, Event>(events))) {
      throw EventServiceAlreadyRegisteredException(
        'A service of type $T is already registered.',
      );
    }
    _services[_TypedEvent<T, Event>(events)] = _TypedServiceFactory<T, Event>(
      service: service,
      serviceFactory: serviceFactory,
      initializeOn: initializeOn,
    );
  }
}

@immutable
class _TypedEvent<T extends EventService, Event extends Enum> {
  const _TypedEvent(this.events);

  final List<Event> events;

  @override
  int get hashCode => type.hashCode;

  Type get type => T;

  @override
  bool operator ==(Object other) =>
      other == T || (other is _TypedEvent<T, Event> && other.events == events);

  @override
  String toString() {
    return '_TypedEvent<$T, $Event>(events: '
        '${events.runtimeType}, type: $type)';
  }
}

@immutable
class _TypedServiceFactory<T extends EventService, Event extends Enum> {
  const _TypedServiceFactory({
    this.serviceFactory,
    this.service,
    this.initializeOn,
  }) : assert(
          service != null || (serviceFactory != null && initializeOn != null),
          'service or serviceFactory must be provided',
        );

  final ServiceFactory<T>? serviceFactory;
  final T? service;
  final Event? initializeOn;

  @override
  int get hashCode => initializeOn.hashCode;

  Type get registrationType => T;

  @override
  bool operator ==(Object other) =>
      other == service ||
      other == serviceFactory!() ||
      (other is _TypedServiceFactory && other.initializeOn == initializeOn);

  T call(Event currentEvent) {
    if (service == null && currentEvent == initializeOn) {
      final lazyLoadedService = serviceFactory!();
      lazyLoadedService<Event>(currentEvent);
      return lazyLoadedService;
    } else {
      service!(currentEvent);
      return service!;
    }
  }

  @override
  String toString() {
    return '_TypedServiceFactory<$T, $Event>(serviceFactory: '
        '${serviceFactory.runtimeType}, service: $service, '
        'initializeOn: $initializeOn)';
  }
}
