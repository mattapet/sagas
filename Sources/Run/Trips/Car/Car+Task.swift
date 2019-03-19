//
//  Car+Task.swift
//  Basic
//
//  Created by Peter Matta on 3/15/19.
//

import Sagas
import Foundation

public struct CarReservationTask: Sagas.Task {
  public init() { }
  
  public func execute(
    using payload: Data?,
    with completion: (Result<Data?, Error>
  ) -> Void) {
    completion(Result { () -> Data? in
      guard let payload = payload else { throw TripError.invalidHotelPayload }
      let trip = try utils.decoder.decode(Trip.self, from: payload)
      try reserve(trip.car, forTripId: trip.tripId)
      return try utils.encoder.encode(trip)
    })
  }
  
  func reserve(_ car: Car, forTripId tripId: Int) throws {
    // Create reservation for plane
    let reservation = CarReservation(tripId: tripId, car: car)
    // Try to find a reservation for the given plane within the same trip
    if let _ = try CarReservation.loadSync(byKey: reservation.key) {
      // If such reservation found, return so we maintain idempotency
      return
    }
    try reservation.saveSync()
    // create reservation
    print("[CAR][RESERVATION] \(tripId):\(car)")
  }
}

public struct CarReservationCancellationTask: Sagas.Task {
  public init() { }
  
  public func execute(
    using payload: Data?,
    with completion: (Result<Data?, Error>
  ) -> Void) {
    completion(Result { () -> Data? in
      guard let payload = payload else { throw TripError.invalidHotelPayload }
      let trip = try utils.decoder.decode(Trip.self, from: payload)
      try cancelReservation(for: trip.car, withTripId: trip.tripId)
      return try utils.encoder.encode(trip)
    })
  }
  
  func cancelReservation(for car: Car, withTripId tripId: Int) throws {
    // Create cancelled reservation for plane and trip
    let reservation =
      CarReservation(tripId: tripId, car: car, cancelled: true)
    // Override existing reservation or create new one
    try reservation.saveSync()
    // cancel reservation
    print("[CAR][CANCELATION] \(tripId)")
  }
}
