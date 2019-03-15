import Foundation
import Sagas

public enum ActionType: String {
  case car, hotel, payment
  case carDecline, hotelDecline, paymentDecline
}

enum TaskError: Error {
  case randomTest
}

struct Task: Sagas.Task {
  func execute(
    using payload: Data?,
    with completion: (Result<Data?, Error>) -> Void
  ) {
    usleep(1000000)
    print("Executing")
    if Int.random(in: 0..<10) < 7 {
      completion(.success(Data()))
    } else {
      completion(.failure(TaskError.randomTest))
    }
  }
}

struct CompensatingTask: Sagas.Task {
  func execute(
    using payload: Data?,
    with completion: (Result<Data?, Error>) -> Void
  ) {
    usleep(1000000)
    print("Compensating")
    if Int.random(in: 0..<10) < 8 {
      completion(.success(Data()))
    } else {
      completion(.failure(TaskError.randomTest))
    }
  }
}

let saga = SagaDefinition<ActionType>(
  name: "Test Saga",
  requests: [
    .request(key: .car, compensation: .carDecline, task: Task.self),
    .request(key: .hotel, compensation: .hotelDecline, task: Task.self),
    .request(
      key: .payment,
      dependencies: [.car, .hotel],
      compensation: .paymentDecline,
      task: Task.self
    ),
  ],
  compensations: [
    .compensation(key: .carDecline, task: CompensatingTask.self),
    .compensation(key: .hotelDecline, task: CompensatingTask.self),
    .compensation(key: .paymentDecline, task: CompensatingTask.self)
  ]
)

struct CustomLogger: Logger { }

let executor = Executor<ActionType>(logger: CustomLogger())
executor.register(saga) {
  print("DONE 1")
}

executor.register(saga) {
  print("DONE 2")
}

executor.register(saga) {
  print("DONE 3")
}


usleep(100_000_000)
