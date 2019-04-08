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
  
  private var retries: [String:Int] = [:]
  private var sagas: [String:Saga]
  private var completions: [String:Disposable]
  
  private let repository: Repository<Store>
  
  public init(repository: Repository<Store>) {
    self.lock = Lock()
    self.queue = DispatchQueue(label: "service-queue")
    self.sagas = [:]
    self.completions = [:]
    self.repository = repository
  }
}

extension Service {
  public func register(
    definition: SagaDefinition,
    using payload: Data? = nil,
    with completion: @escaping () -> Void
  ) {
    let saga = Saga(definition: definition, payload: payload)
    lock.withLock {
      sagas[saga.sagaId] = saga
      completions[saga.sagaId] = ActionDisposable(action: completion)
    }
    queue.async { [weak self] in
      try! self?.startSaga(saga.sagaId, payload: payload)
    }
  }
  
  public func register(
    saga: Saga,
    with completion: @escaping () -> Void
  ) {
    lock.withLock {
      sagas[saga.sagaId] = saga
      completions[saga.sagaId] = ActionDisposable(action: completion)
    }
    queue.async { [weak self] in
      try! self?.startSaga(saga.sagaId, payload: saga.payload)
    }
  }
  
  public func restart(
    saga: Saga,
    with completion: @escaping () -> Void
  ) throws {
    try lock.withLock {
      let saga = try repository.query(saga)
      sagas[saga.sagaId] = saga
      completions[saga.sagaId] = ActionDisposable(action: completion)
      queue.async { [weak self] in
        switch saga.state {
        case .fresh: try! self?.startSaga(saga.sagaId, payload: saga.payload)
        case .started: try! self?.startSaga(saga.sagaId)
        case .aborted: try! self?.abortSaga(saga.sagaId)
        case .completed: try! self?.completeSaga(saga.sagaId)
        }
      }
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
  private func startSaga(_ sagaId: String, payload: Data? = nil) throws {
    try lock.withLock {
      let saga = try sagaFor(
        sagaId,
        executing: .startSaga(sagaId: sagaId, payload: payload)
      )
      try saga.stepsToStart()
        .forEach { step in
          queue.async { [weak self] in
            try! self?.startTransaction(
              sagaId: sagaId,
              stepKey: step.key,
              payload: saga.payload
            )
          }
        }
    }
  }
  
  private func abortSaga(_ sagaId: String) throws {
    try lock.withLock { () -> Void in
      let saga = try sagaFor(sagaId, executing: .abortSaga(sagaId: sagaId))
      let toCompensate = try saga.stepsToCompensate()
      guard !toCompensate.isEmpty else {
        return queue.async { [weak self] in try! self?.completeSaga(sagaId) }
      }
      toCompensate.forEach { step in
        queue.async { [weak self] in
          try! self?.startCompensation(
            sagaId: sagaId,
            stepKey: step.key,
            payload: saga.payload
          )
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

      let step = try saga.stepFor(stepKey)
      DispatchQueue.global().async { [weak self] in
        do {
          let result = try await(payload, step.transaction.execute)
          self?.queue.async { [weak self] in
            try! self?.completeTransaction(
              sagaId: sagaId,
              stepKey: stepKey,
              payload: result
            )
          }
          
        } catch let error {
          print("Transaction failed: \(error)")
          self?.queue.async { [weak self] in
            try! self?.abortTransaction(sagaId: sagaId, stepKey: stepKey)
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
        try! self?.abortSaga(sagaId)
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
          try! self?.completeSaga(sagaId)
        }
      }
      
      let step = try saga.stepFor(stepKey)
      let successors = try step.successors
        .map { try saga.stepFor($0) }
        .filter { $0.isFresh }
        .filter {
          try $0.dependencies
            .map { try saga.stepFor($0) }
            .allSatisfy { $0.isCompleted }
        }

      successors.forEach { successor in
        queue.async { [weak self] in
          try! self?.startTransaction(
            sagaId: sagaId,
            stepKey: successor.key,
            payload: saga.payload ?? step.data
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
      
      let step = try saga.stepFor(stepKey)
      DispatchQueue.global().async { [weak self] in
        do {
          let result = try await(payload, step.compensation.execute)
          self?.queue.async { [weak self] in
            try! self?.completeCompensation(
              sagaId: sagaId,
              stepKey: stepKey,
              payload: result
            )
          }
          
        } catch let error {
          print("\(error)")
          self?.queue.async { [weak self] in
            try! self?.retryCompensation(
              sagaId: sagaId,
              stepKey: stepKey,
              payload: saga.payload ?? payload
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
      
      let step = try saga.stepFor(stepKey)
      let key = "\(sagaId):\(stepKey)"
      guard retries[key, default: 0] < 5 else { fatalError() }
      retries[key, default: 0] += 1
      DispatchQueue.global().async { [weak self] in
        do {
          let result = try await(payload, step.compensation.execute)
          self?.queue.async { [weak self] in
            try! self?.completeCompensation(
              sagaId: sagaId,
              stepKey: stepKey,
              payload: result
            )
          }
          
        } catch let error {
          print("\(error)")
          self?.queue.async { [weak self] in
            try! self?.retryCompensation(
              sagaId: sagaId,
              stepKey: stepKey,
              payload: saga.payload ?? payload
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
          try! self?.completeSaga(sagaId)
        }
      }
      
      let step = try saga.stepFor(stepKey)
      let successors = try step.dependencies
        .map { try saga.stepFor($0) }
        .filter { $0.isFresh }
        .filter {
          try $0.successors
            .map { try saga.stepFor($0) }
            .allSatisfy { !$0.isStarted || !$0.isCompleted }
      }
      
      successors.forEach { successor in
        queue.async { [weak self] in
          try! self?.startCompensation(
            sagaId: sagaId,
            stepKey: successor.key,
            payload: saga.payload ?? step.data
          )
        }
      }
    }
  }
}
