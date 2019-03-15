//
//  Plane.swift
//  Run
//
//  Created by Peter Matta on 3/14/19.
//

import Sagas
import Foundation

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

public struct PlaneReservation: Sagas.Task {
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
    // create reservation
    print("[PLANE][RESERVATION]: \(tripId):\(plane)")
  }
}

public struct PlaneReservationCancellation: Sagas.Task {
  public init() { }
  
  public func execute(
    using payload: Data?,
    with completion: (Result<Data?, Error>
  ) -> Void) {
    completion(Result { () -> Data? in
      guard let payload = payload else { throw TripError.invalidPlanePayload }
      let trip = try utils.decoder.decode(Trip.self, from: payload)
      try cancelReservation(forTripId: trip.tripId)
      return try utils.encoder.encode(trip)
    })
  }
  
  func cancelReservation(forTripId tripId: Int) throws {
    // cancel reservation
    print("[PLANE][CANCELLATION]: \(tripId)")
  }
}
