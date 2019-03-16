//
//  Plane+Model.swift
//  Run
//
//  Created by Peter Matta on 3/15/19.
//

import Foundation

public struct PlaneReservation {
  public let tripId: Int
  public let plane: Plane
  public var cancelled: Bool
  
  public init(
    tripId: Int,
    plane: Plane,
    cancelled: Bool = false
  ) {
    self.tripId = tripId
    self.plane = plane
    self.cancelled = cancelled
  }
}

extension PlaneReservation: AsyncModel {
  public typealias Key = String
  public var key: String {
    return "\(tripId):\(plane.ticketNumber)"
  }
}
extension PlaneReservation: Cancellable {}
