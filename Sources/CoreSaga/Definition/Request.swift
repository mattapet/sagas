//
//  Request.swift
//  CoreSaga
//
//  Created by Peter Matta on 4/4/19.
//

import Foundation

public struct Request {
  public let key: String
  public let dependencies: [String]
  public let compensation: String
  public let task: Job
}
