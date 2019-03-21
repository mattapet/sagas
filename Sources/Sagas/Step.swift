//
//  Step.swift
//  Sagas
//
//  Created by Peter Matta on 3/19/19.
//

import Foundation

public final class Step {
  enum State {
    case `init`, started, aborted, done, compensating, compensated
  }
  
  internal var state: State = .`init`
  public let key: String
  public let dependencies: [String]
  public let successors: [String]
  public let transaction: Task
  public let compensation: Task
  
  public init(
    key: String,
    dependencies: [String],
    successors: [String],
    transaction: Task,
    compensation: Task
  ) {
    self.key = key
    self.dependencies = dependencies
    self.successors = successors
    self.transaction = transaction
    self.compensation = compensation
  }
}
