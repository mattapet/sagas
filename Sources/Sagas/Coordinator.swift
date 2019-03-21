//
//  Coordinator.swift
//  Sagas
//
//  Created by Peter Matta on 3/20/19.
//

import Basic
import Dispatch
import Foundation

fileprivate var _id: Int = 1

public enum CoordinatorError: Error {
  case sagaRedefinition(String)
  case missingDefinition(String)
}

public final class Coordinator {
  internal let produceMessage: DispatchQueue
  internal let consumeMessage: DispatchQueue
  internal let executor: Executor
  internal let logger: Logger
  
  private let lock: Lock
  private var definitions: [String:SagaDefinition]
  private var sagas: [String:Saga]
  private var completions: [String:Disposable]
  
  public init(logger: Logger) {
    self.produceMessage = DispatchQueue(label: "produce_message_queue")
    self.consumeMessage = DispatchQueue(label: "consume_message_queue")
    self.executor = Executor()
    self.lock = Lock()
    self.definitions = [:]
    self.sagas = [:]
    self.completions = [:]
    self.logger = logger
  }
}

extension Coordinator {
  public func register(_ definition: SagaDefinition) throws {
    try lock.withLock {
      if let _ = definitions.updateValue(definition, forKey: definition.name) {
        throw CoordinatorError.sagaRedefinition(definition.name)
      }
    }
  }
  
  public func register(
    _ definition: SagaDefinition,
    using payload: Data? = nil,
    with completion: @escaping () -> Void
  ) throws {
    try lock.withLock {
      defer { _id += 1 }
      if let _ = definitions.updateValue(definition, forKey: definition.name) {
        throw CoordinatorError.sagaRedefinition(definition.name)
      }
      let sagaId = "\(_id)"
      let saga = Saga(sagaId: sagaId, definition: definition, payload: payload)
      sagas[sagaId] = saga
      completions[sagaId] = ActionDisposable(action: completion)
      startSaga(sagaId)
    }
  }
  
  public func start(
    definition name: String,
    using payload: Data? = nil,
    with completion: @escaping () -> Void
  ) throws {
    try lock.withLock {
      defer { _id += 1 }
      guard let definition = definitions[name] else {
        throw CoordinatorError.missingDefinition(name)
      }
      let sagaId = "\(_id)"
      let saga = Saga(sagaId: sagaId, definition: definition, payload: payload)
      sagas[sagaId] = saga
      completions[sagaId] = ActionDisposable(action: completion)
      startSaga(sagaId)
    }
  }
  
  public func consume(_ message: Message) {
    consumeMessage.async { [weak self] in
      self?.lock.withLock { [weak self] in
        self?.sagas[message.sagaId]
          .flatMap({ $0.steps[message.stepKey] })
          .map({ self?.consume(message, $0) })
      }
    }
  }
  
  public func produce(_ message: Message) {
    produceMessage.async { [weak self] in
      self?.consume(message)
    }
  }
}

extension Coordinator {
  private func startSaga(_ sagaId: String) {
    guard let saga = sagas[sagaId] else { return }
    guard saga.state == .`init` else { return }
    let payload = saga.payload
    logger.logStart(saga)
    saga.state = .started
    saga.steps.values
      .filter { $0.dependencies.isEmpty }
      .map {
        .transactionStart(sagaId: sagaId, stepKey: $0.key, payload: payload)
      }
      .forEach(produce)
  }
  
  private func abortSaga(_ sagaId: String) {
    guard let saga = sagas[sagaId] else { return }
    let payload = saga.payload
    logger.logAbort(saga)
    saga.state = .aborted
    saga.steps.values
      .filter { $0.successors.isEmpty }
      .map {
        .compensationStart(sagaId: sagaId, stepKey: $0.key, payload: payload)
      }
      .forEach(produce)
  }
  
  private func completeTransaction(_ sagaId: String) {
    guard let saga = sagas[sagaId] else { return }
    guard saga.state == .started else { return }
    let isComplete = saga.steps.values.allSatisfy { $0.state == .done }
    if isComplete {
      endSaga(saga)
    }
  }
  
  private func completeCompensation(_ sagaId: String) {
    guard let saga = sagas[sagaId] else { return }
    guard saga.state == .aborted  else { return }
    let isComplete = saga.steps.values.allSatisfy {
      $0.state != .done && $0.state != .started
    }
    if isComplete {
      endSaga(saga)
    }
  }
  
  private func endSaga(_ saga: Saga) {
    logger.logEnd(saga)
    saga.state = .done
    guard let completion = completions.removeValue(forKey: saga.sagaId) else {
      return
    }
    DispatchQueue.global().async { completion.dispose() }
  }
}

