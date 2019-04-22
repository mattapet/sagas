//
//  CompensableSaga.swift
//  CompensableSaga
//
//  Created by Peter Matta on 4/15/19.
//

import CoreSaga
import Foundation

public enum SagaState {
  case fresh, started, aborted, completed
}

public protocol CompensableSaga: AnySaga
  where StepType == CompensableStep, State == SagaState
{
  func started(payload: Data?) -> Self
  func aborted() -> Self
  func completed() -> Self
  func stepsToComplete() throws -> [StepType]
  func stepsToCompensate() throws -> [StepType]
}

extension CompensableSaga {
  public var isCompleted: Bool {
    switch state {
    case .started: return steps.allSatisfy { $0.value.isCompleted }
    case .fresh: return false
    case .aborted: return steps.allSatisfy { $0.value.isCompensated || $0.value.isFresh || $0.value.isAborted }
    case .completed: return true
    }
  }
}

extension CompensableSaga {
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
  
  /// Returns array of saga steps that can be compensated.
  ///
  /// Method expects saga to be in `aborted`. The reason for such constraint
  /// is that the saga cannot compensate any of its steps in any other state.
  ///
  /// - returns: An array of saga completed or started steps that can be
  ///    started.
  public func stepsToComplete() throws -> [StepType] {
    // Ensure state of the saga
    guard state == .aborted else { return [] }
    // Set of all traversed steps
    var visited = Set<String>()
    
    // A helper function returning all fresh steps reachable from the given
    // step.
    func stepsToComplete(from step: StepType) throws -> [StepType] {
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
  public func stepsToCompensate() throws -> [StepType] {
    // Ensure state of the saga
    guard state == .aborted else { return [] }
    // Set of all traversed steps
    var visited = Set<String>()
    
    // A helper function returning all fresh completed or started reachable
    // from the given step.
    func stepsToCompensate(from step: StepType) throws -> [StepType] {
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
