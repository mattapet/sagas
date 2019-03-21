//
//  Saga.swift
//  Sagas
//
//  Created by Peter Matta on 3/19/19.
//

import Foundation

public final class Saga {
  enum State {
    case `init`, started, aborted, done
  }
  
  internal var state: State = .`init`
  public let name: String
  public let sagaId: String
  public let steps: [String:Step]
  public let payload: Data?
  
  public init(
    name: String,
    sagaId: String,
    steps: [String:Step],
    payload: Data? = nil
  ) {
    self.name = name
    self.sagaId = sagaId
    self.steps = steps
    self.payload = payload
  }
  
  public init(
    sagaId: String,
    definition: SagaDefinition,
    payload: Data? = nil
  ) {
    self.name = definition.name
    self.sagaId = sagaId
    self.steps = definition.produceExecutionGraph()
    self.payload = payload
  }
}

extension SagaDefinition {
  fileprivate var requestMap: [String:Request] {
    return requests.reduce(into: [:]) { $0[$1.key] = $1 }
  }
  
  fileprivate var compensationMap: [String:Compensation] {
    return compensations.reduce(into: [:]) { $0[$1.key] = $1 }
  }
  
  fileprivate func produceExecutionGraph() -> [String:Step] {
    let comps = compensationMap
    let successors: [String:Set<String>] = requests
      .reduce(into: [:]) { result, next in
        next.dependencies.forEach { result[$0, default: []].insert(next.key) }
      }
    return requestMap.compactMapValues { request in
      // At this point `compensation` must exists
      let compensation = comps[request.compensation]!
      let successors = successors[request.key] ?? []
      return Step(
        key: request.key,
        dependencies: request.dependencies,
        successors: Array(successors),
        transaction: request.task,
        compensation: compensation.task)
    }
  }
}
