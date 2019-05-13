//
//  routes.swift
//  Run
//
//  Created by Peter Matta on 5/6/19.
//

import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
  // Basic "It works" example
  router.get { req in
    return "It works!"
  }
  
  // Basic "Hello, world!" example
  router.get("hello") { req in
    return "Hello, world!"
  }
  
  // Example of configuring a controller
  let sagaController = SagaController()
  router.get("sagas", use: sagaController.index)
  router.post("sagas", use: sagaController.execute)
//  router.delete("todos", Todo.parameter, use: todoController.delete)
}
