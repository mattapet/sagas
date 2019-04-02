//
//  SagaCommand.swift
//  CoreSaga
//
//  Created by Peter Matta on 4/2/19.
//

import Foundation

public struct SagaCommand {
  public enum CommandType {
    case start, finish, abort, compensate
  }
  
  public let type: CommandType
  public let sagaId: String
  
  fileprivate init(
    type: CommandType,
    sagaId: String
  ) {
    self.type = type
    self.sagaId = sagaId
  }
}

extension SagaCommand {
  public static func start(
    sagaId: String
  ) -> SagaCommand {
    return SagaCommand(
      type: .start,
      sagaId: sagaId
    )
  }
  
  public static func finish(
    sagaId: String
  ) -> SagaCommand {
    return SagaCommand(
      type: .finish,
      sagaId: sagaId
    )
  }
  
  public static func abort(
    sagaId: String
  ) -> SagaCommand {
    return SagaCommand(
      type: .abort,
      sagaId: sagaId
    )
  }
  
  public static func compensate(
    sagaId: String
  ) -> SagaCommand {
    return SagaCommand(
      type: .compensate,
      sagaId: sagaId
    )
  }
}
