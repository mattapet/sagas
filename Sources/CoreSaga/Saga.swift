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

/// Protocol describing a generic saga.
///
/// Saga is description of a complex process which is can be divide into
/// descrete transactions.
///
/// Design of `Saga`s
/// =================
///
/// Protocol assumes imeplementors of `Saga` protocol to be have value semantic.
/// The reason for this descition is to make `Saga`s simple to reason about in
/// multi threaded environment, which is considered the most common use case.
///
/// `Saga` protocol thus require it's implementors to have immutable style
/// functions such as `updating(step:)`. These functions return a new `Saga`
/// object rather than mutate the one the function was called upon. For example:
///
///     func applyUpdate<S: AnySaga>(to saga: S) -> S {
///       let stepToUpdate = ...
///       return saga.updating(step: stepToUpdate)
///     }
///
/// Identification
/// --------------
///
/// Each saga is uniquely identified by `sagaId`. Therefore two saga's must be
/// equal iff they have the same `sagaId`.
///
/// Representation
/// --------------
///
/// Saga is represented as a Directed Asyclic Graph ([DAG](https://en.wikipedia.org/wiki/Directed_acyclic_graph))
/// which nodes (`Step`s) represent those discrete transactions. This implies
/// that `Saga` must have following rules:
///
/// * There must be at least one *initial* node
/// * There must be at least one *terminal* node
/// * There must not exist a dependency cycle
///
/// For example:
///
///         A
///       /   \
///      B     C
///       \   /
///         D
///
/// Links
/// =====
///
/// - [original paper](http://www.cs.cornell.edu/andru/cs711/2002fa/reading/sagas.pdf)
/// - [distributed sagas](https://github.com/aphyr/dist-sagas/blob/master/sagas.pdf)
///
/// - seealso:
///   - AnyStep
public protocol AnySaga {
  /// Type of the saga `Step`, representing node of the execution graph.
  associatedtype StepType: AnyStep
  
  /// Unique identifier of the saga.
  var sagaId: String { get }
  /// Map representation of the execution graph.
  ///
  /// The keys of the map are `AnyStep.key`s. Those are required to be unique
  /// within one saga.
  var steps: [String:StepType] { get }
  
  /// `true` if saga completed, `false` otherwise.
  var isCompleted: Bool { get }
  
  /// Returns a new saga updating given step of the saga.
  ///
  /// - parameters:
  ///   - step: Step to be updated within the saga.
  /// - returns: Saga with updated step.
  func updating(step: StepType) -> Self
}

extension AnySaga {
  public static func == (_ lhs: Self, _ rhs: Self) -> Bool {
    return lhs.sagaId == rhs.sagaId
  }
}

extension AnySaga {
  /// Returns an array of initial steps.
  public var initial: [StepType] {
    return steps.values.filter { $0.isInitial }
  }
  
  /// Returns an array of terminal steps.
  public var terminal: [StepType] {
    return steps.values.filter { $0.isTerminal }
  }
  
  public func stepFor(_ stepKey: String) throws -> StepType {
    return try steps[stepKey] ?? { throw SagaError.invalidKeyId }()
  }
}
