//
//  Hotel+Model.swift
//  Run
//
//  Created by Peter Matta on 3/15/19.
//

import Foundation

public struct HotelReservation {
  public let tripId: Int
  public let hotel: Hotel
  public var cancelled: Bool
  
  public init(
    tripId: Int,
    hotel: Hotel,
    cancelled: Bool = false
  ) {
    self.tripId = tripId
    self.hotel = hotel
    self.cancelled = cancelled
  }
}

extension HotelReservation: Model {
  public typealias Key = String
  public var key: String {
    return "\(tripId):\(hotel.hotelId):\(hotel.room)"
  }
}
extension HotelReservation: Cancellable {}
