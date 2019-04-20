//
//  Executor.swift
//  CoreSaga
//
//  Created by Peter Matta on 4/19/19.
//

import Foundation

public protocol Executor {
  func execute(
    _ job: Job,
    using payload: Data?,
    with completion: @escaping (Result<Data?, Error>) -> Void
  )
}
