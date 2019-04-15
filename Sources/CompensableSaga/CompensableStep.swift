//
//  CompensableStep.swift
//  CompensableSaga
//
//  Created by Peter Matta on 4/15/19.
//

import CoreSaga
import Foundation

public struct CompensableStep: AnyStep {
  public enum State {
    case fresh
    case started(Data?)
    case aborted(Data?)
    case completed(Data?)
    case compensated(Data?)
  }
  public typealias JobType = Job
  
  public let state: State
  public let sagaId: String
  public let key: String
  public let dependencies: [String]
  public let successors: [String]
  public let transaction: JobType
  public let compensation: JobType
  
  public init(
    sagaId: String,
    key: String,
    dependencies: [String],
    successors: [String],
    transaction: JobType,
    compensation: JobType
  ) {
    self.state = .fresh
    self.sagaId = sagaId
    self.key = key
    self.dependencies = dependencies
    self.successors = successors
    self.transaction = transaction
    self.compensation = compensation
  }
}

extension CompensableStep {
  public var isFresh: Bool {
    if case .fresh = state { return true }
    else { return false }
  }
  
  public var isStarted: Bool {
    if case .started = state { return true }
    else { return false }
  }
  
  public var isAborted: Bool {
    if case .aborted = state { return true }
    else { return false }
  }
  
  public var isCompleted: Bool {
    if case .completed = state { return true }
    else { return false }
  }
  
  public var isCompensated: Bool {
    if case .compensated = state { return true }
    else { return false }
  }
  
  public var data: Data? {
    switch state {
    case .fresh: return nil
    case .started(let data),
         .aborted(let data),
         .completed(let data),
         .compensated(let data):
      return data
    }
  }
}

extension CompensableStep {
  fileprivate init(
    state: State,
    sagaId: String,
    key: String,
    dependencies: [String],
    successors: [String],
    transaction: Job,
    compensation: Job
  ) {
    self.state = state
    self.sagaId = sagaId
    self.key = key
    self.dependencies = dependencies
    self.successors = successors
    self.transaction = transaction
    self.compensation = compensation
  }
  
  public func started(payload: Data? = nil) -> CompensableStep {
    return CompensableStep(
      state: .started(payload),
      sagaId: sagaId,
      key: key,
      dependencies: dependencies,
      successors: successors,
      transaction: transaction,
      compensation: compensation
    )
  }
  
  public func aborted(payload: Data? = nil) -> CompensableStep {
    return CompensableStep(
      state: .aborted(payload),
      sagaId: sagaId,
      key: key,
      dependencies: dependencies,
      successors: successors,
      transaction: transaction,
      compensation: compensation
    )
  }
  
  public func completed(payload: Data? = nil) -> CompensableStep {
    return CompensableStep(
      state: .completed(payload),
      sagaId: sagaId,
      key: key,
      dependencies: dependencies,
      successors: successors,
      transaction: transaction,
      compensation: compensation
    )
  }
  
  public func compensated(payload: Data? = nil) -> CompensableStep {
    return CompensableStep(
      state: .compensated(payload),
      sagaId: sagaId,
      key: key,
      dependencies: dependencies,
      successors: successors,
      transaction: transaction,
      compensation: compensation
    )
  }
}
