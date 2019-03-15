import Foundation
import Sagas

public enum TripKeys: String, Codable {
  case car, hotel, plane, payment
  case carCancel, hotelCancel, planeCancel, paymentDecline
}

let trip = Trip(
  payment: .paymen(accountId: 12345),
  car: .car(carId: 44),
  hotel: .hotel(hotelId: 194),
  plane: .plane(ticketNumber: "234 gsfdgdfsg")
)

let tripSaga = SagaDefinition<TripKeys>(
  name: "trip_saga",
  requests: [
    .request(key: .car, compensation: .carCancel, task: CarReservation.self),
    .request(
      key: .car,
      compensation: .carCancel,
      task: CarReservation.self),
    .request(
      key: .hotel,
      compensation: .hotelCancel,
      task: HotelReservation.self),
    .request(
      key: .plane,
      compensation: .planeCancel,
      task: PlaneReservation.self),
    .request(
      key: .payment,
      dependencies: [.car, .hotel, .plane],
      compensation: .paymentDecline,
      task: PaymentTask.self),
  ],
  compensations: [
    .compensation(key: .carCancel, task:CarReservationCancellation.self),
    .compensation(key: .hotelCancel, task: HotelReservationCancellation.self),
    .compensation(key: .planeCancel, task: PlaneReservationCancellation.self),
    .compensation(key: .paymentDecline, task: PaymentCancellationTask.self),
  ]
)

struct CustomLogger: Logger { }
let executor = Executor<TripKeys>(logger: CustomLogger())
let tripData = try utils.encoder.encode(trip)
executor.register(tripSaga, using: tripData) {
  print("DONE")
  exit(0)
}

usleep(100_000_000)
