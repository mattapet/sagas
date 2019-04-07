//
//  Hotel+Task.swift
//  Run
//
//  Created by Peter Matta on 3/15/19.
//

import Basic
import CoreSaga
import Foundation

public struct HotelReservationTask: Job {
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
    // Create reservation for hotel
    let reservation = HotelReservation(tripId: tripId, hotel: hotel)
    // Try to find a reservation for the given hotel within the same trip
    if let _ = try await(reservation.key, HotelReservation.load) {
      // If such reservation found, return so we maintain idempotency
      return
    }
    // Create a new one otherwise
    try await(reservation.save)
    // create reservation
    print("[HOTEL][RESERVATION]: \(tripId):\(hotel)")
  }
}

public struct HotelReservationCancellationTask: Job {
  public init() { }
  
  public func execute(
    using payload: Data?,
    with completion: (Result<Data?, Error>) -> Void
  ) {
    completion(Result { () -> Data? in
      guard let payload = payload else { throw TripError.invalidHotelPayload }
      let trip = try utils.decoder.decode(Trip.self, from: payload)
      try cancelReservation(for: trip.hotel, withTripId: trip.tripId)
      return try utils.encoder.encode(trip)
    })
  }
  
  func cancelReservation(for hotel: Hotel, withTripId tripId: Int) throws {
    // Create cancelled reservation for hotel and trip
    let reservation =
      HotelReservation(tripId: tripId, hotel: hotel, cancelled: true)
    // Override existing reservation or create new one
    try await(reservation.save)
    // cancel reservation
    print("[HOTEL][CANCELLATION]: \(tripId)")
  }
}

