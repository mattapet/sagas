//
//  Repository.swift
//  CoreSaga
//
//  Created by Peter Matta on 4/4/19.
//

import Basic
import Foundation

public final class Repository<Store: EventStore> {
  private let store: EventStore
  
  internal let eventHandler: EventHandler
  internal let commandHandler: CommandHandler
  
  public init(
    store: Store,
    eventHandler: EventHandler,
    commandHandler: CommandHandler
  ) {
    self.store = store
    self.eventHandler = eventHandler
    self.commandHandler = commandHandler
  }
  
  public func query(_ saga: Saga) throws -> Saga {
    return try await(saga, store.load).reduce(saga) { saga, event in
      return try eventHandler.apply(event, to: saga)
    }
  }
  
  public func execute(_ command: Command, on saga: Saga) throws -> Saga {
    let events = try commandHandler.handle(command, on: saga)
    try await(events, saga, store.store)
    return try events.reduce(saga) {
      try eventHandler.apply($1, to: $0)
    }
  }
}
