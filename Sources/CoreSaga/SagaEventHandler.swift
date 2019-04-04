//
//  SagaEventHandler.swift
//  CoreSaga
//
//  Created by Peter Matta on 4/2/19.
//

import Foundation

public enum SagaEventHandlerError: Error {
  case invalidTransiction
}

public final class SagaEventHandler<SagaStore: EventStore>: EventHandler {
  public typealias Aggregate = Saga
  public typealias Event = SagaEvent
  
  internal let store: SagaStore
  
  public init(store: SagaStore) {
    self.store = store
  }
  
  public func apply(
    _ event: SagaEvent,
    to saga: Saga,
    with completion: @escaping (Result<Saga, Error>) -> Void
  ) {
    completion(Result {
      switch (saga.state, event.type) {
      case (.fresh, .started):
        saga.state = .started
        return saga
        
      case (.started, .aborted):
        saga.state = .aborted
        return saga
        
      case (.started, .finished):
        saga.state = .finished
        return saga
        
      case (.finished, .compensated),
           (.started, .compensated):
        saga.state = .compensated
        return saga
        
      case (.fresh, .aborted),
           (.fresh, .finished),
           (.fresh, .compensated),
           (.started, .started),
           (.aborted, _),
           (.finished, _),
           (.compensated, _):
        throw SagaEventHandlerError.invalidTransiction
      }
    })
  }
}
