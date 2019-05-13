//
//  Saga.swift
//  Run
//
//  Created by Peter Matta on 5/6/19.
//

import CoreSaga
import HttpSagas
import FluentSQLite
import Vapor

final class Saga: Model {
  typealias Database = SQLiteDatabase
  typealias ID = String
  static let idKey: IDKey = \.sagaId

  var sagaId: String?
  
  var definition: SagaDefinition
  
  private var _events: Data
 
  var events: [Event] {
    set { _events = try! JSONEncoder().encode(newValue) }
    get { return try! JSONDecoder().decode([Event].self, from: _events) }
  }
  
  /// Creates a new `Saga`.
  init(sagaId: String?, definition: SagaDefinition, events: [Event] = []) {
    self.sagaId = sagaId
    self.definition = definition
    self._events = try! JSONEncoder().encode(events)
  }
}

/// Allows `Todo` to be used as a dynamic migration.
extension Saga: Migration { }

/// Allows `Todo` to be encoded to and decoded from HTTP messages.
extension Saga: Content { }

/// Allows `Todo` to be used as a dynamic parameter in route definitions.
extension Saga: Parameter { }

