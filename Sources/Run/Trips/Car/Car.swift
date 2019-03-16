//
//  Car.swift
//  Run
//
//  Created by Peter Matta on 3/14/19.
//

import Foundation

public enum CarBrand: String, Codable {
  case Honda, Chevrolet, Kia, Ford, VW
  
  public static var random: CarBrand {
    return [.Honda, .Chevrolet, .Kia, .Ford, .VW].randomElement
  }
}

public struct Car: Codable {
  public let brand: CarBrand
  public let carId: Int
  public let pickup: Date
  public let dropoff: Date
}
