//
//  Hotel.swift
//  Run
//
//  Created by Peter Matta on 3/14/19.
//

import Sagas
import Foundation

public struct Hotel: Codable {
  public let hotelId: Int
  public let room: String
  public let checkin: Date
  public let checkout: Date
  public let notes: String?
}

public struct HotelReservation: Sagas.Task {
  public init() { }
  
  public func execute(
    using payload: Data?,
    with completion: (Result<Data?, Error>
  ) -> Void) {
    completion(Result { () -> Data? in
      guard let payload = payload else { throw TripError.invalidHotelPayload }
      let trip = try utils.decoder.decode(Trip.self, from: payload)
      try reserve(trip.hotel, forTripId: trip.tripId)
      return try utils.encoder.encode(trip)
    })
  }
  
  func reserve(_ hotel: Hotel, forTripId tripId: Int) throws {
    // create reservation
    print("[HOTEL][RESERVATION]: \(tripId):\(hotel)")
  }
}

public struct HotelReservationCancellation: Sagas.Task {
  public init() {
    
  }
  
  public func execute(
    using payload: Data?,
    with completion: (Result<Data?, Error>
  ) -> Void) {
    completion(Result { () -> Data? in
      guard let payload = payload else { throw TripError.invalidHotelPayload }
      let trip = try utils.decoder.decode(Trip.self, from: payload)
      try cancelReservation(forTripId: trip.tripId)
      return try utils.encoder.encode(trip)
    })
  }
  
  func cancelReservation(forTripId tripId: Int) throws {
    // cancel reservation
    print("[HOTEL][CANCELLATION]: \(tripId)")
  }
}
