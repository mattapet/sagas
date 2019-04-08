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

public struct Saga {
  public enum State {
    case fresh
    case started
    case aborted
    case completed
  }
  
  public let state: State
  
  public let sagaId: String
  public let steps: [String:Step]
  public let payload: Data?
  
  public init(
    sagaId: String,
    steps: [String:Step],
    payload: Data? = nil
  ) {
    self.state = .fresh
    self.sagaId = sagaId
    self.steps = steps
    self.payload = payload
  }
}

extension Saga {
  public var initial: [Step] {
    return steps.values.filter { $0.isInitial }
  }
  
  public var terminal: [Step] {
    return steps.values.filter { $0.isTerminal }
  }
  
  public func stepUpdated(_ step: Step) -> Saga {
    return Saga(
      state: state,
      sagaId: sagaId,
      steps: steps.mapValues { $0.key == step.key ? step : $0 },
      payload: payload
    )
  }
  
  public func stepFor(_ stepKey: String) throws -> Step {
    switch steps[stepKey] {
    case .some(let step): return step
    case .none: throw SagaError.invalidKeyId
    }
  }
}

extension Saga {
  /// Returns array of saga steps that can be started.
  ///
  /// - description:
  ///     Method expects saga to be in `fresh` or `started` state. The reason
  ///     for such constraint is that the saga cannot start any of its steps
  ///     in any other state.
  ///
  /// - return: An array of saga fresh steps that can be started.
  public func stepsToStart() throws -> [Step] {
    // Ensure state of the saga
    precondition(state == .fresh || state == .started)
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
  
  /// Returns array of saga steps that can be compensated.
  ///
  /// - description:
  ///     Method expects saga to be in `aborted`. The reason for such constraint
  ///     is that the saga cannot compensate any of its steps in any other
  ///     state.
  ///
  /// - return: An array of saga completed or started steps that can be started.
  public func stepsToCompensate() throws -> [Step] {
    // Ensure state of the saga
    precondition(state == .aborted)
    // Set of all traversed steps
    var visited = Set<String>()
    
    // A helper function returning all fresh completed or started reachable
    // from the given step.
    func stepsToCompensate(from step: Step) throws -> [Step] {
      // Make sure that traverse add each step only once -- there may exists
      // multiple leading edges (step can have multiple dependencies).
      guard visited.insert(step.key).inserted else { return [] }
      // If the current step is fresh, return it.
      if step.isCompleted || step.isStarted { return [step] }
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

extension Saga {
  fileprivate init(
    state: State,
    sagaId: String,
    steps: [String:Step],
    payload: Data? = nil
  ) {
    self.state = state
    self.sagaId = sagaId
    self.steps = steps
    self.payload = payload
  }

  public func started(payload: Data? = nil) -> Saga {
    return Saga(
      state: .started,
      sagaId: sagaId,
      steps: steps,
      payload: payload ?? self.payload
    )
  }
  
  public func aborted() -> Saga {
    return Saga(
      state: .aborted,
      sagaId: sagaId,
      steps: steps,
      payload: payload
    )
  }
  
  public func completed() -> Saga {
    return Saga(
      state: .completed,
      sagaId: sagaId,
      steps: steps,
      payload: payload
    )
  }
}
