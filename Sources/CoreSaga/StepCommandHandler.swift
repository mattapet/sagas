//
//  StepCommandHandler.swift
//  CoreSaga
//
//  Created by Peter Matta on 4/2/19.
//

import Basic
import Foundation

public final class StepCommandHandler<StepStore: EventStore>: CommandHandler
  where StepStore.Aggregate == Step, StepStore.Event == StepEvent
{
  public typealias Aggregate = Step
  public typealias Command = StepCommand
  public typealias ResultType = Action?
  
  internal let handler: StepEventHandler<StepStore>
  
  public init(
    handler: StepEventHandler<StepStore>
  ) {
    self.handler = handler
  }
  
  public func apply(
    _ command: StepCommand,
    to step: Step,
    with completion: @escaping (Result<Action?, Error>) -> Void
  ) {
    return completion(Result {
      switch (command.type) {
      case .start:
        return try start(step, sagaId: command.sagaId)
      case .finish:
        return try finish(step, sagaId: command.sagaId)
      case .abort:
        return try abort(step, sagaId: command.sagaId)
      case .compensate:
        return try compensate(step, sagaId: command.sagaId)
      }
    })
  }
  
  private func start(_ step: Step, sagaId: String) throws -> ResultType {
    try await(.started(stepKey: step.key, sagaId: sagaId), step, handler.apply)
    return .transaction(step: step, sagaId: sagaId)
  }
  
  private func finish(_ step: Step, sagaId: String) throws -> ResultType {
    try await(.finished(stepKey: step.key, sagaId: sagaId), step, handler.apply)
    return nil
  }
  
  private func abort(_ step: Step, sagaId: String) throws -> ResultType {
    try await(.aborted(stepKey: step.key, sagaId: sagaId), step, handler.apply)
    return nil
  }
  
  private func compensate(_ step: Step, sagaId: String) throws -> ResultType {
    try await(
      .compensated(stepKey: step.key, sagaId: sagaId), step, handler.apply)
    return .compensation(step: step, sagaId: sagaId)
  }
}

