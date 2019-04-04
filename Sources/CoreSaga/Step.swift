//
//  Step.swift
//  CoreSaga
//
//  Created by Peter Matta on 4/2/19.
//

import Foundation

public struct Step {
  internal enum State {
    case fresh, started, finished, aborted, compensated
  }
  
  internal var state: State = .fresh
  public let key: String
  public let dependencies: [String]
  public let successors: [String]
  public let transaction: Job
  public let compensation: Job
  
  public init(
    key: String,
    dependencies: [String],
    successors: [String],
    transaction: Job,
    compensation: Job
  ) {
    self.key = key
    self.dependencies = dependencies
    self.successors = successors
    self.transaction = transaction
    self.compensation = compensation
  }
}

extension Step {
  fileprivate init(
    state: State,
    key: String,
    dependencies: [String],
    successors: [String],
    transaction: Job,
    compensation: Job
  ) {
    self.key = key
    self.dependencies = dependencies
    self.successors = successors
    self.transaction = transaction
    self.compensation = compensation
  }
  
  public func started() -> Step {
    return Step(
      state: .started,
      key: key,
      dependencies: dependencies,
      successors: successors,
      transaction: transaction,
      compensation: compensation
    )
  }
  
  public func finished() -> Step {
    return Step(
      state: .finished,
      key: key,
      dependencies: dependencies,
      successors: successors,
      transaction: transaction,
      compensation: compensation
    )
  }
  
  public func aborted() -> Step {
    return Step(
      state: .aborted,
      key: key,
      dependencies: dependencies,
      successors: successors,
      transaction: transaction,
      compensation: compensation
    )
  }
  
  public func compensated() -> Step {
    return Step(
      state: .compensated,
      key: key,
      dependencies: dependencies,
      successors: successors,
      transaction: transaction,
      compensation: compensation
    )
  }
}

extension Step: Identifiable {
  public static var IDKeyPath: KeyPath<Step, String> {
    return \Step.key
  }
}
