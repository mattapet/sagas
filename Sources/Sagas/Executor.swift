//
//  Executor.swift
//  Sagas
//
//  Created by Peter Matta on 3/20/19.
//

import Dispatch
import Foundation

public final class Executor {
  internal let execution: DispatchQueue
  internal let completion:  DispatchQueue
  
  public init() {
    self.execution = DispatchQueue(label: "execution_queue")
    self.completion = DispatchQueue(label: "completion_queue")
  }
  
  public func execute(_ action: Action) {
    execution.async {
      action.task.execute(using: action.payload) { [weak self] result in
        switch result {
        case .success(let payload):
          self?.handleSuccessAction(action, payload: payload)
        case .failure(let error):
          self?.handleFailedAction(action, error: error)
        }
      }
    }
  }
  
  func handleSuccessAction(
    _ action: Action,
    payload: Data?
  ) {
    completion.async { action.callback(.success(payload)) }
  }
  
  func handleFailedAction(
    _ action: Action,
    error: Error
  ) {
    // Retry logic here?
    completion.async { action.callback(.failure(error)) }
  }
}
