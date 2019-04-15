//
//  EventHandler.swift
//  CoreSaga
//
//  Created by Peter Matta on 4/4/19.
//

import Foundation

public enum EventHandlerError: Error {
  case invalidStepKey
  case invalidEventApplication
}

public protocol EventHandler: class {
  associatedtype SagaType: AnySaga
  
  func apply(_ event: Event, to saga: SagaType) throws -> SagaType
}
