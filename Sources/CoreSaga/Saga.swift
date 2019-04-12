//
//  Saga.swift
//  CoreSaga
//
//  Created by Peter Matta on 4/4/19.
//

import Foundation

public enum SagaError: Error {
  case invalidKeyId
}

public enum SagaState {
  case fresh
  case started
  case aborted
  case completed
}

public protocol AnySaga {
  var state: SagaState { get }
  var sagaId: String { get }
  var steps: [String:Step] { get }
  var payload: Data? { get }
  
  var initial: [Step] { get }
  var terminal: [Step] { get }
  
  func updating(step: Step) -> Self
  func stepFor(_ stepKey: String) throws -> Step
  func stepsToStart() throws -> [Step]
  
  func started(payload: Data?) -> Self
  func completed() -> Self
}

extension AnySaga {
  public var initial: [Step] {
    return steps.values.filter { $0.isInitial }
  }
  
  public var terminal: [Step] {
    return steps.values.filter { $0.isTerminal }
  }
  
  public func stepFor(_ stepKey: String) throws -> Step {
    switch steps[stepKey] {
    case .some(let step): return step
    case .none: throw SagaError.invalidKeyId
    }
  }
}

extension AnySaga {
  /// Returns array of saga steps that can be started.
  ///
  /// Method expects saga to be in `fresh` or `started` state. The reason
  /// for such constraint is that the saga cannot start any of its steps in any
  /// other state.
  ///
  /// - returns: An array of saga fresh steps that can be started.
  public func stepsToStart() throws -> [Step] {
    // Ensure state of the saga
    guard state == .fresh || state == .started else { return [] }
    // Set of all traversed steps
    var visited = Set<String>()
    
    // A helper function returning all fresh steps reachable from the given
    // step.
    func stepsToStart(from step: Step) throws -> [Step] {
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

public protocol RetryableSaga: AnySaga {}

public protocol CompensableSaga: AnySaga {
  func aborted() -> Self
  func stepsToComplete() throws -> [Step]
  func stepsToCompensate() throws -> [Step]
}

extension CompensableSaga {
  /// Returns array of saga steps that can be compensated.
  ///
  /// Method expects saga to be in `aborted`. The reason for such constraint
  /// is that the saga cannot compensate any of its steps in any other state.
  ///
  /// - returns: An array of saga completed or started steps that can be
  ///    started.
  public func stepsToComplete() throws -> [Step] {
    // Ensure state of the saga
    guard state == .aborted else { return [] }
    // Set of all traversed steps
    var visited = Set<String>()
    
    // A helper function returning all fresh steps reachable from the given
    // step.
    func stepsToComplete(from step: Step) throws -> [Step] {
      // Make sure that traverse add each step only once -- there may exists
      // multiple leading edges (step can have multiple dependencies).
      guard visited.insert(step.key).inserted else { return [] }
      // If the current step is fresh, return it.
      if step.isStarted { return [step] }
      // Iterate over the successors
      return try step.successors
        // Recurse over all of them
        .map(stepFor).flatMap(stepsToComplete)
    }
    // Apply the helper function to all of the initial steps.
    return try initial.flatMap(stepsToComplete)
  }
  
  /// Returns array of saga steps that can be compensated.
  ///
  /// Method expects saga to be in `aborted`. The reason for such constraint
  /// is that the saga cannot compensate any of its steps in any other state.
  ///
  /// - returns: An array of saga completed or started steps that can be
  ///    started.
  public func stepsToCompensate() throws -> [Step] {
    // Ensure state of the saga
    guard state == .aborted else { return [] }
    // Set of all traversed steps
    var visited = Set<String>()
    
    // A helper function returning all fresh completed or started reachable
    // from the given step.
    func stepsToCompensate(from step: Step) throws -> [Step] {
      // Make sure that traverse add each step only once -- there may exists
      // multiple leading edges (step can have multiple dependencies).
      guard visited.insert(step.key).inserted else { return [] }
      // If the current step is fresh, return it.
      if step.isCompleted { return [step] }
      // Iterate over the successors -- since the direction of all the edges is
      // reverted, we use dependencies of the steps as our successors
      return try step.dependencies
        // Recurse over all of them
        .map(stepFor).flatMap(stepsToCompensate)
    }
    // Apply the helper function to all of the terminal steps.
    return try terminal.flatMap(stepsToCompensate)
  }
}
