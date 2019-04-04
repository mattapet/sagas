//
//  Service.swift
//  CoreSaga
//
//  Created by Peter Matta on 4/4/19.
//

import Basic
import Dispatch
import Foundation

public enum ServiceError: Error {
  case invalidSagaId
  case invalidKeyId
}

public final class Service<Store: EventStore> {
  private let lock: Lock
  private let queue: DispatchQueue
  private let worker: DispatchQueue
  
  private var sagas: [String:Saga]
  private var completions: [String:Disposable]
  
  private let repository: Repository<Store>
  
  public init(repository: Repository<Store>) {
    self.lock = Lock()
    self.queue = DispatchQueue(label: "service-queue")
    self.worker = DispatchQueue(label: "worker-queue")
    self.sagas = [:]
    self.completions = [:]
    self.repository = repository
  }
}

extension Service {
  public func register(saga: Saga, with completion: Disposable) {
    lock.withLock {
      sagas[saga.sagaId] = saga
      completions[saga.sagaId] = completion
    }
    queue.async { [weak self] in
      try? self?.startSaga(saga.sagaId)
    }
  }
}

extension Service {
  private func sagaFor(
    _ sagaId: String,
    executing command: Command
  ) throws -> Saga {
    guard let saga = try sagas[sagaId]
      .map({ try repository.query($0) })
      .map({ try repository.execute(command, on: $0) })
    else { throw ServiceError.invalidKeyId }
    sagas[sagaId] = saga
    return saga
  }
}

extension Service {
  private func startSaga(_ sagaId: String) throws {
    try lock.withLock {
      let saga = try sagaFor(sagaId, executing: .startSaga(sagaId: sagaId))
      saga.steps.values
        .filter { $0.isInitial }
        .forEach { step in
          queue.async { [weak self] in
            try? self?.startTransaction(sagaId: sagaId, stepKey: step.key)
          }
        }
    }
  }
  
  private func abortSaga(_ sagaId: String) throws {
    try lock.withLock {
      let saga = try sagaFor(sagaId, executing: .abortSaga(sagaId: sagaId))
      saga.steps.values
        .filter { $0.isTerminal }
        .forEach { step in
          queue.async { [weak self] in
            try? self?.startTransaction(sagaId: sagaId, stepKey: step.key)
          }
        }
    }
  }
  
  private func completeSaga(_ sagaId: String) throws {
    try lock.withLock {
      let _ = try sagaFor(sagaId, executing: .completeSaga(sagaId: sagaId))
      completions.removeValue(forKey: sagaId).map({ completion in
        DispatchQueue.global().async {
          completion.dispose()
        }
      })
    }
  }
}

extension Service {
  private func startTransaction(
    sagaId: String,
    stepKey: String,
    payload: Data? = nil
  ) throws {
    try lock.withLock {
      let saga = try sagaFor(sagaId, executing: .startTransaction(
        sagaId: sagaId,
        stepKey: stepKey,
        payload: payload))

      let step = try saga.step(for: stepKey)
      worker.async { [weak self] in
        do {
          let result = try await(payload, step.transaction.execute)
          self?.queue.async { [weak self] in
            try? self?.completeTransaction(
              sagaId: sagaId,
              stepKey: stepKey,
              payload: result
            )
          }
          
        } catch let error {
          print("\(error)")
          self?.queue.async { [weak self] in
            try? self?.abortTransaction(sagaId: sagaId, stepKey: stepKey)
          }
        }
      }
    }
  }
  
  private func abortTransaction(
    sagaId: String,
    stepKey: String,
    payload: Data? = nil
  ) throws {
    try lock.withLock {
      let _ = try sagaFor(sagaId, executing: .abortTransaction(
        sagaId: sagaId,
        stepKey: stepKey,
        payload: payload))
      queue.async { [weak self] in
        try? self?.abortSaga(sagaId)
      }
    }
  }
  
  private func completeTransaction(
    sagaId: String,
    stepKey: String,
    payload: Data? = nil
  ) throws {
    try lock.withLock { () -> Void in
      let saga = try sagaFor(sagaId, executing: .completeTransaction(
        sagaId: sagaId,
        stepKey: stepKey,
        payload: payload))
      
      if saga.steps.values.allSatisfy({ $0.isCompleted }) {
        return queue.async { [weak self] in
          try? self?.completeSaga(sagaId)
        }
      }
      
      let step = try saga.step(for: stepKey)
      let successors = try step.successors
        .map { try saga.step(for: $0) }
        .filter { $0.isFresh }
        .filter {
          try $0.dependencies
            .map { try saga.step(for: $0) }
            .allSatisfy { $0.isCompleted }
        }

      successors.forEach { successor in
        queue.async { [weak self] in
          try? self?.startTransaction(
            sagaId: sagaId,
            stepKey: successor.key,
            payload: step.data
          )
        }
      }
    }
  }
}

extension Service {
  private func startCompensation(
    sagaId: String,
    stepKey: String,
    payload: Data? = nil
  ) throws {
    try lock.withLock {
      let saga = try sagaFor(sagaId, executing: .startCompensation(
        sagaId: sagaId,
        stepKey: stepKey,
        payload: payload))
      
      let step = try saga.step(for: stepKey)
      worker.async { [weak self] in
        do {
          let result = try await(payload, step.transaction.execute)
          self?.queue.async { [weak self] in
            try? self?.completeCompensation(
              sagaId: sagaId,
              stepKey: stepKey,
              payload: result
            )
          }
          
        } catch let error {
          print("\(error)")
          self?.queue.async { [weak self] in
            try? self?.retryCompensation(
              sagaId: sagaId,
              stepKey: stepKey,
              payload: payload
            )
          }
        }
      }
    }
  }
  
  private func retryCompensation(
    sagaId: String,
    stepKey: String,
    payload: Data? = nil
  ) throws {
    try lock.withLock {
      let saga = try sagaFor(sagaId, executing: .retryCompensation(
        sagaId: sagaId,
        stepKey: stepKey))
      
      let step = try saga.step(for: stepKey)
      worker.async { [weak self] in
        do {
          let result = try await(payload, step.transaction.execute)
          self?.queue.async { [weak self] in
            try? self?.completeTransaction(
              sagaId: sagaId,
              stepKey: stepKey,
              payload: result
            )
          }
          
        } catch let error {
          print("\(error)")
          self?.queue.async { [weak self] in
            try? self?.retryCompensation(
              sagaId: sagaId,
              stepKey: stepKey,
              payload: payload
            )
          }
        }
      }
    }
  }
  
  private func completeCompensation(
    sagaId: String,
    stepKey: String,
    payload: Data? = nil
  ) throws {
    try lock.withLock { () -> Void in
      let saga = try sagaFor(sagaId, executing: .completeCompensation(
        sagaId: sagaId,
        stepKey: stepKey,
        payload: payload))
      
      if saga.steps.values.allSatisfy({ !$0.isStarted || !$0.isCompleted }) {
        return queue.async { [weak self] in
          try? self?.completeSaga(sagaId)
        }
      }
      
      let step = try saga.step(for: stepKey)
      let successors = try step.dependencies
        .map { try saga.step(for: $0) }
        .filter { $0.isFresh }
        .filter {
          try $0.successors
            .map { try saga.step(for: $0) }
            .allSatisfy { !$0.isStarted || !$0.isCompleted }
      }
      
      successors.forEach { successor in
        queue.async { [weak self] in
          try? self?.startCompensation(
            sagaId: sagaId,
            stepKey: successor.key,
            payload: step.data
          )
        }
      }
    }
  }
}
