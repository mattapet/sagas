//
//  StepCommand.swift
//  CoreSaga
//
//  Created by Peter Matta on 4/2/19.
//

import Foundation

public struct StepCommand {
  public enum CommandType {
    case start, finish, abort, compensate
  }
  
  public let type: CommandType
  public let stepKey: String
  public let sagaId: String
  
  fileprivate init(
    type: CommandType,
    stepKey: String,
    sagaId: String
  ) {
    self.type = type
    self.stepKey = stepKey
    self.sagaId = sagaId
  }
}

extension StepCommand {
  public static func start(
    stepKey: String,
    sagaId: String
    ) -> StepCommand {
    return StepCommand(
      type: .start,
      stepKey: stepKey,
      sagaId: sagaId
    )
  }
  
  public static func finish(
    stepKey: String,
    sagaId: String
  ) -> StepCommand {
    return StepCommand(
      type: .finish,
      stepKey: stepKey,
      sagaId: sagaId
    )
  }
  
  public static func abort(
    stepKey: String,
    sagaId: String
  ) -> StepCommand {
    return StepCommand(
      type: .abort,
      stepKey: stepKey,
      sagaId: sagaId
    )
  }
  
  public static func compensate(
    stepKey: String,
    sagaId: String
  ) -> StepCommand {
    return StepCommand(
      type: .compensate,
      stepKey: stepKey,
      sagaId: sagaId
    )
  }
}
