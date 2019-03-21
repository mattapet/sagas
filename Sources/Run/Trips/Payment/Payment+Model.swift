//
//  Payment+Model.swift
//  Run
//
//  Created by Peter Matta on 3/15/19.
//

import Foundation

// Each Trip can have at most one credit
public struct Credit {
  public let tripId: Int
  public let amount: Double
  public let currency: Currency
}

// Each Trip can have at most one debit
public struct Debit {
  public let tripId: Int
  public let amount: Double
  public let currency: Currency
}

extension Credit: Model {
  public typealias Key = Int
  public var key: Int {
    return tripId
  }
}

extension Debit: Model {
  public typealias Key = Int
  public var key: Int {
    return tripId
  }
}

