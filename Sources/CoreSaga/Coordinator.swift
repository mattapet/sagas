//
//  Coordinator.swift
//  CoreSaga
//
//  Created by Peter Matta on 4/2/19.
//

import Basic
import Dispatch
import Foundation

public final class Coordiantor<
  SagaStore: EventStore,
  StepStore: EventStore
>
  where
    SagaStore.Aggregate == Saga, SagaStore.Event == SagaEvent,
    StepStore.Aggregate == Step, StepStore.Event == StepEvent
{
  internal let sagaRepository: SagaRepository<SagaStore, StepStore>
  internal let stepRepository: StepRepository<StepStore>
  
  private let lock: Lock
  private let actionQueue: DispatchQueue
  private let commandQueue: DispatchQueue
  private var sagas: [String:Saga]
  
  public init(
    sagaRepository: SagaRepository<SagaStore, StepStore>,
    stepRepository: StepRepository<StepStore>
  ) {
    self.lock = Lock()
    self.actionQueue = DispatchQueue(label: "action-queue")
    self.commandQueue = DispatchQueue(label: "command-queue")
    self.sagaRepository = sagaRepository
    self.stepRepository = stepRepository
    self.sagas = [:]
  }
  
  public func start(_ saga: Saga) {
    precondition(saga.state == .fresh, "Only fresh sagas can be started")
    lock.withLock { sagas[saga.sagaId] = saga }
    execute(.start(sagaId: saga.sagaId))
  }
}

extension Coordiantor {
  private func dispatch(_ action: Action) {
    actionQueue.async { [weak self] in
      do {
        try await(action.payload, action.job.execute)
        self?.execute(action.success)
      } catch let error {
        guard let failure = action.failure else { fatalError("\(error)") }
        self?.execute(failure)
      }
    }
  }
  
  private func execute(_ command: SagaCommand) {
    commandQueue.async { [weak self] in
      self?.lock.withLock { [weak self] in
        guard let saga = self?.sagas[command.sagaId] else { return }
        try! await(saga, command, self!.sagaRepository.executeCommand)
          .forEach { self?.execute($0) }
      }
    }
  }
  
  private func execute(_ command: StepCommand) {
    commandQueue.async { [weak self] in
      self?.lock.withLock { [weak self] in
        guard let saga = self?.sagas[command.sagaId] else { return }
        guard let step = saga.steps[command.stepKey] else { return }
        try! await(step, command, self!.stepRepository.executeCommand)
          .map { self?.dispatch($0) }
      }
    }
  }
}

