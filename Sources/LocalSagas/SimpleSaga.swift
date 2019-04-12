//
//  SimpleSaga.swift
//  LocalSagas
//
//  Created by Peter Matta on 4/11/19.
//

import CoreSaga
import Foundation

public struct SimpleSaga {
  public let state: SagaState
  public let sagaId: String
  public let steps: [String:Step]
  public let payload: Data?
  
  public init(
    sagaId: String,
    steps: [String:Step],
    payload: Data? = nil
  ) {
    self.state = .fresh
    self.sagaId = sagaId
    self.steps = steps
    self.payload = payload
  }
}

extension SimpleSaga: CompensableSaga {
  fileprivate init(
    state: SagaState,
    sagaId: String,
    steps: [String:Step],
    payload: Data? = nil
  ) {
    self.state = state
    self.sagaId = sagaId
    self.steps = steps
    self.payload = payload
  }
  
  public func updating(step: Step) -> SimpleSaga {
    return SimpleSaga(
      state: state,
      sagaId: sagaId,
      steps: steps.mapValues { $0.key == step.key ? step : $0 },
      payload: payload
    )
  }
  
  public func started(payload: Data? = nil) -> SimpleSaga {
    return SimpleSaga(
      state: .started,
      sagaId: sagaId,
      steps: steps,
      payload: payload ?? self.payload
    )
  }
  
  public func completed() -> SimpleSaga {
    return SimpleSaga(
      state: .completed,
      sagaId: sagaId,
      steps: steps,
      payload: payload
    )
  }

  public func aborted() -> SimpleSaga {
    return SimpleSaga(
      state: .aborted,
      sagaId: sagaId,
      steps: steps,
      payload: payload
    )
  }
}
