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
  internal let execution: DispatchQueue
  internal let completion:  DispatchQueue
  
  public init() {
    self.execution = DispatchQueue(label: "execution_queue")
    self.completion = DispatchQueue(label: "completion_queue")
  }
  
  public func execute(_ action: Action) {
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
    _ action: Action,
    payload: Data?
  ) {
    completion.async { action.callback(.success(payload)) }
  }
  
  public func handleFailedAction(
    _ action: Action,
    error: Error
  ) {
    // Retry logic here?
    completion.async { action.callback(.failure(error)) }
  }
}

