//
//  BasicExecutor.swift
//  LocalSagas
//
//  Created by Peter Matta on 3/21/19.
//

import Basic
import Sagas
import Dispatch
import Foundation

public final class BasicExecutor: Executor {
  public typealias ActionType = LocalAction
  
  internal let execution: DispatchQueue
  internal let completion: DispatchQueue
  
  public init() {
    self.execution = DispatchQueue(label: "execution_queue")
    self.completion = DispatchQueue(label: "completion_queue")
  }
  
  public func formAction(
    task: Sagas.Task,
    from message: Message,
    with completion: @escaping (Result<Data?, Error>) -> Void
  ) -> LocalAction {
    return LocalAction(
      task: task,
      stepKey: message.stepKey,
      sagaId: message.stepKey,
      payload: message.payload,
      callback: completion)
  }
  
  public func execute(_ action: LocalAction) {
    execution.async { [weak self] in
      do {
        let payload = try await(action.payload, action.task.execute)
        self?.handleSuccessAction(action, payload: payload)
      } catch let error {
        self?.handleFailedAction(action, error: error)
      }
    }
  }
  
  public func handleSuccessAction(
    _ action: LocalAction,
    payload: Data?
  ) {
    completion.async { action.callback(.success(payload)) }
  }
  
  public func handleFailedAction(
    _ action: LocalAction,
    error: Error
  ) {
    // Retry logic here?
    completion.async { action.callback(.failure(error)) }
  }
}

