//
//  CommandHandler.swift
//  CoreSaga
//
//  Created by Peter Matta on 4/4/19.
//

import Foundation

public enum ComamndHandlerError: Error {
  case invalidStepKey
  case invalidCommandApplication
}

public final class CommandHandler {
  public init() {}
  
  public func handle(_ command: Command, on saga: Saga) throws -> [Event] {
    print("\(saga.state):\(command.type)")
    switch (saga.state, command.type) {
    case (.fresh, .startSaga):
      return [.sagaStarted(sagaId: saga.sagaId, payload: command.payload)]
      
    case (.started, .abortSaga):
      return [.sagaAborted(sagaId: saga.sagaId)]
      
    case (.started, .completeSaga),
         (.aborted, .completeSaga):
      return [.sagaCompleted(sagaId: saga.sagaId)]
      
    case (.started, .startSaga),
         (.aborted, .abortSaga),
         (.completed, .completeSaga):
      return [] // Ensure idempotency
      
    case (.started, .startTransaction),
         (.started, .abortTransaction),
         (.started, .retryTransaction),
         (.started, .completeTransaction),
         (.aborted, .startCompensation),
         (.aborted, .retryCompensation),
         (.aborted, .completeCompensation):
      guard let events = command.stepKey
        .flatMap({ saga.steps[$0] })
        .map({ handle(command, on: $0) })
      else { throw ComamndHandlerError.invalidStepKey }
      return events

    case (.completed, .startSaga),
         (.completed, .abortSaga),
         (.completed, .startTransaction),
         (.completed, .abortTransaction),
         (.completed, .retryTransaction),
         (.completed, .completeTransaction),
         (.completed, .startCompensation),
         (.completed, .retryCompensation),
         (.completed, .completeCompensation),
         (.aborted, .startSaga),
         (.aborted, .startTransaction),
         (.aborted, .abortTransaction),
         (.aborted, .retryTransaction),
         (.aborted, .completeTransaction),
         (.started, .startCompensation),
         (.started, .retryCompensation),
         (.started, .completeCompensation),
         (.fresh, .abortSaga),
         (.fresh, .completeSaga),
         (.fresh, .startTransaction),
         (.fresh, .abortTransaction),
         (.fresh, .retryTransaction),
         (.fresh, .completeTransaction),
         (.fresh, .startCompensation),
         (.fresh, .retryCompensation),
         (.fresh, .completeCompensation):
      print("\(saga.sagaId):\(saga.state):\(command)")
      throw ComamndHandlerError.invalidCommandApplication
    }
  }
  
  internal func handle(_ command: Command, on step: Step) -> [Event] {
    precondition(command.isStepCommand, "Invalid comamnd application")
    switch (step.state, command.type) {
    case (.fresh, .startTransaction):
      return [
        .transactionStarted(
          sagaId: command.sagaId,
          stepKey: step.key,
          payload: command.payload
        )
      ]
      
    case (.started, .abortTransaction):
      return [
        .transactionAborted(
          sagaId: command.sagaId,
          stepKey: step.key,
          payload: command.payload)
      ]
      
    case (.started, .retryTransaction):
      return []

    case (.started, .completeTransaction):
      return [
        .transactionCompleted(
          sagaId: command.sagaId,
          stepKey: step.key,
          payload: command.payload
        )
      ]

    case (.completed, .startCompensation),
         (.started, .startCompensation):
      return [
        .compensationStarted(
          sagaId: command.sagaId,
          stepKey: step.key,
          payload: command.payload
        )
      ]

    case (.started, .retryCompensation),
         (.completed, .retryCompensation):
      return []
      
    case (.started, .completeCompensation),
         (.completed, .completeCompensation):
      return [
        .compensationCompleted(
          sagaId: command.sagaId,
          stepKey: step.key,
          payload: command.payload
        )
      ]
      
    default:
      fatalError("Unreachable")
    }
  }
}
