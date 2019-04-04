//
//  Action.swift
//  CoreSaga
//
//  Created by Peter Matta on 4/2/19.
//

import Foundation

public struct Action {
  public let stepKey: String
  public let sagaId: String
  public let payload: Data?
  public let job: Job
  public let success: StepCommand
  public let failure: StepCommand?
  
  fileprivate init(
    stepKey: String,
    sagaId: String,
    payload: Data? = nil,
    job: Job,
    success: StepCommand,
    failure: StepCommand? = nil
  ) {
    self.stepKey = stepKey
    self.sagaId = sagaId
    self.payload = payload
    self.job = job
    self.success = success
    self.failure = failure
  }
}

extension Action {
  public static func transaction(
    step: Step,
    sagaId: String
  ) -> Action {
    return Action(
      stepKey: step.key,
      sagaId: sagaId,
      payload: nil,
      job: step.transaction,
      success: .finish(stepKey: step.key, sagaId: sagaId),
      failure: .abort(stepKey: step.key, sagaId: sagaId)
    )
  }

  public static func compensation(
    step: Step,
    sagaId: String
  ) -> Action {
    return Action(
      stepKey: step.key,
      sagaId: sagaId,
      payload: nil,
      job: step.compensation,
      success: .finish(stepKey: step.key, sagaId: sagaId)
    )
  }
}
