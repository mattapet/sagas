//
//  HttpSagaFactory.swift
//  HttpSagas
//
//  Created by Peter Matta on 4/21/19.
//

import CoreSaga
import CompensableSaga

public final class HttpSagaExecutionFactory<Store: EventStore>
  where Store.SagaType == HttpSaga
{
  public typealias SagaType = HttpSaga
  public typealias ExecutionType =
    CompensableExecution<HttpSaga, HttpExecutor, HttpRepository<Store>>
  
  public let executor: HttpExecutor
  public let repository: HttpRepository<Store>
  
  public init(
    executor: HttpExecutor = HttpExecutor.shared,
    repository: HttpRepository<Store>
  ) {
    self.executor = executor
    self.repository = repository
  }
}

extension HttpSagaExecutionFactory: ExecutionFactory {
  public func create(from saga: HttpSaga) -> ExecutionType {
    return ExecutionType(saga: saga, executor: executor, repository: repository)
  }
}
