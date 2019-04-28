//
//  Step.swift
//  CoreSaga
//
//  Created by Peter Matta on 4/4/19.
//

import Foundation

/// Protocol describing a generic saga step.
///
/// Saga step represents a single represents a single operation of the process
/// or operation that is described by the saga itself. It is used as a basic
/// building block for execution and state maintenance of the process.
///
/// Design of `Step`s
/// =================
///
/// Each step (or node) can have 0 or more dependencies, steps that must
/// complete before the current step can start to be executed. It also can have
/// 0 or more successors. Successors are basically steps derived from graph by
/// inverting dependency relationship.
///
/// For example: If we have a step `A` with dependencies `B` and `C`, then steps
/// `B` and `C` would have both a since successor `A`.
///
/// Identification
/// --------------
///
/// Each step is uniquely identified by `sagaId` and `key` properties.
/// Furthermore `sagaId` property must match the `sagaId` property of the saga
/// the step relates to.
///
/// - seealso:
///   - AnySaga
public protocol AnyStep {
  /// Saga identifier.
  var sagaId: String { get }
  /// Unique identifier of the step.
  var key: String { get }
  /// List of steps (their keys), which are required to complete before
  /// execution of this step can begin.
  var dependencies: [String] { get }
  /// List of steps (their keys), which require execution of this step to
  /// complete.
  var successors: [String] { get }
}

extension AnyStep {
  public static func == (_ lhs: Self, _ rhs: Self) -> Bool {
    return lhs.sagaId == rhs.sagaId && lhs.key == rhs.key
  }
}

extension AnyStep {
  /// `true` if the step is initial, a.k.a does not have any dependencies,
  /// `false` otherwise.
  public var isInitial: Bool {
    return dependencies.isEmpty
  }

  /// `true` if the step is terminal, a.k.a no other step that depends on this
  /// one, `false` otherwise.
  public var isTerminal: Bool {
    return successors.isEmpty
  }
}
