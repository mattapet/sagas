//
//  SagaDefinition.swift
//  LocalSagas
//
//  Created by Peter Matta on 4/4/19.
//

import CoreSaga

public struct SagaDefinition {
  public typealias RequestType = Request
  public typealias CompensationType = Compensation
  
  public let name: String
  public let requests: [RequestType]
  public let compensations: [CompensationType]
  
  public init(
    name: String,
    requests: [RequestType],
    compensations: [CompensationType]
  ) {
    self.name = name
    self.requests = requests
    self.compensations = compensations
  }
}

extension Request {
  public static func request(
    key: String,
    dependencies: [String],
    compensation: String,
    task: Job
  ) -> Request {
    return Request(
      key: key,
      dependencies: dependencies,
      compensation: compensation,
      task: task
    )
  }
  
  public static func request(
    key: String,
    compensation: String,
    task: Job
  ) -> Request {
    return Request(
      key: key,
      dependencies: [],
      compensation: compensation,
      task: task
    )
  }
}

extension Compensation {
  public static func compensation(
    key: String,
    task: Job
  ) -> Compensation {
    return Compensation(
      key: key,
      task: task
    )
  }
}
