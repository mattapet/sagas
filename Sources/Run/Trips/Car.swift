//
//  Car.swift
//  Run
//
//  Created by Peter Matta on 3/14/19.
//

import Sagas
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

public struct CarReservation: Sagas.Task {
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
    // reserve car
    print("[CAR][RESERVATION] \(tripId):\(car)")
  }
}

public struct CarReservationCancellation: Sagas.Task {
  public init() { }
  
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
    print("[CAR][CANCELATION] \(tripId)")
  }
}
