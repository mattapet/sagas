//
//  CommandHandler.swift
//  CoreSaga
//
//  Created by Peter Matta on 4/2/19.
//

import Foundation

public protocol CommandHandler {
  associatedtype Aggregate
  associatedtype Command
  associatedtype ResultType
  
  func apply(
    _ command: Command,
    to aggregate: Aggregate,
    with completion: @escaping (Result<ResultType, Error>) -> Void
  )
}

