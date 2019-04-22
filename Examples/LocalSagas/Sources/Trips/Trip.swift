//
//  Trip.swift
//  Run
//
//  Created by Peter Matta on 3/14/19.
//

import Foundation

public enum TripError: Error {
  case invalidPaymentPayload
  case invalidCarPayload
  case invalidHotelPayload
  case invalidPlanePayload
}

public struct Trip: Codable {
  public let tripId: Int
  public let payment: Payment
  public let car: Car
  public let hotel: Hotel
  public let plane: Plane
  
  public init(
    tripId: Int = tripId,
    payment: Payment,
    car: Car,
    hotel: Hotel,
    plane: Plane
  ) {
    self.tripId = tripId
    self.payment = payment
    self.car = car
    self.hotel = hotel
    self.plane = plane
  }
  
  private static var _tripId = 0
  public static var tripId: Int {
    defer { _tripId += 1 }
    return _tripId
  }
}

extension Payment {
  public static func paymen(
    accountId: Int,
    amount: Double = Double.random(in: 0..<2000),
    currency: Currency = .random,
    type: PaymentType = .credit
  ) -> Payment {
    return Payment(
      accountId: accountId,
      amount: amount,
      currency: currency,
      type: type
    )
  }
}

extension Car {
  public static func car(
    brand: CarBrand = .random,
    carId: Int,
    pickup: Date = Date(),
    dropoff: Date = Date()
  ) -> Car {
    return Car(
      brand: brand,
      carId: carId,
      pickup: pickup,
      dropoff: dropoff
    )
  }
}

extension Hotel {
  public static func hotel(
    hotelId: Int,
    room: String = "\(Int.random(in: 0..<600))",
    checkin: Date = Date(),
    checkout: Date = Date(),
    notes: String? = nil
  ) -> Hotel {
    return Hotel(
      hotelId: hotelId,
      room: room,
      checkin: checkin,
      checkout: checkout,
      notes: notes
    )
  }
}

extension Plane {
  public static var randomSeat: String {
    let row = ["A", "B", "C", "D", "E", "F"]
    return "\(Int.random(in: 1...60))\(row.randomElement)\(row.randomElement)"
  }
  
  public static var randomFlightNumber: String {
    let characters = (0..<26).map { String(UInt8($0)) }
    return "\(characters.randomElement)\(characters.randomElement)" +
      "\(characters.randomElement)\(Int.random(in: 30..<500))"
  }
  
  public static func plane(
    ticketNumber: String,
    seat: String = randomSeat,
    flightNumber: String = randomSeat,
    `class`: PlaneClass = .random
  ) -> Plane {
    return Plane(
      ticketNumber: ticketNumber,
      seat: seat,
      flightNumber: flightNumber,
      class:`class`
    )
  }
}

