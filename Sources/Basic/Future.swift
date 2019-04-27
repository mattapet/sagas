//
//  Future.swift
//  Basic
//
//  Created by Peter Matta on 4/25/19.
//

import Dispatch

// MARK: - Promise

public struct Promise<Value> {
  /// An eventual value corresponding to the `Promise`.
  public let future: Future<Value>
  
  /// Default initializer.
  ///
  /// - parameters:
  ///   - queue: The dispatch queue this promise is tied to.
  public init(queue: DispatchQueue) {
    self.future = Future(queue: queue)
  }
}

// MARK: - Promise completion

extension Promise {
  /// Dalivers a successful result to the associated `Future<Value>` object.
  ///
  /// - parameters:
  ///   - value: Successful result of operation.
  public func success(_ value: Value) {
    _resolve(.success(value))
  }
  
  /// Dalivers an error to the associated `Future<Value>` object.
  ///
  /// - parameters
  ///    - error: The error produced by the operation.
  public func fail(_ error: Error) {
    _resolve(.failure(error))
  }
}

// MARK: Internal interface

extension Promise {
  /// Call the associated `Future<Value>` on appropriate dispatch queue.
  ///
  /// This method ensures all callbacks associated with the `Future<Value>` will
  /// be executed on the dispatch queue that was used to create the given
  /// proimse.
  ///
  /// This method shall be called only *once*. Each promise shall either succeed
  /// or fail and shall to do so exactly once. Duplicate resolution (successuful
  /// or failed) will end up in fatal error.
  ///
  /// - parameters:
  ///   - value: The value to call the future with.
  internal func _resolve(_ result: Result<Value, Error>) {
    let callbacks = future._setValue(result)
    callbacks.forEach { future.queue.async(execute: $0) }
  }
}

// MARK: - Future

public final class Future<Value> {
  typealias Callback = () -> Void
  
  internal let queue: DispatchQueue
  internal let lock: Lock
  
  private var _value: Result<Value, Error>? {
    // Ensure single assignment
    willSet { precondition(_value == nil, "Value can be assigned only once") }
  }
  private var _callbacks: [Callback]
  
  /// Returns `true` if operation resulting in the future value was completed,
  /// `false` otherwise.
  ///
  /// - note: This is a thread safe, computed property.
  internal var isCompleted: Bool {
    return lock.withLock { _value != nil }
  }
  
  public init(queue: DispatchQueue, value: Result<Value, Error>? = nil) {
    self.lock = Lock()
    self._callbacks = []
    self._value = value
    self.queue = queue
  }
}

extension Future {
  public static func == (_ lhs: Future, rhs: Future) -> Bool {
    return lhs === rhs
  }
}

extension Future {
  public func whenSuccess(_ callback: @escaping (Value) -> Void) {
    _whenComplete {
      if case .success(let value) = self._value! {
        callback(value)
      }
    }
  }
  
  public func whenFail(_ callback: @escaping (Error) -> Void) {
    _whenComplete {
      if case .failure(let error) = self._value! {
        callback(error)
      }
    }
  }
  
  public func whenComplete(
    _ callback: @escaping (Result<Value, Error>) -> Void
  ) {
    _whenCompleteWithValue(callback)
  }
}

// MARK: flatMap, map

extension Future {
  public func flatMap<NewValue>(
    _ transform: @escaping (Value) -> Future<NewValue>
  ) -> Future<NewValue> {
    let next = Promise<NewValue>(queue: queue)
    _whenComplete {
      switch self._value! {
      case .success(let value):
        let newFuture = transform(value)
        newFuture._whenCompleteWithValue { result in
          next._resolve(result)
        }
      case .failure(let error):
        next._resolve(.failure(error))
      }
    }
    return next.future
  }
  
  public func flatMapThrowing<NewValue>(
    _ transform: @escaping (Value) throws -> Future<NewValue>
  ) -> Future<NewValue> {
    return flatMap { value in
      do {
        return try transform(value)
      } catch {
        return Future<NewValue>(queue: self.queue, value: .failure(error))
      }
    }
  }
  
  public func flatMapError(
    _ transform: @escaping (Error) -> Future
  ) -> Future {
    let next = Promise<Value>(queue: queue)
    _whenComplete {
      switch self._value! {
      case .success(let value):
        next._resolve(.success(value))
      case .failure(let error):
        let newFuture = transform(error)
        newFuture._whenCompleteWithValue { result in
          next._resolve(result)
        }
      }
    }
    return next.future
  }
  
