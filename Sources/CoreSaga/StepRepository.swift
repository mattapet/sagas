//
//  StepRepository.swift
//  CoreSaga
//
//  Created by Peter Matta on 4/2/19.
//

import Basic
import Foundation

public final class StepRepository<StepEventStore: EventStore>
  where StepEventStore.Aggregate == Step, StepEventStore.Event == StepEvent
{
  internal let store: StepEventStore
  internal let eventHandler: StepEventHandler
  internal let commandHandler: StepCommandHandler
  
  public init(
    store: StepEventStore,
    eventHandler: StepEventHandler,
    commandHandler: StepCommandHandler
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
      try events.forEach { event in
        try await(event, step, eventHandler.apply)
      }
      return step
    })
  }
  
  public func executeCommand(
    _ step: Step,
    _ command: StepCommand,
    with completion: (Result<(), Error>) -> Void
  ) {
    completion(Result {
      try await(command, step, commandHandler.apply)
    })
  }
}
