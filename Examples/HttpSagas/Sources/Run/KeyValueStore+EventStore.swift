//
//  KeyValueStore+EventStore.swift
//  Run
//
//  Created by Peter Matta on 4/22/19.
//

import CoreSaga
import HttpSagas

public struct SagaEntry: Codable {
  public let definition: SagaDefinition
  public let events: [Event]
  
  public init(definition: SagaDefinition, events: [Event] = []) {
    self.definition = definition
    self.events = events
  }
  
  public func withEvents(_ events: [Event]) -> SagaEntry {
    return SagaEntry(definition: definition, events: self.events + events)
  }
}

extension KeyValueStore {
  public func register(saga: HttpSaga, for definition: SagaDefinition) throws {
    try setValue(SagaEntry(definition: definition), forKey: saga.sagaId)
  }
}

extension KeyValueStore: EventStore {
  public typealias SagaType = HttpSaga
  
  public func load(
    for saga: SagaType,
    with completion: (Result<[Event], Error>) -> Void
  ) {
    completion(Result {
      return try loadValue(forKey: saga.sagaId, as: SagaEntry.self).events
    })
  }
  
  public func store(
    _ events: [Event],
    for saga: SagaType,
    with completion: (Result<(), Error>) -> Void
  ) {
    completion(Result {
      let entry = try loadValue(forKey: saga.sagaId, as: SagaEntry.self)
        .withEvents(events)
      try setValue(entry, forKey: saga.sagaId)
    })
  }
}
