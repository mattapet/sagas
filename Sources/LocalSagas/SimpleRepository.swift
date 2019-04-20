//
//  SimpleRepository.swift
//  LocalSagas
//
//  Created by Peter Matta on 4/15/19.
//

import CoreSaga

public final class SimpleEventHandler: EventHandler {
  public typealias SagaType = SimpleSaga
}

public final class SimpleCommmandHandler: CommandHandler {
  public typealias SagaType = SimpleSaga
}

public final class SimpleRepository: EventRepository {
  public typealias EventStoreType = SimpleEventStore
  public typealias EventHandlerType = SimpleEventHandler
  public typealias CommandHandlerType = SimpleCommmandHandler
  public typealias SagaType = SimpleSaga
  
  public var store: EventStoreType
  public let eventHandler: SimpleEventHandler
  public let commandHandler: SimpleCommmandHandler
  
  internal init(store: EventStoreType) {
    self.store = store
    self.eventHandler = SimpleEventHandler()
    self.commandHandler = SimpleCommmandHandler()
  }
}

