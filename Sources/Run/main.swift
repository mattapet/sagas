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
    using payload: Data,
    with completion: (Result<Data, Error>) -> Void
  ) {
    print("Executing \(String(data: payload, encoding: .utf8) ?? "unknown")")
    if Int.random(in: 0..<10) < 5 {
      completion(.success(Data()))
    } else {
      completion(.failure(TaskError.randomTest))
    }
  }
}

struct CompensatingTask: Sagas.Task {
  func execute(
    using payload: Data,
    with completion: (Result<Data, Error>) -> Void
  ) {
    print("Compensating \(String(data: payload, encoding: .utf8) ?? "unknown")")
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
executor.register(saga)
