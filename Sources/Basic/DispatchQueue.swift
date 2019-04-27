//
//  DispatchQueue.swift
//  Basic
//
//  Created by Peter Matta on 4/26/19.
//

import Foundation

extension DispatchQueue {
  /// Creates a `Promise` object tied to the given dispatch queue.
  ///
  /// - parameters:
  ///   - type: Type of the eventual result of the operation.
  public func makePromise<Value>(of type: Value.Type) -> Promise<Value> {
    return Promise(queue: self)
  }
  
  /// Creates a succeeded `Future` value tied to the given dispatch queue.
  ///
  /// - parameters:
  ///   - value: Result of the operation.
  public func makeSucceededFuture<Value>(_ value: Value) -> Future<Value> {
    return Future(queue: self, value: .success(value))
  }
  
  /// Creates a failed `Future` value teid to the given dispatch queue.
  ///
  /// - parameters:
  ///   - error: Error discribing the failure of the operation.
  public func makeFailedFuture<Value>(
    _ error: Error,
    of type: Value.Type
  ) -> Future<Value> {
    return Future(queue: self, value: .failure(error))
  }
}
