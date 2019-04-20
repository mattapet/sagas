//
//  EventHandler+CompensableSaga.swift
//  CompensableSaga
//
//  Created by Peter Matta on 4/14/19.
//

import CoreSaga

extension EventHandler where SagaType: CompensableSaga {
  public func apply(_ event: Event, to saga: SagaType) throws -> SagaType {
    switch event.type {
    case .sagaStarted:
      return saga.started(payload: event.payload)
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
      return saga.updating(step: step)
    }
  }
  
  internal func apply(
    _ event: Event,
    to step: CompensableStep
  ) -> CompensableStep {
    switch event.type {
    case .transactionStarted:
      return step.started(payload: event.payload)
    case .transactionAborted:
      return step.aborted(payload: event.payload)
    case .transactionCompleted:
      return step.completed(payload: event.payload)
    case .compensationStarted:
      return step//.compensating(payload: event.payload)
    case .compensationCompleted:
      return step.compensated(payload: event.payload)
      
    default:
      fatalError("Unreachable")
    }
  }
}

