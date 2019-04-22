//
//  HttpExecutor.swift
//  HttpSagas
//
//  Created by Peter Matta on 4/21/19.
//

import Basic
import CoreSaga
import Foundation
import Dispatch

public final class HttpExecutor {
  public let numberOfRetries: Int
  
  private static let _shared: HttpExecutor = HttpExecutor()
  public static var shared: HttpExecutor {
    return _shared
  }
  
  public init(numberOfRetries: Int = 3) {
    precondition(numberOfRetries >= 0)
    self.numberOfRetries = numberOfRetries
  }
}

extension HttpExecutor: Executor {
  public func execute(
    _ job: Job,
    using payload: Data?,
    with completion: @escaping (Result<Data?, Error>) -> Void
  ) {
    let numberOfRetries = self.numberOfRetries
    DispatchQueue.global().async {
      var result = Result { try await(payload, job.execute) }
      for _ in 0..<numberOfRetries {
        // Make sure we retry iff the previous execution resulted in failure
        guard case .failure = result else { break }
        print("Retrying....")
        result = Result { try await(payload, job.execute) }
      }
      print("Completing RESULT: \(result)")
      completion(result)
    }
  }
}
