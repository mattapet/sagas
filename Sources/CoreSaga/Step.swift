//
//  Step.swift
//  CoreSaga
//
//  Created by Peter Matta on 4/4/19.
//

import Foundation

public protocol AnyStep {
  associatedtype State
  
  var state: State { get }
  var sagaId: String { get }
  var key: String { get }
  var dependencies: [String] { get }
  var successors: [String] { get }
  
  var isInitial: Bool { get }
  var isTerminal: Bool { get }
}

extension AnyStep {
  public var isInitial: Bool {
    return dependencies.isEmpty
  }
  
  public var isTerminal: Bool {
    return successors.isEmpty
  }
}
