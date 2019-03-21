//
//  Executor.swift
//  Sagas
//
//  Created by Peter Matta on 3/20/19.
//

import Dispatch
import Foundation

public protocol Executor {
  func execute(_ action: Action)
  func handleSuccessAction(_ action: Action, payload: Data?)
  func handleFailedAction(_ action: Action, error: Error)
}
