//
//  StepEvent.swift
//  CoreSaga
//
//  Created by Peter Matta on 4/2/19.
//

import Foundation

public struct StepEvent: Codable {
  public enum EventType: String, Codable {
    case started, finished, aborted, compensated
  }
  
  public let type: EventType
  public let stepKey: String
  public let sagaId: String
  
  fileprivate init(
    type: EventType,
    stepKey: String,
    sagaId: String
  ) {
    self.type = type
    self.stepKey = stepKey
    self.sagaId = sagaId
  }
}

extension StepEvent {
  public static func started(
    stepKey: String,
    sagaId: String
  ) -> StepEvent {
    return StepEvent(
      type: .started,
      stepKey: stepKey,
      sagaId: sagaId
    )
  }
  
  public static func finished(
    stepKey: String,
    sagaId: String
    ) -> StepEvent {
    return StepEvent(
      type: .finished,
      stepKey: stepKey,
      sagaId: sagaId
    )
  }
  
  public static func aborted(
    stepKey: String,
    sagaId: String
    ) -> StepEvent {
    return StepEvent(
      type: .aborted,
      stepKey: stepKey,
      sagaId: sagaId
    )
  }
  
  public static func compensated(
    stepKey: String,
    sagaId: String
    ) -> StepEvent {
    return StepEvent(
      type: .compensated,
      stepKey: stepKey,
      sagaId: sagaId
    )
  }
}
