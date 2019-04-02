//
//  Step.swift
//  CoreSaga
//
//  Created by Peter Matta on 4/2/19.
//

import Foundation

public final class Step {
  internal enum State {
    case fresh, started, finished, aborted, compensated
  }
  
  internal var state: State = .fresh
  public let key: String
  public let dependencies: [String]
  public let successors: [String]
  
  public init(
    key: String,
    dependencies: [String],
    successors: [String]
  ) {
    self.key = key
    self.dependencies = dependencies
    self.successors = successors
  }
}

extension Step: Identifiable {
  public static var IDKeyPath: KeyPath<Step, String> {
    return \Step.key
  }
}
