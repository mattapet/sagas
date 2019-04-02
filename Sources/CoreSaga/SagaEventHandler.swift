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

public final class SagaEventHandler: EventHandler {
  public typealias Aggregate = Saga
  public typealias Event = SagaEvent
  
  public func apply(
    _ event: SagaEvent,
    to saga: Saga,
    with completion: @escaping (Result<(), Error>) -> Void
  ) {
    switch (saga.state, event.type) {
    case (.fresh, .started):
      saga.state = .started
      completion(.success(()))
      
    case (.started, .aborted):
      saga.state = .aborted
      completion(.success(()))
      
    case (.started, .finished):
      saga.state = .finished
      completion(.success(()))
      
    case (.finished, .compensated),
         (.started, .compensated):
      saga.state = .compensated
      completion(.success(()))
      
    case (.fresh, .aborted),
         (.fresh, .finished),
         (.fresh, .compensated),
         (.started, .started),
         (.aborted, _),
         (.finished, _),
         (.compensated, _):
      completion(.failure(SagaEventHandlerError.invalidTransiction))
    }
  }
}
