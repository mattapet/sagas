//
//  SimpleExecutor.swift
//  LocalSagas
//
//  Created by Peter Matta on 4/19/19.
//

import Basic
import CoreSaga
import Dispatch
import Foundation

public final class SimpleExecutor: Executor {
  public func execute(
    _ job: Job,
    using payload: Data?,
    with completion: @escaping (Result<Data?, Error>) -> Void
  ) {
    DispatchQueue.global().async {
      completion(Result {
        try await(payload, job.execute)
      })
    }
  }
}
