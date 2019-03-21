//
//  LocalAction.swift
//  LocalSagas
//
//  Created by Peter Matta on 3/21/19.
//

import Sagas
import Foundation

public struct LocalAction: Action {
  public let task: Sagas.Task
  public let stepKey: String
  public let sagaId: String
  public let payload: Data?
  public let callback: (Result<Data?, Error>) -> Void
}