  public func flatMapErrorThrowing(
    _ transform: @escaping (Error) throws -> Future
  ) -> Future {
    return flatMapError { error in
      do {
        return try transform(error)
      } catch {
        return Future(queue: self.queue, value: .failure(error))
      }
    }
  }
  
  public func map<NewValue>(
    _ transform: @escaping (Value) throws -> NewValue
  ) -> Future<NewValue> {
    return flatMap { value in
      Future<NewValue>(
        queue: self.queue,
        value: Result { try transform(value) })
    }
  }
  
  public func mapError(
    _ transform: @escaping (Error) throws -> Value
  ) -> Future {
    return flatMapError { error in
      Future(queue: self.queue, value: Result { try transform(error) })
    }
  }
}

// MAKR: - reduce

extension Future {
  public func fold<OtherValue>(
    _ futures: [Future<OtherValue>],
    _ nextPartialResult: @escaping (Value, OtherValue) -> Future<Value>
  ) -> Future<Value> {
    return futures.reduce(self) { f1, f2 in
      return f1.and(f2).flatMap { nextPartialResult($0.0, $0.1) }
    }
  }
  
  public static func reduce<Result>(
    _ initialResult: Result,
    _ futures: [Future<Value>],
    on queue: DispatchQueue,
    _ nextPartialResult: @escaping (Result, Value) -> Result
  ) -> Future<Result> {
    let result = queue.makeSuccessFuture(initialResult)
    return result.fold(futures) { lhs, rhs in
      return queue.makeSuccessFuture(nextPartialResult(lhs, rhs))
    }
  }
}

// MARK: - and

extension Future {
  public func and<OtherValue>(
    _ other: Future<OtherValue>
  ) -> Future<(Value, OtherValue)> {
    let promise = queue.makePromise(of: (Value, OtherValue).self)
    var lhs: Value? = nil
    var rhs: OtherValue? = nil
    
    _whenComplete {
      switch (self._value!, rhs) {
      case (.failure(let error), _) where !promise.future.isCompleted:
        promise._resolve(.failure(error))
      case (.success(let lhs), .some(let rhs)):
        promise._resolve(.success((lhs, rhs)))
      case (.success(let value), .none):
        lhs = value
      case (.failure, _):
        break
      }
    }
    
    other.hop(to: queue)._whenComplete {
      switch (other._value!, lhs) {
      case (.failure(let error), _) where !promise.future.isCompleted:
        promise._resolve(.failure(error))
      case (.success(let rhs), .some(let lhs)):
        promise._resolve(.success((lhs, rhs)))
      case (.success(let value), .none):
        rhs = value
      case (.failure, _):
        break
      }
    }
    return promise.future
  }
}

// MARK: cascade

extension Future {
  public func cascade(to promise: Promise<Value>) {
    whenComplete { result in
      switch result {
      case .success(let value): promise.success(value)
      case .failure(let error): promise.fail(error)
      }
    }
  }
}

// MARK: hop

extension Future {
  public func hop(to target: DispatchQueue) -> Future<Value> {
    if target === queue {
      // We are already on the target dispatch queue
      return self
    }
    let promise = target.makePromise(of: Value.self)
    cascade(to: promise)
    return promise.future
  }
}

// MARK: wait

extension Future {
  public func wait() throws -> Value {
    let lock = Lock()
    let group = DispatchGroup()
    var result: Result<Value, Error>? = nil
    group.enter()
    _whenCompleteWithValue { result0 in
      lock.withLock { result = result0 }
      group.leave()
    }
    group.wait()
    return try result!.get()
  }
}

// MARK: internal

extension Future {
  internal func _setValue(_ value: Result<Value, Error>) -> [Callback] {
    return lock.withLock {
      // Store the resulting value
      self._value = value
      // Flush the callbacks that were set
      let callbacks = self._callbacks
      self._callbacks = []
      // And return them for the execution
      return callbacks
    }
  }
  
  internal func _whenComplete(_ callback: @escaping () -> Void) {
    lock.withLock {
      guard self._value == nil else {
        // If value was received before calling _whenComplete, call the callback
        // directly without appending it.
        callback()
        return
      }
      self._callbacks.append(callback)
    }
  }
  
  internal func _whenCompleteWithValue(
    _ callback: @escaping (Result<Value, Error>) -> Void
  ) {
    _whenComplete { callback(self._value!) }
  }
}
