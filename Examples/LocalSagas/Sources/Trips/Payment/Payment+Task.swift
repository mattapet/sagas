//
//  Payment+Task.swift
//  Run
//
//  Created by Peter Matta on 3/15/19.
//

import Basic
import CoreSaga
import Foundation

public protocol PaymentExecutable {
  func credit(_ playment: Payment, forTripId: Int) throws
  
  func debit(_ playment: Payment, forTripId: Int) throws
}

extension PaymentExecutable {
  public func credit(_ payment: Payment, forTripId tripId: Int) throws {
    // Make sure we credit only once per trip
    if let _ = try await(tripId, Credit.load) { return }
    // If there has been no credit yet, create one
    let credit =
      Credit(tripId: tripId, amount: payment.amount, currency: payment.currency)
    try await(credit.save)
    // add credit to account
    print("[CREDIT] \(tripId):\(payment)")
  }
  
  public func debit(_ payment: Payment, forTripId tripId: Int) throws {
    // Make sure we debit only once per trip
    if let _ = try await(tripId, Debit.load) { return }
    // If there has been no debit yet, create one
    let debit =
      Debit(tripId: tripId, amount: payment.amount, currency: payment.currency)
    try await(debit.save)
    // add debit to account
    print("[DEBIT] \(tripId):\(payment)")
  }
}

public struct PaymentTask: Job {
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

public struct PaymentCancellationTask: Job {
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

