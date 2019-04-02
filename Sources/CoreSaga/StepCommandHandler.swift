//
//  StepCommandHandler.swift
//  CoreSaga
//
//  Created by Peter Matta on 4/2/19.
//

import Basic
import Foundation

public final class StepCommandHandler: CommandHandler {
  public typealias Aggregate = Step
  public typealias Command = StepCommand
  public typealias ResultType = [StepCommand]
  
  internal let handler: StepEventHandler
  
  public init(
    handler: StepEventHandler
  ) {
    self.handler = handler
  }
  
  public func apply(
    _ command: StepCommand,
    to step: Step,
    with completion: @escaping (Result<[StepCommand], Error>) -> Void
  ) {
    switch (command.type) {
    case .start:
      completion(Result { try start(step, sagaId: command.sagaId) })
    case .finish:
      completion(Result { try finish(step, sagaId: command.sagaId) })
    case .abort:
      completion(Result { try abort(step, sagaId: command.sagaId) })
    case .compensate:
      completion(Result { try compensate(step, sagaId: command.sagaId) })
    }
  }
  
  private func start(_ step: Step, sagaId: String) throws -> ResultType {
    try await(.started(stepKey: step.key, sagaId: sagaId), step, handler.apply)
    return []
  }
  
  private func finish(_ step: Step, sagaId: String) throws -> ResultType {
    try await(.finished(stepKey: step.key, sagaId: sagaId), step, handler.apply)
    return []
  }
  
  private func abort(_ step: Step, sagaId: String) throws -> ResultType {
    try await(.aborted(stepKey: step.key, sagaId: sagaId), step, handler.apply)
    return []
  }
  
  private func compensate(_ step: Step, sagaId: String) throws -> ResultType {
    try await(
      .compensated(stepKey: step.key, sagaId: sagaId), step, handler.apply)
    return []
  }
}

