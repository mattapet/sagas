import Basic
import Dispatch
import Foundation
import Sagas
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

//let tripSaga = SagaDefinition {
//  ("car", carTask.execute, carCancelTask.execute)
//    |> ("hotel", hotelTask.execute, hotelCancelTask.execute)
//    |> ("plane", planeTask.execute, planeCancelTask.execute)
//    |> ("payment", paymentTask.execute, paymentCancelTask.execute)
//}

let tripSaga = SagaDefinition(
  name: "trip_saga",
  requests: [
    .request(
      key: ".car",
      compensation: ".carCancel",
      task: CarReservationTask()),
    .request(
      key: ".hotel",
      compensation: ".hotelCancel",
      task: HotelReservationTask()),
    .request(
      key: ".plane",
      compensation: ".planeCancel",
      task: PlaneReservationTask()),
    .request(
      key: ".payment",
      dependencies: [".car", ".hotel", ".plane"],
      compensation: ".paymentDecline",
      task: PaymentTask()),
  ],
  compensations: [
    .compensation(
      key: ".carCancel",
      task: CarReservationCancellationTask()),
    .compensation(
      key: ".hotelCancel",
      task: HotelReservationCancellationTask()),
    .compensation(
      key: ".planeCancel",
      task: PlaneReservationCancellationTask()),
    .compensation(
      key: ".paymentDecline",
      task: PaymentCancellationTask()),
  ]
)

struct CustomLogger: Logger {
  public func log(_ message: Message) {
    print("[LOGGER]: \(message.sagaId):\(message.type):\(message.stepKey)")
  }
  
  public func logRegisterd(_ definition: SagaDefinition) {
    print("[LOGGER]: SAGA DEF REGISTERED \(definition.name)")
  }
  
  public func logStart(_ saga: Saga) {
    print("[LOGGER]: SAGA START \(saga.name):\(saga.sagaId)")
  }
  
  public func logAbort(_ saga: Saga) {
    print("[LOGGER]: SAGA ABORT \(saga.name):\(saga.sagaId)")
  }
  
  public func logEnd(_ saga: Saga) {
    print("[LOGGER]: SAGA END \(saga.name):\(saga.sagaId)")
  }
}
let group = DispatchGroup()
let coordinator = Coordinator(logger: CustomLogger(), executor: BasicExecutor())
let tripData = try utils.encoder.encode(trip)
let tripData1 = try utils.encoder.encode(trip1)

group.enter()
try coordinator.register(tripSaga, using: tripData) {
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
