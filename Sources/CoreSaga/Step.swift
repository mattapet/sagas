//
//  Step.swift
//  CoreSaga
//
//  Created by Peter Matta on 4/4/19.
//

import Foundation

public struct Step {
  internal enum State {
    case fresh
    case started(Data?)
    case aborted(Data?)
    case completed(Data?)
    case compensated(Data?)
  }
  
  internal let state: State
  public let sagaId: String
  public let key: String
  public let dependencies: [String]
  public let successors: [String]
  public let transaction: Job
  public let compensation: Job
  
  public init(
    sagaId: String,
    key: String,
    dependencies: [String],
    successors: [String],
    transaction: Job,
    compensation: Job
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

extension Step {
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
  
  public var isInitial: Bool {
    return dependencies.isEmpty
  }
  
  public var isTerminal: Bool {
    return successors.isEmpty
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

extension Step {
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
  
  public func started(payload: Data? = nil) -> Step {
    return Step(
      state: .started(payload),
      sagaId: sagaId,
      key: key,
      dependencies: dependencies,
      successors: successors,
      transaction: transaction,
      compensation: compensation
    )
  }
  
  public func aborted(payload: Data? = nil) -> Step {
    return Step(
      state: .aborted(payload),
      sagaId: sagaId,
      key: key,
      dependencies: dependencies,
      successors: successors,
      transaction: transaction,
      compensation: compensation
    )
  }
  
  public func completed(payload: Data? = nil) -> Step {
    return Step(
      state: .completed(payload),
      sagaId: sagaId,
      key: key,
      dependencies: dependencies,
      successors: successors,
      transaction: transaction,
      compensation: compensation
    )
  }
  
  public func compensated(payload: Data? = nil) -> Step {
    return Step(
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
