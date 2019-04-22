//
//  Saga+SagaDefinition.swift
//  HttpSagas
//
//  Created by Peter Matta on 4/21/19.
//

import CompensableSaga
import Foundation

extension HttpSaga {
  public init(
    sagaId: String = UUID().uuidString,
    definition: SagaDefinition,
    payload: Data? = nil
  ) {
    let reqMap = definition.requestMap
    let compMap = definition.compensationMap
    precondition(reqMap.count == definition.requests.count)
    precondition(compMap.count == definition.requests.count)
    let successorMap: [String:Set<String>] = definition.requests
      .reduce(into: [:]) { result, next in
        next.dependencies.forEach {
          result[$0, default: []].insert(next.key)
        }
      }
    
    self.state = .fresh
    self.sagaId = sagaId
    self.payload = payload
    self.steps = reqMap.mapValues { request in
      let compensation = compMap[request.compensation]!
      return CompensableStep(
        sagaId: sagaId,
        key: request.key,
        dependencies: request.dependencies.compactMap { reqMap[$0]!.key },
        successors: Array(successorMap[request.key] ?? []),
        transaction: HttpJob(
          url: URL(string: request.url)!,
          httpMethod: request.httpMethod),
        compensation: HttpJob(
          url: URL(string: compensation.url)!,
          httpMethod: compensation.httpMethod)
      )
    }
  }
}

extension SagaDefinition {
  fileprivate var requestMap: [String:Request] {
    return requests.reduce(into: [:]) { $0[$1.key] = $1 }
  }
  
  fileprivate var compensationMap: [String:Compensation] {
    return compensations.reduce(into: [:]) { $0[$1.key] = $1 }
  }
}
