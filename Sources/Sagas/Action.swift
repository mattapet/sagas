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
