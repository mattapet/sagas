//
//  Execution.swift
//  CoreSaga
//
//  Created by Peter Matta on 4/11/19.
//

import Basic
import Dispatch
import Foundation

public final class Execution<SagaType, RepositoryType: Repository>
  where RepositoryType.SagaType == SagaType
{
  internal let saga: SagaType
  internal let queue: DispatchQueue
  internal let repository: RepositoryType
  internal var completion: ((Result<Data?, Error>) -> Void)?
  
  public init(saga: SagaType, repository: RepositoryType) {
    self.saga = saga
    self.queue = DispatchQueue(label: "execution-queue-\(saga.sagaId)")
    self.repository = repository
    self.completion = nil
  }
  
  public init(
    saga: SagaType,
    repository: RepositoryType,
    queue: DispatchQueue
  ) {
    self.saga = saga
    self.queue = queue
    self.repository = repository
    self.completion = nil
  }
}

extension Execution {
  public var sagaId: String {
    return saga.sagaId
  }
}

extension Execution {
  internal func execute(_ command: Command) throws -> SagaType {
    return try repository.execute(command, on: try repository.query(saga))
  }
}

// MARK: - AnySaga - public

extension Execution {
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
}

// MARK: - AnySaga - private

extension Execution {
  private func start() throws {
    let saga = try execute(.startSaga(sagaId: sagaId))
    let stepsToStart = try saga.stepsToStart()
    guard !stepsToStart.isEmpty else { return try complete() }
    
    try stepsToStart.forEach { stepToStart in
      try start(step: stepToStart.key)
    }
  }
  
  private func complete() throws {
    let _ = try execute(.completeSaga(sagaId: sagaId))
    completion?(.success(nil))
    completion = nil
    print("Done")
  }
  
  private func fail(error: Error) {
    completion?(.failure(error))
    completion = nil
  }
}

// MARK: - AnySaga - private Step transitions

extension Execution {
  private func start(step stepKey: String) throws {
    let saga = try execute(.startTransaction(sagaId: sagaId, stepKey: stepKey))
    let step = try saga.stepFor(stepKey)
    DispatchQueue.global().async { [weak self] in
      let result = Result { try await(saga.payload, step.transaction.execute) }
      self?.queue.async { [weak self] in
        do {
          switch result {
          case .success(let result):
            try self?.complete(step: stepKey, payload: result)
          case .failure:
            try self?.retry(step: stepKey)
          }
        } catch let error { self?.fail(error: error) }
      }
    }
  }
  
  private func retry(step stepKey: String) throws {
    let saga = try execute(.retryTransaction(sagaId: sagaId, stepKey: stepKey))
    let step = try saga.stepFor(stepKey)
    DispatchQueue.global().async { [weak self] in
      let result = Result { try await(saga.payload, step.transaction.execute) }
      self?.queue.async { [weak self] in
        do {
          switch result {
          case .success(let result):
            try self?.complete(step: stepKey, payload: result)
          case .failure:
            try self?.retry(step: stepKey)
          }
        } catch let error { self?.fail(error: error) }
      }
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

// MARK: - CompensableSaga

extension Execution where SagaType: CompensableSaga {
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
        case .aborted: try self?.abort()
        case .completed: try self?.complete()
        }
      } catch let error { self?.fail(error: error) }
    }
  }
}

// MARK: - CompensableSaga - private

extension Execution where SagaType: CompensableSaga {
  private func start() throws {
    let saga = try execute(.startSaga(sagaId: sagaId))
    let stepsToStart = try saga.stepsToStart()
    guard !stepsToStart.isEmpty else { return try complete() }
    
    try stepsToStart.forEach { stepToStart in
      try start(step: stepToStart.key)
    }
  }
  
  private func abort() throws {
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
}

// MARK: - CompensableSaga - private Step transitions

extension Execution where SagaType: CompensableSaga {
  private func start(step stepKey: String) throws {
    let saga = try execute(.startTransaction(sagaId: sagaId, stepKey: stepKey))
    let step = try saga.stepFor(stepKey)
    print("Starting \(step)")
    DispatchQueue.global().async { [weak self] in
      let result = Result { try await(saga.payload, step.transaction.execute) }
      self?.queue.async { [weak self] in
        do {
          switch result {
          case .success(let result):
            try self?.complete(step: stepKey, payload: result)
          case .failure:
            try self?.abort(step: stepKey)
          }
        } catch let error { self?.fail(error: error) }
      }
    }
  }
  
  private func abort(step stepKey: String) throws {
    let _ = try execute(.abortTransaction(sagaId: sagaId, stepKey: stepKey))
    try abort()
  }
  
  private func retry(step stepKey: String) throws {
    let saga = try execute(.retryTransaction(sagaId: sagaId, stepKey: stepKey))
    let step = try saga.stepFor(stepKey)
    DispatchQueue.global().async { [weak self] in
      let result = Result { try await(saga.payload, step.transaction.execute) }
      self?.queue.async { [weak self] in
        do {
          switch result {
          case .success(let result):
            try self?.complete(step: stepKey, payload: result)
          case .failure:
            try self?.retry(step: stepKey)
          }
        } catch let error { self?.fail(error: error) }
      }
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
    DispatchQueue.global().async { [weak self] in
      let result = Result { try await(saga.payload, step.compensation.execute) }
      self?.queue.async { [weak self] in
        do {
          switch result {
          case .success(let result):
            try self?.completeCompensation(step: stepKey, payload: result)
          case .failure:
            try self?.retryCompensation(step: stepKey)
          }
        } catch let error { self?.fail(error: error) }
      }
    }
  }
  
  private func retryCompensation(step stepKey: String) throws {
    let saga = try execute(.retryCompensation(sagaId: sagaId, stepKey: stepKey))
    let step = try saga.stepFor(stepKey)
    DispatchQueue.global().async { [weak self] in
      let result = Result { try await(saga.payload, step.compensation.execute) }
      self?.queue.async { [weak self] in
        do {
          switch result {
          case .success(let result):
            try self?.completeCompensation(step: stepKey, payload: result)
          case .failure:
            try self?.retryCompensation(step: stepKey)
          }
        } catch let error { self?.fail(error: error) }
      }
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
