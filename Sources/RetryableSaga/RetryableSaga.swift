//
//  RetryableSaga.swift
//  RetryableSaga
//
//  Created by Peter Matta on 4/15/19.
//

import CoreSaga
import Foundation

public enum SagaState {
  case fresh, started, completed
}

public protocol RetryableSaga: AnySaga
  where StepType == RetryableStep
{
  var state: SagaState { get }
  var payload: Data? { get }
  
  func started(payload: Data?) -> Self
  func completed() -> Self
}

extension RetryableSaga {
  public var isCompleted: Bool {
    switch state {
    case .fresh: return false
    case .started: return steps.allSatisfy { $0.value.isCompleted  }
    case .completed: return true
    }
  }
}

extension RetryableSaga {
  /// Returns array of saga steps that can be started.
  ///
  /// Method expects saga to be in `fresh` or `started` state. The reason
  /// for such constraint is that the saga cannot start any of its steps in any
  /// other state.
  ///
  /// - returns: An array of saga fresh steps that can be started.
  public func stepsToStart() throws -> [StepType] {
    // Ensure state of the saga
    guard state == .fresh || state == .started else { return [] }
    // Set of all traversed steps
    var visited = Set<String>()
    
    // A helper function returning all fresh steps reachable from the given
    // step.
    func stepsToStart(from step: StepType) throws -> [StepType] {
      // Make sure that traverse add each step only once -- there may exists
      // multiple leading edges (step can have multiple dependencies).
      guard visited.insert(step.key).inserted else { return [] }
      // If the current step is fresh, return it.
      if step.isFresh { return [step] }
      // Iterate over the successors
      return try step.successors
        // Recurse over all of them
        .map(stepFor).flatMap(stepsToStart)
    }
    // Apply the helper function to all of the initial steps.
    return try initial.flatMap(stepsToStart)
  }
}
