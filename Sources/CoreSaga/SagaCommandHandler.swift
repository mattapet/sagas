//
//  SagaCommandHandler.swift
//  CoreSaga
//
//  Created by Peter Matta on 4/2/19.
//

import Basic
import Foundation

public final class SagaCommandHandler: CommandHandler {
  public typealias Aggregate = Saga
  public typealias Command = SagaCommand
  public typealias ResultType = [StepCommand]
  
  internal let handler: SagaEventHandler
  
  public init(handler: SagaEventHandler) {
    self.handler = handler
  }
  
  public func apply(
    _ command: SagaCommand,
    to saga: Saga,
    with completion: @escaping (Result<ResultType, Error>) -> Void
  ) {
    switch command.type {
    case .start:
      completion(Result { try start(saga) })
    case .abort:
      completion(Result { try abort(saga) })
    case .compensate:
      completion(Result { try compensate(saga) })
    case .finish:
      completion(Result { try finish(saga) })
    }
  }
  
  private func start(_ saga: Saga) throws -> ResultType {
    try await(.started(sagaId: saga.sagaId), saga, handler.apply)
    return saga.steps.values.filter { $0.dependencies.isEmpty }
      .map { .start(stepKey: $0.key, sagaId: saga.sagaId) }
  }
  
  private func abort(_ saga: Saga) throws -> ResultType {
    try await(.aborted(sagaId: saga.sagaId), saga, handler.apply)
    return saga.steps.values.filter { $0.successors.isEmpty }
      .map { .compensate(stepKey: $0.key, sagaId: saga.sagaId) }
  }
  
  private func compensate(_ saga: Saga) throws -> ResultType {
    try await(.compensated(sagaId: saga.sagaId), saga, handler.apply)
    return []
  }
  
  private func finish(_ saga: Saga) throws -> ResultType {
    try await(.finished(sagaId: saga.sagaId), saga, handler.apply)
    return []
  }
}