extension Coordinator {
  private func consume(_ message: Message, _ step: Step) {
    switch (step.state, message.type) {
    case (.`init`, .transactionStart):
      logger.log(message)
      step.state = .started
      let task = step.transaction.init()
      startTransaction(task, message)
    
    case (.started, .transactionAbort):
      logger.log(message)
      step.state = .aborted
      abortTransation(message.sagaId)
      abortSaga(message.sagaId)
    
    case (.started, .transactionEnd):
      logger.log(message)
      step.state = .done
      completeTransaction(step, message.sagaId)
      completeTransaction(message.sagaId)
    
    case (.started, .compensationStart),
         (.done, .compensationStart):
      logger.log(message)
      let task = step.compensation.init()
      startCompensation(task, message)
    
    case (.`init`, .compensationStart),
         (.aborted, .compensationStart):
      completeCompensation(step, message.sagaId)
      completeCompensation(message.sagaId)
      
    case (.started, .compensationEnd),
         (.done, .compensationEnd):
      logger.log(message)
      step.state = .compensated
      completeCompensation(step, message.sagaId)
      completeCompensation(message.sagaId)
      
    default:
      print("Ignoring \(step.key):\(step.state):\(message.type)")
    }
  }
}

extension Coordinator {
  private func startTransaction(
    _ task: Task,
    _ message: Message
  ) {
    let action: Action = .from(message: message, task: task)
    { [weak self] result in
      switch result {
      case .success(let payload):
        self?.produce(
          .transactionEnd(
            sagaId: message.sagaId,
            stepKey: message.stepKey,
            payload: payload
          )
        )
      case .failure:
        self?.produce(
          .transactionAbort(
            sagaId: message.sagaId,
            stepKey: message.stepKey
          )
        )
      }
    }
    executor.execute(action)
  }
  
  private func abortTransation(_ sagaId: String) {
    guard let saga = sagas[sagaId] else { return }
    let payload = saga.payload
    saga.state = .aborted
    saga.steps.values
      .filter { $0.successors.isEmpty }
      .map {
        .compensationStart(sagaId: sagaId, stepKey: $0.key, payload: payload)
      }
      .forEach(produce)
  }
  
  private func completeTransaction(
    _ step: Step,
    _ sagaId: String
  ) {
    guard let saga = sagas[sagaId] else { return }
    let payload = saga.payload
    step.successors
      // Get all successing steps
      .compactMap { saga.steps[$0] }
      // Declaration of the fileter lambda necessary for compiler to typecheck
      // in reasonable amound of time.
      .filter { (step: Step) -> Bool in
        // Pick ones that have not been started yet
        return step.state == .`init` &&
          // And have all of their dependencies done
          step.dependencies
            .compactMap({ saga.steps[$0] })
            .allSatisfy({ $0.state == .done })
      }
      // Create start transaction message for all of them
      .map {
        .transactionStart(sagaId: sagaId, stepKey: $0.key, payload: payload)
      }
      // And enqueue them
      .forEach(produce)
  }
  
  private func startCompensation(
    _ task: Task,
    _ message: Message
  ) {
    let action: Action = .from(message: message, task: task)
      { [weak self] result in
        switch result {
        case .success:
          self?.produce(
            .compensationEnd(
              sagaId: message.sagaId,
              stepKey: message.stepKey
            )
          )
        case .failure:
          self?.produce(
            .compensationStart(
              sagaId: message.sagaId,
              stepKey: message.stepKey,
              payload: message.payload
            )
          )
        }
      }
    executor.execute(action)
  }
  
  private func completeCompensation(
    _ step: Step,
    _ sagaId: String
  ) {
    guard let saga = sagas[sagaId] else { return }
    let payload = saga.payload
    step.dependencies
      // Get all successing steps
      .compactMap { saga.steps[$0] }
      // Declaration of the fileter lambda necessary for compiler to typecheck
      // in reasonable amound of time.
      .filter { (step: Step) -> Bool in
        // Pick ones that have not been compensated for
        return (step.state == .done || step.state == .started) &&
          // And have all of their predecessors compensated for
          step.successors
            .compactMap({ saga.steps[$0] })
            .allSatisfy({ $0.state != .done && $0.state != .started })
      }
      // Create start transaction message for all of them
      .map {
        .compensationStart(sagaId: sagaId, stepKey: $0.key, payload: payload)
      }
      // And enqueue them
      .forEach(produce)
  }
}
