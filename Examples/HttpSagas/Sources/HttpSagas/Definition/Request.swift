//
//  Request.swift
//  HttpSagas
//
//  Created by Peter Matta on 4/21/19.
//

public struct Request: Codable {
  public let key: String
  public let dependencies: [String]
  public let compensation: String
  public let url: String
  public let httpMethod: String
}
