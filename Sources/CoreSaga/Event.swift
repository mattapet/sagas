//
//  Event.swift
//  CoreSaga
//
//  Created by Peter Matta on 4/4/19.
//

import Foundation

public struct Event: Codable {
  public enum EventType: String, Codable {
    case sagaStarted
    case sagaAborted
    case sagaCompleted
    
    case transactionStarted
    case transactionAborted
    case transactionCompleted
    
    case compensationStarted
    case compensationCompleted
  }
  
  public let type: EventType
  public let sagaId: String
  public let stepKey: String?
  public let payload: Data?
  
  fileprivate init(
    type: EventType,
    sagaId: String,
    stepKey: String? = nil,
    payload: Data? = nil
  ) {
    self.type = type
    self.sagaId = sagaId
    self.stepKey = stepKey
    self.payload = payload
  }
}

extension Event {
  var isSagaEvent: Bool {
    switch type {
    case .sagaStarted, .sagaAborted, .sagaCompleted: return true
    default: return false
    }
  }
  
  var isStepEvent: Bool {
    return !isSagaEvent
  }
}

extension Event {
  public static func sagaStarted(
    sagaId: String,
    payload: Data? = nil
  ) -> Event {
    return Event(
      type: .sagaStarted,
      sagaId: sagaId,
      payload: payload
    )
  }
  
  public static func sagaAborted(
    sagaId: String
  ) -> Event {
    return Event(
      type: .sagaAborted,
      sagaId: sagaId
    )
  }
  
  public static func sagaCompleted(
    sagaId: String
  ) -> Event {
    return Event(
      type: .sagaCompleted,
      sagaId: sagaId
    )
  }
  
  public static func transactionStarted(
    sagaId: String,
    stepKey: String,
    payload: Data? = nil
  ) -> Event {
    return Event(
      type: .transactionStarted,
      sagaId: sagaId,
      stepKey: stepKey,
      payload: payload
    )
  }
  
  public static func transactionAborted(
    sagaId: String,
    stepKey: String,
    payload: Data? = nil
  ) -> Event {
    return Event(
      type: .transactionAborted,
      sagaId: sagaId,
      stepKey: stepKey,
      payload: payload
    )
  }
  
  public static func transactionCompleted(
    sagaId: String,
    stepKey: String,
    payload: Data? = nil
  ) -> Event {
    return Event(
      type: .transactionCompleted,
      sagaId: sagaId,
      stepKey: stepKey,
      payload: payload
    )
  }
  
  public static func compensationStarted(
    sagaId: String,
    stepKey: String,
    payload: Data? = nil
  ) -> Event {
    return Event(
      type: .compensationStarted,
      sagaId: sagaId,
      stepKey: stepKey,
      payload: payload
    )
  }
  
  public static func compensationCompleted(
    sagaId: String,
    stepKey: String,
    payload: Data? = nil
  ) -> Event {
    return Event(
      type: .compensationCompleted,
      sagaId: sagaId,
      stepKey: stepKey,
      payload: payload
    )
  }
}
