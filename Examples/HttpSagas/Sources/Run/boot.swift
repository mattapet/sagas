//
//  boot.swift
//  Run
//
//  Created by Peter Matta on 5/6/19.
//

import Vapor
import HttpSagas

var store: Store! = nil
var factory: HttpSagaExecutionFactory<Store>! = nil
var executor: SagaExecutor! = nil

/// Called after your application has initialized.
public func boot(_ app: Application) throws {
  store = Store(app: app)
  factory = HttpSagaExecutionFactory<Store>(
    executor: HttpExecutor(),
    repository: HttpRepository(store: store)
  )
  executor = SagaExecutor(factory: factory)
  
  let _ = Saga.query(on: store).all().map {
    $0.map { HttpSaga.init(sagaId: $0.sagaId!, definition: $0.definition) }
      .forEach { saga in
      executor.register(saga: saga) { _ in print("DONE: \(saga.sagaId)") }
    }
  }
}
