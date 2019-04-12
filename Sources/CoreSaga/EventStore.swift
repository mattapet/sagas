//
//  EventStore.swift
//  CoreSaga
//
//  Created by Peter Matta on 4/4/19.
//

import Foundation

public protocol EventStore {
  func load(
    for saga: AnySaga,
    with completion: (Result<[Event], Error>) -> Void
  )
  
  func store(
    _ events: [Event],
    for saga: AnySaga,
    with completion: (Result<(), Error>) -> Void
  )
}
