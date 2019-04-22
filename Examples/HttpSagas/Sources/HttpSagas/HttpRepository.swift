//
//  HttpRepository.swift
//  HttpSagas
//
//  Created by Peter Matta on 4/21/19.
//

import CoreSaga

public final class HttpEventHandler: EventHandler {
  public typealias SagaType = HttpSaga
}

public final class HttpCommandHandler: CommandHandler {
  public typealias SagaType = HttpSaga
}

public final class HttpRepository<Store: EventStore>: EventRepository
  where Store.SagaType == HttpSaga
{
  public typealias EventStoreType = Store
  public typealias EventHandlerType = HttpEventHandler
  public typealias CommandHandlerType = HttpCommandHandler
  public typealias SagaType = HttpSaga
  
  public var store: EventStoreType
  public let eventHandler: HttpEventHandler
  public let commandHandler: HttpCommandHandler
  
  public init(store: Store) {
    self.store = store
    self.eventHandler = HttpEventHandler()
    self.commandHandler = HttpCommandHandler()
  }
}
