import 'package:equatable/equatable.dart';

/// This exception is thrown when you try to unregister a service that is not
/// yet registered.
class EventServiceNotRegisteredException extends Equatable
    implements Exception {
  /// This exception is thrown when you try to unregister a service that is not
  /// yet registered.
  const EventServiceNotRegisteredException(this.message);

  /// The reason for the exception.
  final String message;

  @override
  List<Object?> get props => [message];

  @override
  bool? get stringify => true;
}

/// This exception is thrown when you try to register a service that is
/// already registered.
class EventServiceAlreadyRegisteredException extends Equatable
    implements Exception {
  /// This exception is thrown when you try to register a service that is
  /// already registered.
  const EventServiceAlreadyRegisteredException(this.message);

  /// The reason for the exception.
  final String message;

  @override
  List<Object?> get props => [message];

  @override
  bool? get stringify => true;
}

/// This exception is thrown when you try to access an instance without first
/// once initialising AppEventService.
class EventHandlerNotInitialised extends Equatable implements Exception {
  /// This exception is thrown when you try to access an instance without first
  /// once initialising AppEventService.
  const EventHandlerNotInitialised();

  @override
  List<Object?> get props => [];
}
