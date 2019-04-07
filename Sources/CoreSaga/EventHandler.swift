//
//  EventHandler.swift
//  CoreSaga
//
//  Created by Peter Matta on 4/4/19.
//

import Foundation

public enum EventHandlerError: Error {
  case invalidStepKey
}

public final class EventHandler {
  public init() { }

  public func apply(_ event: Event, to saga: Saga) throws  -> Saga {
    switch event.type {
    case .sagaStarted:
      return saga.started()
    case .sagaAborted:
      return saga.aborted()
    case .sagaCompleted:
      return saga.completed()
    
    case .transactionStarted,
         .transactionAborted,
         .transactionCompleted,
         .compensationStarted,
         .compensationCompleted:
      guard let step = event.stepKey
        .flatMap({ saga.steps[$0] })
        .map({ apply(event, to: $0) })
      else { throw EventHandlerError.invalidStepKey }
      return saga.stepUpdated(step)
    }
  }
  
  internal func apply(_ event: Event, to step: Step) -> Step {
    precondition(event.isStepEvent, "Invalid event application")
    switch event.type {
    case .transactionStarted:
      return step.started(payload: event.payload)
    case .transactionAborted:
      return step.aborted(payload: event.payload)
    case .transactionCompleted:
      return step.completed(payload: event.payload)
    case .compensationStarted:
      return step.compensating(payload: event.payload)
    case .compensationCompleted:
      return step.compensated(payload: event.payload)
      
    default:
      fatalError("Unreachable")
    }
  }
}

