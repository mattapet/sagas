//
//  RetryableExecution.swift
//  RetryableSaga
//
//  Created by Peter Matta on 4/14/19.
//

import Basic
import CoreSaga
import Foundation

public final class RetryableExecution<
  S: RetryableSaga,
  E: Executor,
  R: Repository
>
  where S == R.SagaType
{
  public typealias SagaType = S
  public typealias ExecutorType = E
  public typealias RepositoryType = R
  
  public let saga: SagaType
  public let executor: ExecutorType
  internal let queue: DispatchQueue
  internal let repository: RepositoryType
  internal var completion: ((Result<Data?, Error>) -> Void)?
  
  private let executeJob: (Job, Data?) -> Future<Data?>
  
  public init(
    saga: SagaType,
    executor: ExecutorType,
    repository: RepositoryType
  ) {
    self.saga = saga
    self.executor = executor
    self.queue = DispatchQueue(label: "execution-queue-\(saga.sagaId)")
    self.repository = repository
    self.completion = nil
    self.executeJob = promisify(on: queue, executor.execute)
  }
  
  public init(
    saga: SagaType,
    executor: ExecutorType,
    repository: RepositoryType,
    queue: DispatchQueue
  ) {
    self.saga = saga
    self.executor = executor
    self.queue = queue
    self.repository = repository
    self.completion = nil
    self.executeJob = promisify(on: queue, executor.execute)
  }
}

extension RetryableExecution {
  internal func execute(_ command: Command) throws -> SagaType {
    return try repository.execute(command, on: try repository.query(saga))
  }
}

extension RetryableExecution: Execution {
  public func launch(
    with completion: @escaping (Result<Data?, Error>) -> Void
  ) {
    self.completion = completion
    queue.async { [weak self] in
      do {
        guard let saga = self?.saga else { return }
        switch saga.state {
        case .fresh: try self?.start()
        case .started: try self?.start()
        case .completed: try self?.complete()
        }
      } catch let error { self?.fail(error: error) }
    }
  }
  
  public func start() throws {
    let saga = try execute(.startSaga(sagaId: sagaId))
    let stepsToStart = try saga.stepsToStart()
    guard !stepsToStart.isEmpty else { return try complete() }
    
    try stepsToStart.forEach { stepToStart in
      try start(step: stepToStart.key)
        .whenFail { error in self.fail(error: error) }
    }
  }
  
  public func complete() throws {
    let _ = try execute(.completeSaga(sagaId: sagaId))
    completion?(.success(nil))
    completion = nil
    print("Done")
  }
  
  public func fail(error: Error) {
    completion?(.failure(error))
    completion = nil
  }
}

extension RetryableExecution {
  private func start(step stepKey: String) throws -> Future<Void> {
    let saga = try execute(.startTransaction(sagaId: sagaId, stepKey: stepKey))
    let step = try saga.stepFor(stepKey)
    return executeJob(step.transaction, saga.payload)
      .map { result in
        try self.complete(step: stepKey, payload: result)
      }
      .flatMapErrorThrowing { _ in
        try self.retry(step: stepKey)
      }
  }
  
  private func retry(step stepKey: String) throws -> Future<Void> {
    let saga = try execute(.retryTransaction(sagaId: sagaId, stepKey: stepKey))
    let step = try saga.stepFor(stepKey)
    return executeJob(step.transaction, saga.payload)
      .map { result in
        try self.complete(step: stepKey, payload: result)
      }
      .flatMapErrorThrowing { _ in
        try self.retry(step: stepKey)
      }
  }
  
  private func complete(step stepKey: String, payload: Data?) throws {
    let saga = try execute(.completeTransaction(
      sagaId: sagaId,
      stepKey: stepKey,
      payload: payload))
    switch saga.state {
    case .started: try start()
    default: fatalError("Unreachable")
    }
  }
}
