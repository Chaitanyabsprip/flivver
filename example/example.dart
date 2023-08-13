import 'package:flivver/flivver.dart';

/// Example os configuration and usage of FlivverEventHandler
///
/// This example creates a few events. It then also calls the handler with
/// the events. Which will call the registered functions.
void main() {
  initEventHandler();
  FlivverEventHandler.I.call(StartupEvent);
  FlivverEventHandler.I.call(DependenciesInitialisedEvent);
  FlivverEventHandler.I.call(SignInEvent);
  // Or
  // EventHandler.I.call(LogInEvent);
  FlivverEventHandler.I.call(LogOutEvent);
}

void initEventHandler() {
  FlivverEventHandler<CustomEvent>.newInstance();
  FlivverEventHandler.I.registerEventServiceLazy<DependencyInjectionService>(
    DependencyInjectionService.new,
    events: [StartupEvent, LogOutEvent, LogInEvent, SignInEvent],
    initializeOn: StartupEvent,
  );
  FlivverEventHandler.I.registerEventService<FirebaseService>(
    FirebaseService(),
    events: [StartupEvent],
  );
  FlivverEventHandler.I.registerEventService<FeatureService>(
    FeatureService(),
    events: [DependenciesInitialisedEvent],
  );
}

abstract class CustomEvent {}

class SignInEvent extends CustomEvent {}

abstract class LogInEvent extends CustomEvent {}

abstract class LogOutEvent extends CustomEvent {}

abstract class StartupEvent extends CustomEvent {}

abstract class DependenciesInitialisedEvent extends CustomEvent {}

class DependencyInjectionService implements EventService {
  @override
  Future<void> call<Event extends Object>(Event currentEvent) async {
    if (currentEvent is StartupEvent) {
      // initialising non-auth dependencies
    } else if (currentEvent is LogInEvent || currentEvent is SignInEvent) {
      // initialising auth dependencies
    } else if (currentEvent is LogOutEvent) {
      // clearing dependencies
    }
  }
}

class FirebaseService implements EventService {
  @override
  Future<void> call<Event extends Object>(Event currentEvent) async {
    if (currentEvent is StartupEvent) {
      // initialising firebase
    }
  }
}

class FeatureService implements EventService {
  @override
  Future<void> call<Event extends Object>(Event currentEvent) async {
    if (currentEvent is DependenciesInitialisedEvent) {
      // doing something
    }
  }
}
