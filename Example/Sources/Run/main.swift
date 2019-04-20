import Basic
import Dispatch
import Foundation
import LocalSagas
import Trips

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

let carTask = CarReservationTask()
let carCancelTask = CarReservationCancellationTask()
let hotelTask = HotelReservationTask()
let hotelCancelTask = HotelReservationCancellationTask()
let planeTask = PlaneReservationTask()
let planeCancelTask = PlaneReservationCancellationTask()
let paymentTask = PaymentTask()
let paymentCancelTask = PaymentCancellationTask()

let tripSaga = SagaDefinition {
  ("car", carTask.execute, carCancelTask.execute)
    |> ("hotel", hotelTask.execute, hotelCancelTask.execute)
    |> ("plane", planeTask.execute, planeCancelTask.execute)
    |> ("payment", paymentTask.execute, paymentCancelTask.execute)
}

//let tripSaga = SagaDefinition(
//  name: "trip_saga",
//  requests: [
//    .request(
//      key: ".car",
//      compensation: ".carCancel",
//      task: CarReservationTask()),
//    .request(
//      key: ".hotel",
//      compensation: ".hotelCancel",
//      task: HotelReservationTask()),
//    .request(
//      key: ".plane",
//      compensation: ".planeCancel",
//      task: PlaneReservationTask()),
//    .request(
//      key: ".payment",
//      dependencies: [".car", ".hotel", ".plane"],
//      compensation: ".paymentDecline",
//      task: PaymentTask()),
//  ],
//  compensations: [
//    .compensation(
//      key: ".carCancel",
//      task: CarReservationCancellationTask()),
//    .compensation(
//      key: ".hotelCancel",
//      task: HotelReservationCancellationTask()),
//    .compensation(
//      key: ".planeCancel",
//      task: PlaneReservationCancellationTask()),
//    .compensation(
//      key: ".paymentDecline",
//      task: PaymentCancellationTask()),
//  ]
//)

let group = DispatchGroup()

let tripData = try utils.encoder.encode(trip)
let tripData1 = try utils.encoder.encode(trip1)

//try store._storage.keys.forEach { sagaId in
//  let saga = SimpleSaga(sagaId: sagaId, definition: tripSaga)
//  group.enter()
//  coordinator.register(saga: saga) { _ in
//    print("DONE Restarting \(sagaId)")
//    group.leave()
//  }
//}

group.enter()
register(definition: tripSaga, using: tripData) { result in
  print("Result: \(result)")
  print("DONE")
  group.leave()
}
//group.enter()
//try coordinator.start(definition: tripSaga.name, using: tripData1) {
//  print("DONE")
//  group.leave()
//}

group.wait()
dumpStorage()
//store.saveToFile()
