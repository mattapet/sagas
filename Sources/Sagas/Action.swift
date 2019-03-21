//
//  Action.swift
//  Sagas
//
//  Created by Peter Matta on 3/20/19.
//

import Foundation

public protocol Action {
  var task: Task { get }
  var stepKey: String { get }
  var sagaId: String { get }
  var payload: Data? { get }
  var callback: (Result<Data?, Error>) -> Void { get }
}
