//
//  HttpSaga.swift
//  HttpSagas
//
//  Created by Peter Matta on 4/21/19.
//

import CompensableSaga
import Foundation

public struct HttpSaga: CompensableSaga {
  public let state: SagaState
  public let sagaId: String
  public let steps: [String:CompensableStep]
  public let payload: Data?
  
  public init(
    sagaId: String,
    steps: [String:StepType],
    payload: Data? = nil
  ) {
    self.state = .fresh
    self.sagaId = sagaId
    self.steps = steps
    self.payload = payload
  }
}

extension HttpSaga {
  fileprivate init(
    state: SagaState,
    sagaId: String,
    steps: [String:CompensableStep],
    payload: Data? = nil
  ) {
    self.state = state
    self.sagaId = sagaId
    self.steps = steps
    self.payload = payload
  }
  
  public func updating(step: CompensableStep) -> HttpSaga {
    return HttpSaga(
      state: state,
      sagaId: sagaId,
      steps: steps.mapValues { $0.key == step.key ? step : $0 },
      payload: payload
    )
  }
  
  public func started(payload: Data? = nil) -> HttpSaga {
    return HttpSaga(
      state: .started,
      sagaId: sagaId,
      steps: steps,
      payload: payload ?? self.payload
    )
  }
  
  public func completed() -> HttpSaga {
    return HttpSaga(
      state: .completed,
      sagaId: sagaId,
      steps: steps,
      payload: payload
    )
  }
  
  public func aborted() -> HttpSaga {
    return HttpSaga(
      state: .aborted,
      sagaId: sagaId,
      steps: steps,
      payload: payload
    )
  }
}
