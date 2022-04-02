/// A library to handle multi event callback.
library app_event_service;

export 'src/app_event_service.dart'
    show ServiceFactory, AppEventService, EventService;
export 'src/exceptions.dart'
    show
        EventServiceNotRegisteredException,
        EventServiceAlreadyRegisteredException;
