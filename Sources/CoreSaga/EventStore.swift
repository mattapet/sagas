//
//  EventStore.swift
//  CoreSaga
//
//  Created by Peter Matta on 4/4/19.
//

import Foundation

public protocol EventStore {
  func load<S: AnySaga>(
    for saga: S,
    with completion: (Result<[Event], Error>) -> Void
  )
  
  func store<S: AnySaga>(
    _ events: [Event],
    for saga: S,
    with completion: (Result<(), Error>) -> Void
  )
}
