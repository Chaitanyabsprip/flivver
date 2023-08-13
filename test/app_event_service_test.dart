import 'package:flivver/flivver.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'mock.dart';
import 'test_objects.dart';

void main() {
  late FlivverEventHandler<FakeEvents> appEventService;

  setUpAll(() {
    registerFallbackValue(FakeEventService());
    registerFallbackValue(FakeEvents.onStartup);
  });

  test(
    'should throw AppEventHandlerNotInitialised when intantiating before '
    'initialising once',
    () {
      expect(
        () => FlivverEventHandler.I,
        throwsA(isA<EventHandlerNotInitialised>()),
      );
    },
  );

  group('After initialisation, AppEventHandler', () {
    setUp(() {
      appEventService = FlivverEventHandler<FakeEvents>.newInstance();
    });

    test(
        'should return a new instance of AppEventHandler when factory method '
        'asNewInstance is called', () {
      final instance1 = FlivverEventHandler.newInstance();
      final instance2 = FlivverEventHandler.newInstance();
      expect(instance1, isNot(equals(instance2)));
    });

    test(
        'should return same instance of AppEventHandler when I and instance '
        'static methods are called', () {
      final instance1 = FlivverEventHandler.I;
      final instance2 = FlivverEventHandler.instance;
      expect(instance1, equals(instance2));
    });

    test('should register startup service when registerEventService is called',
        () {
      appEventService.registerEventService<FakeEventService>(
        FakeEventService(),
        events: [],
      );
      expect(appEventService.isRegistered<FakeEventService>(), true);
    });

    test(
        'should unregister startup service when unregisterEventService is '
        'called', () {
      appEventService
        ..registerEventService(FakeEventService(), events: [])
        ..unregisterEventService<FakeEventService>();
      expect(appEventService.isRegistered<FakeEventService>(), false);
    });

    test(
        'should throw EventServiceAlreadyRegisteredException when '
        'registerEventService is called with same service twice', () {
      appEventService.registerEventService(FakeEventService(), events: []);
      expect(
        () => appEventService.registerEventService(
          FakeEventService(),
          events: [],
        ),
        throwsA(isA<EventServiceAlreadyRegisteredException>()),
      );
    });

    test(
        'should throw EventServiceNotRegisteredException when '
        'unRegisterEventService is called with a new service', () {
      expect(
        () => appEventService.unregisterEventService(FakeEventService()),
        throwsA(isA<EventServiceNotRegisteredException>()),
      );
    });

    test(
        'should return true when isRegistered is called with registered '
        'service', () {
      appEventService.registerEventService(FakeEventService(), events: []);
      expect(appEventService.isRegistered<FakeEventService>(), true);
    });

    test(
        'should return false when isRegistered is called with unregistered '
        'service', () {
      expect(appEventService.isRegistered<FakeEventService>(), false);
    });

    test('should unregister all services when reset is called', () {
      appEventService
        ..registerEventService(FakeEventService(), events: [])
        ..registerEventService(MockEventService1(), events: [])
        ..registerEventService(MockEventService2(), events: [])
        ..registerEventService(MockEventService3(), events: []);
      expect(appEventService.isRegistered<FakeEventService>(), true);
      expect(appEventService.isRegistered<MockEventService1>(), true);
      expect(appEventService.isRegistered<MockEventService2>(), true);
      expect(appEventService.isRegistered<MockEventService3>(), true);
      appEventService.reset();
      expect(appEventService.isRegistered<FakeEventService>(), false);
      expect(appEventService.isRegistered<MockEventService1>(), false);
      expect(appEventService.isRegistered<MockEventService2>(), false);
      expect(appEventService.isRegistered<MockEventService3>(), false);
    });

    test(
        'should call call() on all registered services when '
        'callOnEventServices is called', () async {
      final service1 = MockEventService1();
      final service2 = MockEventService2();
      final service3 = MockEventService3();

      when(() => service1.call<FakeEvents>(any())).thenAnswer(
        (_) => Future<void>.value(),
      );
      when(() => service2.call<FakeEvents>(any())).thenAnswer(
        (_) => Future<void>.value(),
      );
      when(() => service3.call<FakeEvents>(any())).thenAnswer(
        (_) => Future<void>.value(),
      );

      appEventService
        ..registerEventService(service1, events: [FakeEvents.onStartup])
        ..registerEventService(service2, events: [FakeEvents.onStartup]);
      await appEventService.call(FakeEvents.onStartup);

      verify(() => service1.call<FakeEvents>(any())).called(1);
      verify(() => service2.call<FakeEvents>(any())).called(1);
      verifyNever(() => service3.call<FakeEvents>(any()));
    });
  });
}
