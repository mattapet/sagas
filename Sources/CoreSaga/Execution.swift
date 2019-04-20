//
//  Execution.swift
//  CoreSaga
//
//  Created by Peter Matta on 4/11/19.
//

import Basic
import Dispatch
import Foundation

public protocol Execution {
  associatedtype SagaType: AnySaga
  associatedtype ExecutorType: Executor = Executor
  
  var saga: SagaType { get }
  var executor: ExecutorType { get }
  
  func launch(with completion: @escaping (Result<Data?, Error>) -> Void)
  func start() throws
  func complete() throws
  func fail(error: Error) throws
}

extension Execution {
  public var sagaId: String {
    return saga.sagaId
  }
}
