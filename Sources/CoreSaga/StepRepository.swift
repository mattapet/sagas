//
//  StepRepository.swift
//  CoreSaga
//
//  Created by Peter Matta on 4/2/19.
//

import Basic
import Foundation

public final class StepRepository<StepStore: EventStore>
  where StepStore.Aggregate == Step, StepStore.Event == StepEvent
{
  internal let store: StepStore
  internal let eventHandler: StepEventHandler<StepStore>
  internal let commandHandler: StepCommandHandler<StepStore>
  
  public init(
    store: StepStore,
    eventHandler: StepEventHandler<StepStore>,
    commandHandler: StepCommandHandler<StepStore>
  ) {
    self.store = store
    self.eventHandler = eventHandler
    self.commandHandler = commandHandler
  }
  
  public func loadStep(
    for step: Step,
    with completion: @escaping (Result<Step, Error>) -> Void
  ) {
    completion(Result {
      let events = try await(step.key, store.load)
      return try events.reduce(step) { step, event in
        return try await(event, step, eventHandler.apply)
      }
    })
  }
  
  public func executeCommand(
    _ step: Step,
    _ command: StepCommand,
    with completion: (Result<Action?, Error>) -> Void
  ) {
    completion(Result {
      try await(command, step, commandHandler.apply)
    })
  }
}
