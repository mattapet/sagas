//
//  SagaRepository.swift
//  CoreSaga
//
//  Created by Peter Matta on 4/2/19.
//

import Basic
import Foundation

public final class SagaRepository<
  SagaStore: EventStore,
  StepStore: EventStore
>
  where
    SagaStore.Aggregate == Saga, SagaStore.Event == SagaEvent,
    StepStore.Aggregate == Step, StepStore.Event == StepEvent
{
  internal let store: SagaStore
  internal let eventHandler: SagaEventHandler<SagaStore>
  internal let commandHandler: SagaCommandHandler<SagaStore>
  internal let stepRepository: StepRepository<StepStore>
  
  public init(
    store: SagaStore,
    eventHandler: SagaEventHandler<SagaStore>,
    commandHandler: SagaCommandHandler<SagaStore>,
    stepRepository: StepRepository<StepStore>
  ) {
    self.store = store
    self.eventHandler = eventHandler
    self.commandHandler = commandHandler
    self.stepRepository = stepRepository
  }
  
  public func loadSaga(
    for saga: Saga,
    with completion: @escaping (Result<Saga, Error>) -> Void
  ) {
    completion(Result {
      let events = try await(saga.sagaId, store.load)
      let saga = try events.reduce(saga) { saga, event in
        return try await(event, saga, eventHandler.apply)
      }
      saga.steps = try saga.steps
        .mapValues { try await($0, stepRepository.loadStep) }
      return saga
    })
  }
  
  public func executeCommand(
    _ saga: Saga,
    _ command: SagaCommand,
    with completion: (Result<[StepCommand], Error>) -> Void
  ) {
    completion(Result {
      try await(command, saga, commandHandler.apply)
    })
  }
}
