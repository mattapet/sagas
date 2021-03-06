//
//  Saga+SagaDefinition.swift
//  LocalSagas
//
//  Created by Peter Matta on 4/5/19.
//

import CoreSaga
import CompensableSaga
import Foundation

extension SimpleSaga {
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
      return CompensableStep(
        sagaId: sagaId,
        key: request.key,
        dependencies: request.dependencies.compactMap { reqMap[$0]!.key },
        successors: Array(successorMap[request.key] ?? []),
        transaction: request.task,
        compensation: compMap[request.compensation]!.task
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
