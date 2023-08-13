import 'dart:collection';

import 'package:meta/meta.dart';

import 'exceptions.dart';

/// Function that returns a EventService instance of type [T]
typedef ServiceFactory<T extends EventService> = T Function();

/// A Service class that handles registration of [EventService]s.
///
/// Usage:
/// - Register a service
///
/// ```dart
///   EventHandler.I.registerEventService<MyEventService>(
///     MyEventService(),
///   );
///   EventHandler.I.registerEventServiceLazy<MyOtherEventService>(
///     () => MyOtherEventService(),
///   );
/// ```
///
/// - Unregister a service
///
/// ```dart
///   EventHandler.I.unregisterEventService(MyEventService());
///   // Or
///   EventHandler.I.unregisterEventService<MyEventService>();
/// ```
///
/// - Unregister all services or reset the singleton
///
/// ```dart
///   EventHandler.I.reset()
///   // Or
///   EventHandler.newInstance();
/// ```
abstract class FlivverEventHandler<E extends Object> {
  /// Resets the global singleton.
  factory FlivverEventHandler.newInstance() {
    return _instance = _FlivverEventDelegate<E>();
  }

  static late FlivverEventHandler _instance;

  /// Short form to access the singleton instance.
  static FlivverEventHandler get I {
    try {
      return _instance;
    } catch (e) {
      throw const EventHandlerNotInitialised();
    }
  }

  /// Access the singleton instance.
  static FlivverEventHandler get instance => I;

  /// Calls the registered [EventService](s) for the given event.
  Future<void> call(E currentEvent);

  /// Test if a service of a Type [T] or instance [service] is registered.
  bool isRegistered<T extends EventService>([T? service]);

  /// Registers a [service] against type [T] by passing an
  /// instance of [T].
  ///
  /// [events] is the list of events that the [service] will be called for.
  void registerEventService<T extends EventService>(
    T service, {
    required List<E> events,
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
    required List<E> events,
    required E initializeOn,
  });

  /// Unregisters all services.
  void reset();

  /// Unregister a service by the instance of registered [service] or the
  /// implelmentation type [T] of the registered service.
  void unregisterEventService<T extends EventService>([EventService? service]);
}

/// Implement this class to register a startup service with
/// [FlivverEventHandler].
///
/// Usage:
/// ```dart
/// class DependencyInjectionService implements EventService {
///   @override
///   void call<Event extends Object>(Event currentEvent) {
///     if (currentEvent is StartupEvent) {
///       // initialising non-auth dependencies
///     } else if (currentEvent is LogInEvent || currentEvent is SignInEvent) {
///       // initialising auth dependencies
///     } else if (currentEvent is LogOutEvent) {
///       // clearing dependencies
///     }
///   }
/// }
/// ```
// ignore: one_member_abstracts
abstract class EventService {
  /// Call this [EventService] only for the currentevent.
  Future<void> call<E extends Object>(E currentEvent);
}

class _FlivverEventDelegate<E extends Object>
    implements FlivverEventHandler<E> {
  _FlivverEventDelegate();

  final _services = LinkedHashMap<_TypedEvent, _TypedServiceFactory>.from(
    <_TypedEvent, _TypedServiceFactory>{},
  );

  @override
  Future<void> call(E currentEvent) async {
    for (final serviceOrFactory in _services.values) {
      await serviceOrFactory(currentEvent);
    }
  }

  @override
  bool isRegistered<T extends EventService>([EventService? service]) {
    return _services.containsKey(_TypedEvent<T, E>(const [])) ||
        _services.containsValue(service);
  }

  @override
  void registerEventService<T extends EventService>(
    T service, {
    required List<E> events,
  }) {
    _register<T>(service: service, events: events);
  }

  @override
  void registerEventServiceLazy<T extends EventService>(
    ServiceFactory<T> serviceFactory, {
    required E initializeOn,
    required List<E> events,
  }) {
    _register<T>(
      serviceFactory: serviceFactory,
      events: events,
      initializeOn: initializeOn,
    );
  }

  @override
  void reset() => _services.clear();

  @override
  void unregisterEventService<T extends EventService>([EventService? service]) {
    if (isRegistered<T>(service)) {
      _services.remove(_TypedEvent<T, E>(const []));
    } else {
      throw EventServiceNotRegisteredException(
        'No service registered for type $T or $service',
      );
    }
  }

  void _register<T extends EventService>({
    E? initializeOn,
    ServiceFactory<T>? serviceFactory,
    T? service,
    required List<E> events,
  }) {
    if (_services.containsKey(_TypedEvent<T, E>(events))) {
      throw EventServiceAlreadyRegisteredException(
        'A service of type $T is already registered.',
      );
    }
    _services[_TypedEvent<T, E>(events)] = _TypedServiceFactory<T, E>(
      service: service,
      serviceFactory: serviceFactory,
      initializeOn: initializeOn,
    );
  }
}

/// == returns true either when other has the same type as this or when other
/// has same events as this.
@immutable
class _TypedEvent<T extends EventService, E extends Object> {
  const _TypedEvent(this.events);

  final List<E> events;

  @override
  int get hashCode => type.hashCode;

  Type get type => T;

  @override
  bool operator ==(Object other) =>
      other == T || (other is _TypedEvent<T, E> && other.events == events);

  @override
  String toString() {
    return '_TypedEvent<$T, $E>(events: ${events.runtimeType}, type: $type)';
  }
}

@immutable
class _TypedServiceFactory<T extends EventService, E extends Object> {
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
  final E? initializeOn;

  @override
  int get hashCode => initializeOn.hashCode;

  Type get registrationType => T;

  @override
  bool operator ==(Object other) =>
      other == service ||
      other == serviceFactory!() ||
      (other is _TypedServiceFactory && other.initializeOn == initializeOn);

  Future<T> call(E currentEvent) async {
    if (service == null && currentEvent == initializeOn) {
      final lazyLoadedService = serviceFactory!();
      await lazyLoadedService<E>(currentEvent);
      return lazyLoadedService;
    } else {
      await service!(currentEvent);
      return service!;
    }
  }

  @override
  String toString() {
    return '_TypedServiceFactory<$T, $E>(serviceFactory: '
        '${serviceFactory.runtimeType}, service: $service, '
        'initializeOn: $initializeOn)';
  }
}
