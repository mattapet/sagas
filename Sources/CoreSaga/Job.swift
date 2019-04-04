//
//  Job.swift
//  CoreSaga
//
//  Created by Peter Matta on 4/2/19.
//

import Foundation

public protocol Job {
  func execute(
    using payload: Data?,
    with completion: (Result<Data?, Error>) -> Void
  )
}

