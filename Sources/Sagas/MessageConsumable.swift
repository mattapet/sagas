//
//  MessageConsumable.swift
//  Sagas
//
//  Created by Peter Matta on 3/21/19.
//

public protocol MessageConsumable: class {
  func consume(_ message: Message)
}
