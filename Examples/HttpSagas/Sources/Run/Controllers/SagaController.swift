//
//  SagaController.swift
//  Run
//
//  Created by Peter Matta on 5/6/19.
//

import Vapor
import HttpSagas

final class SagaController {
  func index(_ req: Vapor.Request) throws -> Future<[Saga]> {
    return Saga.query(on: req).all()
  }
  
  func execute(_ req: Vapor.Request) throws -> Future<HTTPStatus> {
    return try req.content.decode(SagaDefinition.self)
      .map {
        Saga(sagaId: UUID().uuidString, definition: $0)
      }
      .flatMap { saga in saga.create(on: req) }
      .map { HttpSaga(sagaId: $0.sagaId!, definition: $0.definition) }
      .map { executor.register(saga: $0) { _ in print("DONE") } }
      .transform(to: .accepted)
  }
}
