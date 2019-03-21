//
//  Action.swift
//  Sagas
//
//  Created by Peter Matta on 3/20/19.
//

import Foundation

public struct Action {
  public let task: Task
  public let stepKey: String
  public let sagaId: String
  public let payload: Data?
  public let callback: (Result<Data?, Error>) -> Void
}

extension Action {
  public static func from(
    message: Message,
    task: Task,
    callback: @escaping (Result<Data?, Error>) -> Void
  ) -> Action {
    return Action(
      task: task,
      stepKey: message.stepKey,
      sagaId: message.sagaId,
      payload: message.payload,
      callback: callback
    )
  }
}
