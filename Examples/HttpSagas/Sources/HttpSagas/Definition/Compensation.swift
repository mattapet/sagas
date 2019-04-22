//
//  Compensation.swift
//  HttpSagas
//
//  Created by Peter Matta on 4/21/19.
//

public struct Compensation: Codable {
  public let key: String
  public let url: String
  public let httpMethod: String
}
