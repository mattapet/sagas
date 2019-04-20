//
//  EventRepository.swift
//  CoreSaga
//
//  Created by Peter Matta on 4/15/19.
//

import Basic
import Foundation

public protocol EventRepository: Repository {
  associatedtype EventStoreType: EventStore
  associatedtype EventHandlerType: EventHandler
  associatedtype CommandHandlerType: CommandHandler
    where
      EventStoreType.SagaType == SagaType,
      CommandHandlerType.SagaType == SagaType,
      CommandHandlerType.SagaType == EventHandlerType.SagaType
  
  var store: EventStoreType { get }
  var eventHandler: EventHandlerType { get }
  var commandHandler: CommandHandlerType { get }
}

extension EventRepository {
  public func query(_ saga: SagaType) throws -> SagaType {
    return try await(saga, store.load).reduce(saga) { saga, event in
      return try eventHandler.apply(event, to: saga)
    }
  }
  
  public func execute(
    _ command: Command,
    on saga: SagaType
  ) throws -> SagaType {
    let events = try commandHandler.handle(command, on: saga)
    try await(events, saga, store.store)
    return try events.reduce(saga) {
      try eventHandler.apply($1, to: $0)
    }
  }
}

