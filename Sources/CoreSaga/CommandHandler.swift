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
  public func handle(_ command: Command, on saga: Saga) throws -> [Event] {
    switch (saga.state, command.type) {
    case (.fresh, .startSaga):
      return [.sagaStarted(sagaId: saga.sagaId)]
    case (.started, .abortSaga):
      return [.sagaAborted(sagaId: saga.sagaId)]
    case (.started, .completeSaga),
         (.aborted, .completeSaga):
      return [.sagaCompleted(sagaId: saga.sagaId)]
      
    case (.started, .startTransaction),
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

    case (.completed, _),
         (.aborted, .startSaga),
         (.aborted, .abortSaga),
         (.aborted, .startTransaction),
         (.aborted, .retryTransaction),
         (.aborted, .completeTransaction),
         (.started, .startSaga),
         (.started, .startCompensation),
         (.started, .retryCompensation),
         (.started, .completeCompensation),
         (.fresh, .abortSaga),
         (.fresh, .completeSaga),
         (.fresh, .startTransaction),
         (.fresh, .retryTransaction),
         (.fresh, .completeTransaction),
         (.fresh, .startCompensation),
         (.fresh, .retryCompensation),
         (.fresh, .completeCompensation),
         (_, .abortTransaction):
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

    case (.aborted, .startCompensation):
      return [
        .compensationStarted(
          sagaId: command.sagaId,
          stepKey: step.key,
          payload: command.payload
        )
      ]

    case (.aborted, .retryCompensation):
      return []
      
    case (.aborted, .completeCompensation):
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
