//
//  Aggregator.swift
//  CoreSaga
//
//  Created by Peter Matta on 3/29/19.
//

import Foundation

public protocol Aggregator {
  associatedtype Aggregate: AnyObject
  associatedtype EventType
  
  func apply(_ event: EventType, to aggregate: Aggregate)
}

public protocol ReplayableAggregator: Aggregator {
  func replay(_ event: EventType, on aggregate: Aggregate)
}
