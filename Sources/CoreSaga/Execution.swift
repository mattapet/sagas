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
  
  var saga: SagaType { get }
  
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
