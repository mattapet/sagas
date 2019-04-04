//
//  Saga.swift
//  CoreSaga
//
//  Created by Peter Matta on 4/4/19.
//

import Foundation

public enum SagaError: Error {
  case invalidKeyId
}

public struct Saga {
  public enum State {
    case fresh
    case started
    case aborted
    case completed
  }
  
  internal let state: State
  
  public let sagaId: String
  public let steps: [String:Step]
  
  public init(
    sagaId: String,
    steps: [String:Step]
  ) {
    self.state = .fresh
    self.sagaId = sagaId
    self.steps = steps
  }
}

extension Saga {
  public func stepUpdated(_ step: Step) -> Saga {
    return Saga(
      state: state,
      sagaId: sagaId,
      steps: steps.mapValues { $0.key == step.key ? step : $0 }
    )
  }
  
  public func step(for stepKey: String) throws -> Step {
    guard let step = steps[stepKey] else { throw SagaError.invalidKeyId }
    return step
  }
}

extension Saga {
  fileprivate init(
    state: State,
    sagaId: String,
    steps: [String:Step]
  ) {
    self.state = state
    self.sagaId = sagaId
    self.steps = steps
  }

  public func started() -> Saga {
    return Saga(
      state: .started,
      sagaId: sagaId,
      steps: steps
    )
  }
  
  public func aborted() -> Saga {
    return Saga(
      state: .aborted,
      sagaId: sagaId,
      steps: steps
    )
  }
  
  public func completed() -> Saga {
    return Saga(
      state: .completed,
      sagaId: sagaId,
      steps: steps
    )
  }
}
