//
//  Car+Model.swift
//  Basic
//
//  Created by Peter Matta on 3/15/19.
//


public struct CarReservation {
  public let tripId: Int
  public let car: Car
  public var cancelled: Bool
  
  public init(
    tripId: Int,
    car: Car,
    cancelled: Bool = false
  ) {
    self.tripId = tripId
    self.car = car
    self.cancelled = cancelled
  }
}

extension CarReservation: Model {
  public typealias Key = String
  public var key: String {
    return "\(tripId):\(car.carId)"
  }
}
extension CarReservation: Cancellable {}

