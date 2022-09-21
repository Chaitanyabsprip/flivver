/// A library to handle multi event callback.
library flivver;

export 'src/exceptions.dart'
    show
        EventServiceNotRegisteredException,
        EventServiceAlreadyRegisteredException,
        EventHandlerNotInitialised;
export 'src/flivver.dart'
    show ServiceFactory, FlivverEventHandler, EventService;
