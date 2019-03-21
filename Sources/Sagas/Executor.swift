//
//  Executor.swift
//  Sagas
//
//  Created by Peter Matta on 3/20/19.
//

import Dispatch
import Foundation

public protocol Executor {
  associatedtype ActionType: Action
  
  func formAction(
    task: Task,
    from message: Message,
    with completion: @escaping (Result<Data?, Error>) -> Void
  ) -> ActionType
  func execute(_ action: ActionType)
}
