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

public protocol AnySaga {
  associatedtype State
  associatedtype StepType: AnyStep
  
  var state: State { get }
  var sagaId: String { get }
  var steps: [String:StepType] { get }
  var payload: Data? { get }
  
  var isCompleted: Bool { get }
  
  func updating(step: StepType) -> Self
  func stepFor(_ stepKey: String) throws -> StepType
}

extension AnySaga {
  public var initial: [StepType] {
    return steps.values.filter { $0.isInitial }
  }
  
  public var terminal: [StepType] {
    return steps.values.filter { $0.isTerminal }
  }
  
  public func stepFor(_ stepKey: String) throws -> StepType {
    return try steps[stepKey] ?? { throw SagaError.invalidKeyId }()
  }
}
