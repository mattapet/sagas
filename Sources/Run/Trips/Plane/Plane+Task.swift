//
//  Plane+Task.swift
//  Run
//
//  Created by Peter Matta on 3/15/19.
//

import Sagas
import Foundation

public struct PlaneReservationTask: Sagas.Task {
  public init() { }
  
  public func execute(
    using payload: Data?,
    with completion: (Result<Data?, Error>
  ) -> Void) {
    completion(Result { () -> Data? in
      guard let payload = payload else { throw TripError.invalidPlanePayload }
      let trip = try utils.decoder.decode(Trip.self, from: payload)
      try reserve(trip.plane, forTripId: trip.tripId)
      return try utils.encoder.encode(trip)
    })
  }
  
  func reserve(_ plane: Plane, forTripId tripId: Int) throws {
    // Create reservation for plane
    let reservation = PlaneReservation(tripId: tripId, plane: plane)
    // Try to find a reservation for the given plane within the same trip
    if let _ = try PlaneReservation.loadSync(byKey: reservation.key) {
      // If such reservation found, return so we maintain idempotency
      return
    }
    try reservation.saveSync()
    // create reservation
    print("[PLANE][RESERVATION]: \(tripId):\(plane)")
  }
}

public struct PlaneReservationCancellationTask: Sagas.Task {
  public init() { }
  
  public func execute(
    using payload: Data?,
    with completion: (Result<Data?, Error>
  ) -> Void) {
    completion(Result { () -> Data? in
      guard let payload = payload else { throw TripError.invalidPlanePayload }
      let trip = try utils.decoder.decode(Trip.self, from: payload)
      try cancelReservation(for: trip.plane, withTripId: trip.tripId)
      return try utils.encoder.encode(trip)
    })
  }
  
  func cancelReservation(for plane: Plane, withTripId tripId: Int) throws {
    // Create cancelled reservation for plane and trip
    let reservation =
        PlaneReservation(tripId: tripId, plane: plane, cancelled: true)
    // Override existing reservation or create new one
    try reservation.saveSync()
    // cancel reservation
    print("[PLANE][CANCELLATION]: \(tripId)")
  }
}

