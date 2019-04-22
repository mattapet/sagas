//
//  Job.swift
//  CoreSaga
//
//  Created by Peter Matta on 4/4/19.
//

import Foundation

public protocol Job {
  func execute(
    using payload: Data?,
    with completion: @escaping (Result<Data?, Error>) -> Void
  )
}
