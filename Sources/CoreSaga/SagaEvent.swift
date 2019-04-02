//
//  SagaEvent.swift
//  CoreSaga
//
//  Created by Peter Matta on 4/2/19.
//

import Foundation

public struct SagaEvent: Codable {
  public enum EventType: String, Codable {
    case started, finished, aborted, compensated
  }
  
  public let type: EventType
  public let sagaId: String
  
  fileprivate init(
    type: EventType,
    sagaId: String
  ) {
    self.type = type
    self.sagaId = sagaId
  }
}

extension SagaEvent {
  public static func started(
    sagaId: String
  ) -> SagaEvent {
    return SagaEvent(
      type: .started,
      sagaId: sagaId
    )
  }
  
  public static func finished(
    sagaId: String
  ) -> SagaEvent {
    return SagaEvent(
      type: .finished,
      sagaId: sagaId
    )
  }

  public static func aborted(
    sagaId: String
  ) -> SagaEvent {
    return SagaEvent(
      type: .aborted,
      sagaId: sagaId
    )
  }
  
  public static func compensated(
    sagaId: String
  ) -> SagaEvent {
    return SagaEvent(
      type: .compensated,
      sagaId: sagaId
    )
  }
}
