//
//  SimpleSagaExecutionFactory.swift
//  LocalSagas
//
//  Created by Peter Matta on 4/15/19.
//

import CoreSaga
import CompensableSaga
import Foundation

public final class SimpleSagaExecutionFactory: ExecutionFactory {
  public typealias SagaType = SimpleSaga
  public typealias ExecutionType =
    CompensableExecution<SimpleSaga, SimpleExecutor, SimpleRepository>
  
  private let repository: SimpleRepository =
    SimpleRepository(store: SimpleEventStore())
  private let executor: SimpleExecutor = SimpleExecutor()
  
  fileprivate init() {}
  
  private static let _shared: SimpleSagaExecutionFactory =
    SimpleSagaExecutionFactory()
  public static var shared: SimpleSagaExecutionFactory {
    return _shared
  }
  
  public func create(
    from saga: SimpleSaga
  ) -> CompensableExecution<SimpleSaga, SimpleExecutor, SimpleRepository> {
    return CompensableExecution(
      saga: saga,
      executor: executor,
      repository: repository)
  }
}
