//
//  Saga.swift
//  CoreSaga
//
//  Created by Peter Matta on 4/2/19.
//

import Foundation

public final class Saga {
  internal enum State {
    case fresh, started, aborted, compensated, finished
  }
  
  internal var state: State = .fresh
  internal var steps: [String:Step]
  public let sagaId: String
  
  public init(
    steps: [String:Step],
    sagaId: String
  ) {
    self.steps = steps
    self.sagaId = sagaId
  }
}

extension Saga: Identifiable {
  public static var IDKeyPath: KeyPath<Saga, String> {
    return \Saga.sagaId
  }
}

