//
//  Plane.swift
//  Run
//
//  Created by Peter Matta on 3/14/19.
//

public enum PlaneClass: String, Codable {
  case economy, economyPlus, business
  
  public static var random: PlaneClass {
    return [.economy, .economyPlus, .business].randomElement
  }
}

public struct Plane: Codable {
  public let ticketNumber: String
  public let seat: String
  public let flightNumber: String
  public let `class`: PlaneClass
}
