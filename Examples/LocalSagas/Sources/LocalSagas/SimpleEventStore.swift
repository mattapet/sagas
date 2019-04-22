//
//  SimpleEventStore.swift
//  LocalSagas
//
//  Created by Peter Matta on 4/15/19.
//

import CoreSaga

public final class SimpleEventStore: EventStore {
  public typealias SagaType = SimpleSaga
  
  private var store: [String:[Event]] = [:]
  
  public func load(
    for saga: SagaType,
    with completion: (Result<[Event], Error>) -> Void
  ) {
    completion(Result { store[saga.sagaId] ?? [] })
  }
  
  public func store(
    _ events: [Event],
    for saga: SagaType,
    with completion: (Result<(), Error>) -> Void
  ) {
    completion(Result { store[saga.sagaId, default: []] += events })
  }
}
