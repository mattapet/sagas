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
}
