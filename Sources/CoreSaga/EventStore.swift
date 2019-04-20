//
//  EventStore.swift
//  CoreSaga
//
//  Created by Peter Matta on 4/4/19.
//

import Foundation

public protocol EventStore {
  associatedtype SagaType: AnySaga = AnySaga
  
  func load(
    for saga: SagaType,
    with completion: (Result<[Event], Error>) -> Void
  )
  
  func store(
    _ events: [Event],
    for saga: SagaType,
    with completion: (Result<(), Error>) -> Void
  )
}
