//
//  SagaRepository.swift
//  Run
//
//  Created by Peter Matta on 5/6/19.
//

import CoreSaga
import HttpSagas
import Vapor
import FluentSQLite

public final class Store {
  public typealias SagaType = HttpSaga
  let app: Application
  
  public init(app: Application) {
    self.app = app
  }
  
  public func load(for saga: HttpSaga) -> Future<[Event]> {
    return Saga.find(saga.sagaId, on: self).map { $0!.events }
  }

  public func store(_ events: [Event], for saga: HttpSaga) -> Future<()> {
    return Saga.find(saga.sagaId, on: self)
      .flatMap { (saga: Saga?) -> Future<Saga> in
        guard let saga = saga else { fatalError() }
        saga.events.append(contentsOf: events)
        return saga.save(on: self)
      }.map { _ in }
  }
}

extension Store: EventStore {
  public func load(
    for saga: HttpSaga,
    with completion: @escaping (Result<[Event], Error>) -> Void
  ) {
    let future = load(for: saga)
    future.whenSuccess { completion(.success($0)) }
    future.whenFailure { completion(.failure($0)) }
  }
  
  public func store(
    _ events: [Event],
    for saga: HttpSaga,
    with completion: @escaping (Result<(), Error>) -> Void
  ) {
    let future = store(events, for: saga)
    future.whenSuccess { _ in completion(.success(())) }
    future.whenFailure { completion(.failure($0)) }
  }
}

extension Store: DatabaseConnectable {
  public func shutdownGracefully(
    queue: DispatchQueue,
    _ callback: @escaping (Error?) -> Void
  ) {
    
  }
  
  public func databaseConnection<Database>(
    to database: DatabaseIdentifier<Database>?
  ) -> EventLoopFuture<Database.Connection>
    where Database: Vapor.Database
  {
    guard let database = database else { fatalError() }
    return app.requestCachedConnection(to: database, poolContainer: app)
  }
  
  public func next() -> EventLoop {
    return eventLoop.next()
  }
}
