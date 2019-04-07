//
//  ClosureTask.swift
//  LocalSagas
//
//  Created by Peter Matta on 3/21/19.
//

import CoreSaga
import Foundation

public protocol ClosureJob: Sagas.Task {
  var closure: (Data?, (Result<Data?, Error>) -> Void) -> Void { get }
}

extension ClosureJob {
  public func execute(
    using payload: Data?,
    with completion: (Result<Data?, Error>) -> Void
  ) {
    closure(payload) { completion($0) }
  }
}

public struct BasicTask: ClosureJob {
  public let closure: (Data?, (Result<Data?, Error>) -> Void) -> Void
}
