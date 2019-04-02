//
//  StepEventHandler.swift
//  CoreSaga
//
//  Created by Peter Matta on 4/2/19.
//

import Foundation

public enum StepEventHandlerError: Error {
  case invalidTransition
}

public final class StepEventHandler: EventHandler {
  public typealias Aggregate = Step
  public typealias Event = StepEvent
  
  public func apply(
    _ event: StepEvent,
    to step: Step,
    with completion: @escaping (Result<(), Error>) -> Void
  ) {
    switch (step.state, event.type) {
    case (.fresh, .started):
      step.state = .started
      completion(.success(()))
      
    case (.started, .aborted):
      step.state = .aborted
      completion(.success(()))
      
    case (.started, .finished):
      step.state = .finished
      completion(.success(()))
      
    case (.started, .compensated),
         (.finished, .compensated):
      step.state = .compensated
      completion(.success(()))
      
    case (.finished, .started),
         (.finished, .finished),
         (.finished, .aborted),
         (.started, .started),
         (.fresh, .finished),
         (.fresh, .aborted),
         (.fresh, .compensated),
         (.aborted, _),
         (.compensated, _):
      completion(.failure(StepEventHandlerError.invalidTransition))
    }
  }
}

