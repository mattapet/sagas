//
//  Command.swift
//  CoreSaga
//
//  Created by Peter Matta on 4/4/19.
//

import Foundation

public struct Command {
  public enum CommandType {
    case startSaga
    case abortSaga
    case completeSaga
    
    case startTransaction
    case retryTransaction
    case abortTransaction
    case completeTransaction
    
    case startCompensation
    case retryCompensation
    case completeCompensation
  }
  
  public let type: CommandType
  public let sagaId: String
  public let stepKey: String?
  public let payload: Data?
  
  fileprivate init(
    type: CommandType,
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

extension Command {
  public var isSagaCommand: Bool {
    switch type {
    case .startSaga, .abortSaga, .completeSaga: return true
    default: return false
    }
  }
  
  public var isStepCommand: Bool {
    return !isSagaCommand
  }
}

extension Command {
  public static func startSaga(
    sagaId: String,
    payload: Data? = nil
  ) -> Command {
    return Command(
      type: .startSaga,
      sagaId: sagaId,
      payload: payload
    )
  }
  
  public static func abortSaga(
    sagaId: String
  ) -> Command {
    return Command(
      type: .abortSaga,
      sagaId: sagaId
    )
  }
  
  public static func completeSaga(
    sagaId: String
  ) -> Command {
    return Command(
      type: .completeSaga,
      sagaId: sagaId
    )
  }
  
  public static func startTransaction(
    sagaId: String,
    stepKey: String,
    payload: Data? = nil
  ) -> Command {
    return Command(
      type: .startTransaction,
      sagaId: sagaId,
      stepKey: stepKey,
      payload: payload
    )
  }
  
  public static func retryTransaction(
    sagaId: String,
    stepKey: String
  ) -> Command {
    return Command(
      type: .retryTransaction,
      sagaId: sagaId,
      stepKey: stepKey
    )
  }
  
  public static func abortTransaction(
    sagaId: String,
    stepKey: String,
    payload: Data? = nil
  ) -> Command {
    return Command(
      type: .abortTransaction,
      sagaId: sagaId,
      stepKey: stepKey,
      payload: payload
    )
  }
  
  public static func completeTransaction(
    sagaId: String,
    stepKey: String,
    payload: Data? = nil
  ) -> Command {
    return Command(
      type: .completeTransaction,
      sagaId: sagaId,
      stepKey: stepKey,
      payload: payload
    )
  }
  
  public static func startCompensation(
    sagaId: String,
    stepKey: String,
    payload: Data? = nil
  ) -> Command {
    return Command(
      type: .startCompensation,
      sagaId: sagaId,
      stepKey: stepKey,
      payload: payload
    )
  }
  
  public static func retryCompensation(
    sagaId: String,
    stepKey: String
  ) -> Command {
    return Command(
      type: .retryCompensation,
      sagaId: sagaId,
      stepKey: stepKey
    )
  }
  
  public static func completeCompensation(
    sagaId: String,
    stepKey: String,
    payload: Data? = nil
  ) -> Command {
    return Command(
      type: .completeCompensation,
      sagaId: sagaId,
      stepKey: stepKey,
      payload: payload
    )
  }
}
