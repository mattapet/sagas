//
//  RetryableStep.swift
//  RetryableSaga
//
//  Created by Peter Matta on 4/15/19.
//

import CoreSaga
import Foundation

public struct RetryableStep: AnyStep {
  public enum State {
    case fresh
    case started(Data?)
    case completed(Data?)
  }
  
  public let state: State
  public let sagaId: String
  public let key: String
  public let dependencies: [String]
  public let successors: [String]
  public let transaction: Job
  
  public init(
    sagaId: String,
    key: String,
    dependencies: [String],
    successors: [String],
    transaction: Job
  ) {
    self.state = .fresh
    self.sagaId = sagaId
    self.key = key
    self.dependencies = dependencies
    self.successors = successors
    self.transaction = transaction
  }
}

extension RetryableStep {
  public var isFresh: Bool {
    if case .fresh = state { return true }
    else { return false }
  }
  
  public var isStarted: Bool {
    if case .started = state { return true }
    else { return false }
  }
  
  public var isCompleted: Bool {
    if case .completed = state { return true }
    else { return false }
  }
  
  public var data: Data? {
    switch state {
    case .fresh: return nil
    case .started(let data),
         .completed(let data):
      return data
    }
  }
}

extension RetryableStep {
  fileprivate init(
    state: State,
    sagaId: String,
    key: String,
    dependencies: [String],
    successors: [String],
    transaction: Job
  ) {
    self.state = state
    self.sagaId = sagaId
    self.key = key
    self.dependencies = dependencies
    self.successors = successors
    self.transaction = transaction
  }
  
  public func started(payload: Data? = nil) -> RetryableStep {
    return RetryableStep(
      state: .started(payload),
      sagaId: sagaId,
      key: key,
      dependencies: dependencies,
      successors: successors,
      transaction: transaction
    )
  }
  
  public func completed(payload: Data? = nil) -> RetryableStep {
    return RetryableStep(
      state: .completed(payload),
      sagaId: sagaId,
      key: key,
      dependencies: dependencies,
      successors: successors,
      transaction: transaction
    )
  }
}

