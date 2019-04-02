//
//  EventStore.swift
//  CoreSaga
//
//  Created by Peter Matta on 4/2/19.
//

import Foundation

public protocol EventStore {
  associatedtype Aggregate: Identifiable
  associatedtype Event: Codable
  
  func load(
    byId: Aggregate.ID,
    with completion: @escaping (Result<[Event], Error>) -> Void
  )
  
  func save(
    event: Event,
    for aggregate: Aggregate,
    with completion: @escaping (Result<[Event], Error>) -> Void
  )
}

