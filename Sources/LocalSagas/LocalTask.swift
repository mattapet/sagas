//
//  LocalTask.swift
//  LocalSagas
//
//  Created by Peter Matta on 3/21/19.
//

import Sagas
import Foundation

public protocol ClosureTask: Sagas.Task {
  var closure: (Data?, (Result<Data?, Error>) -> Void) -> Void { get }
}

extension ClosureTask {
  public func execute(
    using payload: Data?,
    with completion: (Result<Data?, Error>) -> Void
  ) {
    closure(payload) { completion($0) }
  }
}

public struct LocalTask: ClosureTask {
  public let closure: (Data?, (Result<Data?, Error>) -> Void) -> Void
}
