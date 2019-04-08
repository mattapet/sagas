import Basic
import Dispatch
import Foundation
import CoreSaga
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

final class CustomEventStore: EventStore {
  let filename: String
  var _storage: [String:[Event]] = [:]
  
  init(filename: String) {
    self.filename = filename
    do {
      self._storage =
        try utils.decoder.decode(
          [String:[Event]].self,
          from: try Data(contentsOf:
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
              .appendingPathComponent(filename)))
    } catch {
      self._storage = [:]
    }
  }

  func saveToFile() {
    try! utils.encoder.encode(_storage).write(to:
      URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        .appendingPathComponent(filename))
  }
  
  func load(
    for saga: Saga,
    with completion: (Result<[Event], Error>) -> Void
  ) {
    completion(Result {
      saveToFile()
      return _storage[saga.sagaId] ?? []
    })
  }
  
  func store(
    _ events: [Event],
    for saga: Saga, 
    with completion: (Result<(), Error>) -> Void
  ) {
    completion(Result {
      _storage[saga.sagaId, default: []].append(contentsOf: events)
    })
  }
}

let group = DispatchGroup()
let eventHandler = EventHandler()
let commandHandler = CommandHandler()
let store = CustomEventStore(filename: "storage.json")
let repository = Repository(store: store, eventHandler: eventHandler, commandHandler: commandHandler)
let coordinator = Service(repository: repository)

let tripData = try utils.encoder.encode(trip)
let tripData1 = try utils.encoder.encode(trip1)

try store._storage.keys.forEach { sagaId in
  let saga = Saga(sagaId: sagaId, definition: tripSaga)
  group.enter()
  try coordinator.restart(saga: saga) {
    print("DONE Restarting \(sagaId)")
    group.leave()
  }
}

//group.enter()
//coordinator.register(definition: tripSaga, using: tripData) {
//  print("DONE")
//  group.leave()
//}
//group.enter()
//try coordinator.start(definition: tripSaga.name, using: tripData1) {
//  print("DONE")
//  group.leave()
//}

group.wait()
dumpStorage()
store.saveToFile()
