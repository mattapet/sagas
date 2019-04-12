//
//  SagaExecutor.swift
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

public final class SagaExecutor<SagaType, RepositoryType: Repository>
  where SagaType == RepositoryType.SagaType
{
  private let lock: Lock
  private var retries: [String:Int] = [:]
  private var completions: [String:Disposable]
  private var executions: [String:Execution<SagaType, RepositoryType>]
  private let repository: RepositoryType
  
  public init(repository: RepositoryType) {
    self.lock = Lock()
    self.executions = [:]
    self.completions = [:]
    self.repository = repository
  }
}

extension SagaExecutor {
  public func register(
    saga: SagaType,
    with completion: @escaping (Result<Data?, Error>) -> Void
  ) {
    lock.withLock {
      let execution = Execution(saga: saga, repository: repository)
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

extension SagaExecutor where SagaType: CompensableSaga {
  public func register(
    saga: SagaType,
    with completion: @escaping (Result<Data?, Error>) -> Void
  ) {
    lock.withLock {
      let execution = Execution(saga: saga, repository: repository)
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
