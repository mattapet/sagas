import Dispatch
import Foundation
import Sagas

public enum TripKeys: String {
  case car, hotel, plane, payment
  case carCancel, hotelCancel, planeCancel, paymentDecline
}


let trip = Trip(
  payment: .paymen(accountId: 12345),
  car: .car(carId: 44),
  hotel: .hotel(hotelId: 194),
  plane: .plane(ticketNumber: "234 gsfdgdfsg")
)
let trip1 = Trip(
  payment: .paymen(accountId: 87654),
  car: .car(carId: 55),
  hotel: .hotel(hotelId: 43214),
  plane: .plane(ticketNumber: "443214 hgfdefgt")
)

let tripSaga = SagaDefinition(
  name: "trip_saga",
  requests: [
    .request(
      key: ".car",
      compensation: ".carCancel",
      task: CarReservationTask.self),
    .request(
      key: ".hotel",
      compensation: ".hotelCancel",
      task: HotelReservationTask.self),
    .request(
      key: ".plane",
      compensation: ".planeCancel",
      task: PlaneReservationTask.self),
    .request(
      key: ".payment",
      dependencies: [".car", ".hotel", ".plane"],
      compensation: ".paymentDecline",
      task: PaymentTask.self),
  ],
  compensations: [
    .compensation(key: ".carCancel", task:CarReservationCancellationTask.self),
    .compensation(key: ".hotelCancel", task: HotelReservationCancellationTask.self),
    .compensation(key: ".planeCancel", task: PlaneReservationCancellationTask.self),
    .compensation(key: ".paymentDecline", task: PaymentCancellationTask.self),
  ]
)

struct CustomLogger: Logger { }
let group = DispatchGroup()
let coordinator = Coordinator(logger: CustomLogger())
let tripData = try utils.encoder.encode(trip)

group.enter()
try coordinator.register(tripSaga, using: tripData) {
  print("DONE")
  group.leave()
}
group.enter()
try coordinator.start(definition: tripSaga.name) {
  print("DONE")
  group.leave()
}

group.wait()
dumpStorage()
