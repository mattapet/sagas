//
//  Cancellable.swift
//  Run
//
//  Created by Peter Matta on 3/15/19.
//

import Foundation

public protocol Cancellable {
  var cancelled: Bool { get set }
  mutating func cancel()
}

extension Cancellable {
  public mutating func cancel() {
    guard !cancelled else { return }
    cancelled = true
  }
}
