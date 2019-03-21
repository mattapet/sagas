//
//  utils.swift
//  Run
//
//  Created by Peter Matta on 3/14/19.
//

import Foundation

public struct utils {
  private init() {}
  
  public static let decoder = { JSONDecoder() }()
  public static let encoder = { JSONEncoder() }()
}
