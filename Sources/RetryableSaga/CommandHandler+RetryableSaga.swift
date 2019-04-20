//
//  CommandHandler+RetryableSaga.swift
//  RetryableSaga
//
//  Created by Peter Matta on 4/14/19.
//

import CoreSaga

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
      return try command.stepKey
        .flatMap({ saga.steps[$0] })
        .map({ handle(command, on: $0) }) ?? {
          throw ComamndHandlerError.invalidStepKey
        }()
      
    case (.completed, .startSaga),
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
  
  internal func handle(
    _ command: Command,
    on step: SagaType.StepType
  ) -> [Event] {
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
