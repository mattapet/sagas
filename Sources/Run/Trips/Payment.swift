//
//  Payment.swift
//  Run
//
//  Created by Peter Matta on 3/14/19.
//

import Sagas
import Foundation

public enum Currency: String, Codable {
  case USD, EUR, GBP
  
  public static var random: Currency {
    return [.USD, .EUR, .GBP].randomElement
  }
}

public enum PaymentType: String, Codable {
  case credit, debit
}

public struct Payment: Codable {
  public let accountId: Int
  public let amount: Double
  public let currency: Currency
  public let type: PaymentType
}

public protocol PaymentExecutable {
  func credit(_ playment: Payment, forTripId: Int) throws
  
  func debit(_ playment: Payment, forTripId: Int) throws
}

extension PaymentExecutable {
  public func credit(_ payment: Payment, forTripId tripId: Int) throws {
    // add credit to account
    print("[CREDIT] \(tripId):\(payment)")
  }
  
  public func debit(_ payment: Payment, forTripId tripId: Int) throws {
    // add debit to account
    print("[DEBIT] \(tripId):\(payment)")
  }
}

public struct PaymentTask: Sagas.Task {
  public init() { }
  
  public func execute(
    using payload: Data?,
    with completion: (Result<Data?, Error>) -> Void
  ) {
    completion(Result { () -> Data? in
      guard let payload = payload else { throw TripError.invalidHotelPayload }
      let trip = try utils.decoder.decode(Trip.self, from: payload)
      switch trip.payment.type {
      case .credit: try credit(trip.payment, forTripId: trip.tripId)
      case .debit: try debit(trip.payment, forTripId: trip.tripId)
      }
      return try utils.encoder.encode(trip)
    })
  }
}

public struct PaymentCancellationTask: Sagas.Task {
  public init() { }

  public func execute(
    using payload: Data?,
    with completion: (Result<Data?, Error>) -> Void
  ) {
    completion(Result { () -> Data? in
      guard let payload = payload else { throw TripError.invalidHotelPayload }
      let trip = try utils.decoder.decode(Trip.self, from: payload)
      switch trip.payment.type {
      case .credit: try debit(trip.payment, forTripId: trip.tripId)
      case .debit: try credit(trip.payment, forTripId: trip.tripId)
      }
      return try utils.encoder.encode(trip)
    })
  }
}

extension PaymentTask: PaymentExecutable {}
extension PaymentCancellationTask: PaymentExecutable {}
