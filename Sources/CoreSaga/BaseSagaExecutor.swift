//
//  BaseSagaExecutor.swift
//  CoreSaga
//
//  Created by Peter Matta on 4/4/19.
//

import Basic
import Dispatch
import Foundation

public enum ServiceError: Error {
  case invalidSagaId
  case invalidKeyId
}

open class BaseSagaExecutor<
  SagaType,
  ExecutionFactoryType: ExecutionFactory
> where SagaType == ExecutionFactoryType.SagaType
{
  public typealias ExecutionType = ExecutionFactoryType.ExecutionType
  
  private let lock: Lock
  private var completions: [String:Disposable]
  private var executions: [String:ExecutionType]
  private let factory: ExecutionFactoryType
  
  public init(factory: ExecutionFactoryType) {
    self.lock = Lock()
    self.executions = [:]
    self.completions = [:]
    self.factory = factory
  }
}

extension BaseSagaExecutor {
  public func register(
    saga: SagaType,
    with completion: @escaping (Result<Data?, Error>) -> Void
  ) {
    lock.withLock {
      let execution = factory.create(from: saga)
      executions[saga.sagaId] = execution

      execution.launch { [weak self] result in
        self?.lock.withLock { [weak self] in
          self?.completions.removeValue(forKey: saga.sagaId)
          completion(result)
        }
      }
    }
  }
}
