//
//  CommandHandler.swift
//  CoreSaga
//
//  Created by Peter Matta on 4/4/19.
//

import Foundation

public enum ComamndHandlerError: Error {
  case invalidStepKey
  case invalidCommandApplication
}

public protocol CommandHandler: class {
  associatedtype SagaType: AnySaga
  
  func handle(_ command: Command, on saga: SagaType) throws -> [Event]
}
