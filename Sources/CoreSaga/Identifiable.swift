//
//  Identifiable.swift
//  CoreSaga
//
//  Created by Peter Matta on 4/2/19.
//

import Foundation

public protocol Identifiable {
  associatedtype ID: Hashable = String
  
  static var IDKeyPath: KeyPath<Self, ID> { get }
}

