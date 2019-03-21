//
//  MessageProduceable.swift
//  Sagas
//
//  Created by Peter Matta on 3/21/19.
//

public protocol MessageProduceable: class {
  func produce(_ message: Message)
}
