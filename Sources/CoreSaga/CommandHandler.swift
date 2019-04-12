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

public protocol CommandHandler {
  associatedtype SagaType: AnySaga
  
  func handle(_ command: Command, on saga: SagaType) throws -> [Event]
}

// MARK: - Retryable saga

extension CommandHandler where SagaType: RetryableSaga {
  public func handle(_ command: Command, on saga: SagaType) throws -> [Event] {
    print("\(saga.state):\(command.type)")
    switch (saga.state, command.type) {
    case (.fresh, .startSaga):
      return [.sagaStarted(sagaId: saga.sagaId, payload: command.payload)]
      
    case (.started, .completeSaga):
      return [.sagaCompleted(sagaId: saga.sagaId)]
      
    case (.started, .startSaga),
         (.completed, .completeSaga):
      return [] // Ensure idempotency
      
    case (.started, .startTransaction),
         (.started, .retryTransaction),
         (.started, .completeTransaction):
      guard let events = command.stepKey
        .flatMap({ saga.steps[$0] })
        .map({ handle(command, on: $0) })
        else { throw ComamndHandlerError.invalidStepKey }
      return events
      
    case (.aborted, _),
         (.completed, .startSaga),
         (.completed, .startTransaction),
         (.completed, .retryTransaction),
         (.completed, .completeTransaction),
         (.fresh, .completeSaga),
         (.fresh, .startTransaction),
         (.fresh, .retryTransaction),
         (.fresh, .completeTransaction),
         (_, .abortSaga),
         (_, .abortTransaction),
         (_, .startCompensation),
         (_, .retryCompensation),
         (_, .completeCompensation):
      print("\(saga.sagaId):\(saga.state):\(command)")
      throw ComamndHandlerError.invalidCommandApplication
    }
  }
  
  internal func handle(_ command: Command, on step: Step) -> [Event] {
    precondition(command.isStepCommand, "Invalid comamnd application")
    switch (step.state, command.type) {
    // `started` Saga, `fresh` Step
    case (.fresh, .startTransaction):
      return [
        .transactionStarted(
          sagaId: command.sagaId,
          stepKey: step.key,
          payload: command.payload
        )
      ]
      // `started` Saga, `started` Step
      
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
      
    default:
      fatalError("Unreachable")
    }
  }
}

// MARK: - Compensable saga

extension CommandHandler where SagaType: CompensableSaga {
  public func handle(_ command: Command, on saga: SagaType) throws -> [Event] {
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
         
         (.aborted, .completeTransaction),
         (.aborted, .retryTransaction),
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
    // `started` Saga, `fresh` Step
    case (.fresh, .startTransaction):
      return [
        .transactionStarted(
          sagaId: command.sagaId,
          stepKey: step.key,
          payload: command.payload
        )
      ]
    // `started` & `aborted` Saga, `started` Step
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
      
    // `aborted` Saga, `completed` Step
    case (.completed, .startCompensation):
      return [
        .compensationStarted(
          sagaId: command.sagaId,
          stepKey: step.key,
          payload: command.payload
        )
      ]
      
    case (.completed, .retryCompensation):
      return []
      
    case (.completed, .completeCompensation):
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
