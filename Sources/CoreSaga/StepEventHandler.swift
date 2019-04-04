//
//  StepEventHandler.swift
//  CoreSaga
//
//  Created by Peter Matta on 4/2/19.
//

import Basic
import Foundation

public enum StepEventHandlerError: Error {
  case invalidTransition
}

public final class StepEventHandler<StepStore: EventStore>: EventHandler
  where StepStore.Aggregate == Step, StepStore.Event == StepEvent
{
  public typealias Aggregate = Step
  public typealias Event = StepEvent
  
  internal let store: StepStore
  
  public init(store: StepStore) {
    self.store = store
  }
  
  public func apply(
    _ event: StepEvent,
    to step: Step,
    with completion: @escaping (Result<Step, Error>) -> Void
  ) {
    completion(Result {
      switch (step.state, event.type) {
      case (.fresh, .started):
        return try await(event, step.started(), store.save)
        
      case (.started, .aborted):
        return try await(event, step.aborted(), store.save)
        
      case (.started, .finished):
        return try await(event, step.finished(), store.save)
        
      case (.started, .compensated),
           (.finished, .compensated):
        return try await(event, step.compensated(), store.save)
        
      case (.finished, .started),
           (.finished, .finished),
           (.finished, .aborted),
           (.started, .started),
           (.fresh, .finished),
           (.fresh, .aborted),
           (.fresh, .compensated),
           (.aborted, _),
           (.compensated, _):
        throw StepEventHandlerError.invalidTransition
      }
    })
  }
}

