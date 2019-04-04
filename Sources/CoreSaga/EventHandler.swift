//
//  EventHandler.swift
//  CoreSaga
//
//  Created by Peter Matta on 4/2/19.
//

import Foundation

public protocol EventHandler {
  associatedtype Aggregate: Identifiable
  associatedtype Event: Codable
  
  func apply(
    _ event: Event,
    to aggregate: Aggregate,
    with completion: @escaping (Result<Aggregate, Error>) -> Void
  )
}

