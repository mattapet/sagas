//
//  Payment.swift
//  Run
//
//  Created by Peter Matta on 3/14/19.
//

import Foundation

public enum Currency: String, Codable {
  case USD, EUR, GBP
  
  public static var random: Currency {
    return [.USD, .EUR, .GBP].randomElement
  }
}

public enum PaymentType: String, Codable {
  case credit, debit
}

public struct Payment: Codable {
  public let accountId: Int
  public let amount: Double
  public let currency: Currency
  public let type: PaymentType
}

