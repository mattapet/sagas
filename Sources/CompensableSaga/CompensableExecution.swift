//
//  CompensableExecution.swift
//  CompensableSaga
//
//  Created by Peter Matta on 4/14/19.
//

import Basic
import CoreSaga
import Foundation

public final class CompensableExecution<
  S: CompensableSaga,
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

extension CompensableExecution {
  internal func execute(_ command: Command) throws -> SagaType {
    return try repository.execute(command, on: try repository.query(saga))
  }
}

extension CompensableExecution: Execution {
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
        case .aborted: fatalError("Unreachable")
        }
      } catch let error { self?.fail(error: error) }
    }
  }
  
  public func start() throws {
    let saga = try execute(.startSaga(sagaId: sagaId))
    let stepsToStart = try saga.stepsToStart()
    guard !saga.isCompleted else { return try complete() }
    
    try stepsToStart.forEach { stepToStart in
      try start(step: stepToStart.key)
    }
  }
  
  public func abort() throws {
    let saga = try execute(.abortSaga(sagaId: sagaId))
    let stepsToCompensate = try saga.stepsToCompensate()
    let stepsToComplete = try saga.stepsToStart()
    guard !stepsToCompensate.isEmpty || !stepsToComplete.isEmpty else {
      return try complete()
    }
    
    try stepsToComplete.forEach { stepToComplete in
      try retry(step: stepToComplete.key)
    }
    try stepsToCompensate.forEach { stepToCompensate in
      try compensate(step: stepToCompensate.key)
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

extension CompensableExecution {
  private func start(step stepKey: String) throws {
    let saga = try execute(.startTransaction(sagaId: sagaId, stepKey: stepKey))
    let step = try saga.stepFor(stepKey)
    print("Starting \(step)")
    executeJob(step.transaction, saga.payload)
      .map { [weak self] result in
        try self?.complete(step: stepKey, payload: result)
      }
      .mapError { [weak self] _ in
        try self?.abort(step: stepKey)
      }
      .whenFail { [weak self] error in
        self?.fail(error: error)
      }
  }
  
  private func abort(step stepKey: String) throws {
    let _ = try execute(.abortTransaction(sagaId: sagaId, stepKey: stepKey))
    try abort()
  }
  
  private func retry(step stepKey: String) throws {
    let saga = try execute(.retryTransaction(sagaId: sagaId, stepKey: stepKey))
    let step = try saga.stepFor(stepKey)
    executeJob(step.transaction, saga.payload)
      .map { [weak self] result in
        try self?.complete(step: stepKey, payload: result)
      }
      .mapError { [weak self] _ in
        try self?.retry(step: stepKey)
      }
      .whenFail { [weak self] error in
        self?.fail(error: error)
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
  
  private func compensate(step stepKey: String) throws {
    let saga = try execute(.startCompensation(sagaId: sagaId, stepKey: stepKey))
    let step = try saga.stepFor(stepKey)
    executeJob(step.compensation, saga.payload)
      .map { [weak self] result in
        try self?.completeCompensation(step: stepKey, payload: result)
      }
      .mapError { [weak self] _ in
        try self?.retryCompensation(step: stepKey)
      }
      .whenFail { [weak self] error in
        self?.fail(error: error)
      }
  }
  
  private func retryCompensation(step stepKey: String) throws {
    let saga = try execute(.retryCompensation(sagaId: sagaId, stepKey: stepKey))
    let step = try saga.stepFor(stepKey)
    executeJob(step.compensation, saga.payload)
      .map { [weak self] result in
        try self?.completeCompensation(step: stepKey, payload: result)
      }
      .mapError { [weak self] _ in
        try self?.retryCompensation(step: stepKey)
      }
      .whenFail { [weak self] error in
        self?.fail(error: error)
      }
  }
  
  private func completeCompensation(
    step stepKey: String,
    payload: Data?
  ) throws {
    let _ = try execute(.completeCompensation(
      sagaId: sagaId,
      stepKey: stepKey,
      payload: payload))
    try abort()
  }
}
