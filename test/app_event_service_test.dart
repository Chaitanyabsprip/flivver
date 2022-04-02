import 'package:app_event_service/app_event_service.dart';
import 'package:app_event_service/src/exceptions.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'mock.dart';
import 'test_objects.dart';

void main() {
  late AppEventService<AppLifeCycleEvents> appEventService;

  setUpAll(() {
    registerFallbackValue(MockEventService());
    registerFallbackValue(AppLifeCycleEvents.onStartup);
  });

  test(
      'should throw AppEventServiceNotInitialised when calling I before '
      'initialising once', () {
    expect(
      () => AppEventService.I,
      throwsA(isA<AppEventServiceNotInitialised>()),
    );
  });

  group('After initialisation, AppEventService', () {
    setUp(() {
      appEventService = AppEventService<AppLifeCycleEvents>.newInstance();
    });

    test(
        'should create an instance of AppEventService when static method I is '
        'called', () {
      expect(AppEventService.I, isA<AppEventService>());
    });

    test(
        'should return an instance of AppEventService when static method '
        'instance is called', () {
      expect(AppEventService.instance, isA<AppEventService>());
    });

    test(
        'should return a new instance of AppEventService when factory method '
        'asNewInstance is called', () {
      final instance1 = AppEventService.newInstance();
      final instance2 = AppEventService.newInstance();
      expect(instance1, isNot(equals(instance2)));
    });

    test(
        'should return same instance of AppEventService when I and instance '
        'static methods are called', () {
      final instance1 = AppEventService.I;
      final instance2 = AppEventService.instance;
      expect(instance1, equals(instance2));
    });

    test('should register startup service when registerEventService is called',
        () {
      appEventService.registerEventService<MockEventService>(
        MockEventService(),
        events: [],
      );
      expect(appEventService.isRegistered<MockEventService>(), true);
    });

    test(
        'should unregister startup service when unregisterEventService is '
        'called', () {
      appEventService
        ..registerEventService(
          MockEventService(),
          events: [],
        )
        ..unregisterEventService<MockEventService>();
      expect(appEventService.isRegistered<MockEventService>(), false);
    });

    test(
        'should throw EventServiceAlreadyRegisteredException when '
        'registerEventService is called with same service twice', () {
      appEventService.registerEventService(MockEventService(), events: []);
      expect(
        () => appEventService.registerEventService(
          MockEventService(),
          events: [],
        ),
        throwsA(isA<EventServiceAlreadyRegisteredException>()),
      );
    });

    test(
        'should throw EventServiceNotRegisteredException when '
        'unRegisterEventService is called with a new service', () {
      expect(
        () => appEventService.unregisterEventService(MockEventService()),
        throwsA(isA<EventServiceNotRegisteredException>()),
      );
    });

    test(
        'should return true when isRegistered is called with registered '
        'service', () {
      appEventService.registerEventService(MockEventService(), events: []);
      expect(appEventService.isRegistered<MockEventService>(), true);
    });

    test(
        'should return false when isRegistered is called with unregistered '
        'service', () {
      expect(appEventService.isRegistered<MockEventService>(), false);
    });

    test('should unregister all services when reset is called', () {
      appEventService
        ..registerEventService(MockEventService(), events: [])
        ..registerEventService(MockEventService1(), events: [])
        ..registerEventService(MockEventService2(), events: [])
        ..registerEventService(MockEventService3(), events: []);
      expect(appEventService.isRegistered<MockEventService>(), true);
      expect(appEventService.isRegistered<MockEventService1>(), true);
      expect(appEventService.isRegistered<MockEventService2>(), true);
      expect(appEventService.isRegistered<MockEventService3>(), true);
      appEventService.reset();
      expect(appEventService.isRegistered<MockEventService>(), false);
      expect(appEventService.isRegistered<MockEventService1>(), false);
      expect(appEventService.isRegistered<MockEventService2>(), false);
      expect(appEventService.isRegistered<MockEventService3>(), false);
    });

    test(
        'should call call() on all registered services when '
        'callOnEventServices is called', () {
      final service1 = MockEventService1();
      final service2 = MockEventService2();
      final service3 = MockEventService3();

      when(() => service1.call<AppLifeCycleEvents>(any())).thenAnswer(
        (_) => Future<void>.value(),
      );
      when(() => service2.call<AppLifeCycleEvents>(any())).thenAnswer(
        (_) => Future<void>.value(),
      );
      when(() => service3.call<AppLifeCycleEvents>(any())).thenAnswer(
        (_) => Future<void>.value(),
      );

      appEventService
        ..registerEventService(service1, events: [])
        ..registerEventService(service2, events: [])
        ..call(AppLifeCycleEvents.onStartup);

      verify(() => service1.call<AppLifeCycleEvents>(any())).called(1);
      verify(() => service2.call<AppLifeCycleEvents>(any())).called(1);
      verifyNever(() => service3.call<AppLifeCycleEvents>(any()));
    });
  });
}
