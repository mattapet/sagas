//
//  SagaDefinition.swift
//  HttpSagas
//
//  Created by Peter Matta on 4/21/19.
//

public struct SagaDefinition: Codable {
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
    dependencies: [String] = [],
    compensation: String,
    url: String,
    httpMethod: String = "POST"
  ) -> Request {
    return Request(
      key: key,
      dependencies: dependencies,
      compensation: compensation,
      url: url,
      httpMethod: httpMethod
    )
  }
}

extension Compensation {
  public static func compensation(
    key: String,
    url: String,
    httpMethod: String = "POST"
  ) -> Compensation {
    return Compensation(
      key: key,
      url: url,
      httpMethod: httpMethod
    )
  }
}
