//
//  Future.swift
//  Basic
//
//  Created by Peter Matta on 4/25/19.
//

import Dispatch

// MARK: - Promise

/// Promise of an eventual result (or a failure) of asynchronous opreation.
///
/// This is a API provider for the `Future<Value>`. Each asynchronous operation
/// that wishes to return an incomplete/unfultilled value shall return a
/// promise such as:
///
///     func someAsyncOperation(args) -> Future<Value> {
///       // Create a promise tied to some dispatch queue `queue`
///       let promise = queue.makePromise(of: Value.self)
///       someAsyncOpeartionWithCallback { (result: Result<Value, Error>) in
///         switch result {
///         case .successful(let value):
///           // When operation completes successfully...
///           promise.success(value)
///         case .failure(let error):
///           // When operation fails...
///           promise.fail(error)
///       }
///       // Return the promised future value
///       return promise.future
///     }
///
/// Note that the future value is typically returned before the async opeartion
/// completes. That is why one would be tempted to use `Future<Value>.wait()`
/// method, however doing so is considered an anti-pattern and thus is
/// discouraged.
///
/// One should rather compose the wanted behavior suing mapping API provided by
/// the future such as:
///
/// * If you have a `Future<Value>` and want to perform another asynchronous
///   operation after the value completes, use `Future<Value>.flatMap()`.
/// * If you already have a value and need a `Future<Value>` to provide to some
///   API, use `DispatchQueue.makeSucceededFuture(result)` to create a already
///   resolved future value or `DispatchQueue.makeFailedFuture(error)` to create
///   a failed future value.
///
/// - note: Each promise shall complete exactly once. Not completing promises
///   may lead to memory leaks. However completing promise more than once causes
///   a `fatalError` to occur.
public struct Promise<Value> {
  /// `Future<Value>` object associated with the promised result.
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
  /// Completes the associated `Future<Value>` on appropriate dispatch queue.
  ///
  /// This method ensures all callbacks associated with the `Future<Value>` will
  /// be executed on the dispatch queue that was used to create the proimse.
  ///
  /// This method shall be called exactly *once*. Not completing promises
  /// may lead to memory leaks. However completing promise more than once causes
  /// a `fatalError` to occur.
  ///
  /// - parameters:
  ///   - value: The value to call the future with.
  internal func _resolve(_ result: Result<Value, Error>) {
    let callbacks = future._setValue(result)
    callbacks.forEach { future.queue.async(execute: $0) }
  }
}

// MARK: - Future

/// Container for the result of asynchronous operation that will be provided
/// later.
///
/// Functions that perform some asynchronous operation may to return a promise
/// of a result of such operation as `Future<Value>`. The recipient of such
/// promise can use the placeholder `Future<Value>` object to observe the result
/// of the operation being notified when the operation completes or fails.
///
/// Observation of the fulfillment of the promise can be done using variety of
/// the methods provided by the `Future<Value>` such as `flatMap`, `map`,
/// `flatMapError` or `wait`.
///
/// The provider of the `Future<Value>` typically creates the placeholder object
/// *before* the actual result is available. For example:
///
///     func perofrmNetworkCall(args) -> Future<ResultType> {
///       let promise = queue.makePromise(of: ResultType.self)
///       DispatchQueue.global().async {
///         /* Perform actual network call */
///
///         // Eventually call `Promise<Value>.success(value)` with the response
///         promise.success(response)
///         // Or `Promise<Value>.fail(error)` if there was an error encountered
///         promise.fail(error)
///       }
///       return promise
///     }
///
/// Note that the function returns *immediately* and does not wait for the
/// promise to be fulfilled. This behavior is common across many programming
/// languages that have a concept of Futures/Promises:
///
/// - [C++](https://en.cppreference.com/w/cpp/thread/future)
/// - [Javascript](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Using_promises)
/// - [Scala](http://docs.scala-lang.org/overviews/core/futures.html)
///
/// ### Threading and Futures
///
/// Futures are observable values that provide a callback based interface for
/// observing the completion of the value. Each of the `Future` object is tied
/// to a specific `DispatchQueue` which is used to execute all registered
/// callbacks on.
///
/// #### Callbacks
///
/// As it was mentioned previosly, all of the callbacks registered on a given
/// `Future<Value>` will be executed on the thread corresponding to a dispatch
/// queue used to create the given `Future` *regardless* of what thread succeeds
/// or fails associated `Promise<Value>`.
public final class Future<Value> {
  typealias Callback = () -> Void
  
  /// The dispatch queue that is tied to the future and is used to execute all
  /// callbacks associated with the future.
  public let queue: DispatchQueue
  
  /// A lock used to ensure unique access to `_value` and `_callbacks` sotred
  /// properties.
  private let lock: Lock
  
  /// The actual stored result of the asynchronous computation. This is a stored
  /// property that can be assigned only once and only a non-nil value.
  private var _value: Result<Value, Error>? {
    willSet {
      // Ensure single assignment
      precondition(_value == nil, "Value can be assigned only once")
      // Ensure we initialize the value only once
      precondition(newValue != nil, "Value cannot be assigned `nil`")
    }
  }
  
  /// List of callbacks that should be executed when this `Future<Value>`
  /// receives a value.
  private var _callbacks: [Callback]
  
  /// Returns `true` if operation resulting in the future value was completed,
  /// `false` otherwise.
  ///
  /// - note: This is a thread safe, computed property.
  internal var isComplete: Bool {
    return lock.withLock { _value != nil }
  }
  
  /// Default initializer.
  ///
  /// - parameters:
  ///   - queue: Dispatch queue tied to the future result.
  ///   - value: A result of the async operation, if completed, otherwise `nil`.
  internal init(queue: DispatchQueue, value: Result<Value, Error>? = nil) {
    self.lock = Lock()
    self._callbacks = []
    self._value = value
    self.queue = queue
  }
  
  /// Default initializer.
  ///
  /// - parameters:
  ///   - queue: Dispatch queue tied to the future result.
  ///   - value: A result of the async operation, if completed, otherwise `nil`.
  internal init(_queue queue: DispatchQueue, value: Result<Value, Error>?) {
    self.lock = Lock()
    self._callbacks = []
    self._value = value
    self.queue = queue
  }
  
  /// Convenience initializer for incomplete future.
  ///
  /// - parameters:
  ///   - queue: Dispatch queue tied to the future result.
  internal convenience init(queue: DispatchQueue) {
    self.init(_queue: queue, value: nil)
  }
  
  /// Convenience initializer for successfully completed future.
  ///
  /// - parameters:
  ///   - queue: Dispatch queue tied to the future result.
  ///   - value: A result of the async operation.
  internal convenience init(queue: DispatchQueue, value: Value) {
    self.init(_queue: queue, value: .success(value))
  }
  
  /// Convenience initializer for future completed with an error.
  ///
  /// - parameters:
  ///   - queue: Dispatch queue tied to the future result.
  ///   - error: An error encountered during the  async operation.
  internal convenience init(queue: DispatchQueue, error: Error) {
    self.init(_queue: queue, value: .failure(error))
  }
  
  deinit {
    #if DEBUG
    precondition(isComplete, "Leaking of incomplete Promise")
    #endif
  }
}

extension Future: Equatable {
  /// Future is equatable only if it is the same instance.
  public static func == (_ lhs: Future, rhs: Future) -> Bool {
    return lhs === rhs
  }
}

// MARK: - flatMap and map implementations

extension Future {
  /// Run given callback providing a new `Future<NewValue>` when this future
  /// successfully completes.
  ///
  /// This method allows one to compose complex asynchronous operations as a
  /// series of asynchronous steps. Note that each callback in the chain is
  /// passed the result of the previous operation, for example:
  ///
  ///     let f1 = networkRequest(args).future()
  ///     let f2 = f1.flatMap { response in
  ///       /* Do something with the response */
  ///       return networkRequest(args).future()
  ///     }
  ///     f2.whenSuccess { response in
  ///       print("Response of the second request is \(response)")
  ///     }
  ///
  /// Note that each `Future<Value>.flatMap(callback)` creates a new new future
  /// placeholder that is immediatelly returned, which is commonly used to chain
  /// the calls such as:
  ///
  ///     let f = networkRequest(args).future()
  ///       .flatMap { response in
  ///         /* Do something with the response */
  ///         return netowrkRequest(args).future()
  ///       }
  ///     f.whenSuccess { response in
  ///       print("Response of the second request is \(response)")
  ///     }
  ///
  /// - parameters:
  ///   - transform: Function that will receive the result value of this future
  ///     and returns a new `Future<NewValue>`.
  /// - returns: A new future, that will receive an eventual value.
  public func flatMap<NewValue>(
    _ transform: @escaping (Value) -> Future<NewValue>
  ) -> Future<NewValue> {
    let next = queue.makePromise(of: NewValue.self)
    _whenComplete {
      switch self._value! {
      case .success(let value):
        // Get the future from the mapping callback
        let innerFuture = transform(value)
        // Complete the promise when the created future completes
        innerFuture._whenComplete {
          next._resolve(innerFuture._value!)
        }
      case .failure(let error):
        // Skip over the callback if this future resolves in failure
        next._resolve(.failure(error))
      }
    }
    return next.future
  }
  
  /// Run given callback providing a new `Future<NewValue>` when this future
  /// successfully completes. The provided callback may optionally `throw`.
  ///
  /// This method mirrors the behavior of `Future<Value>.flatMap(callback)` with
  /// the exception of hadling error that may be thrown when executing the
  /// callback.
  ///
  /// If the callback passed to the method throws, the returned
  /// `Future<NewValue>` will fail with the thrown error.
  ///
  /// - parameters:
  ///   - transform: Function that will receive the error value of this future
  ///     and return a new `Future<Value>` attempting to recover from the error.
  /// - returns: A new future, that will receive an eventual value.
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
  
  /// Run given callback providing a new `Future<Value>` when this future
  /// errors.
  ///
  /// - parameters:
  ///   - transform: Function that will receive the error value of this future
  ///     and return a new `Future<Value>` attempting to recover from the error.
  /// - returns: A new future, that will receive an eventual value.
  public func flatMapError(
    _ transform: @escaping (Error) -> Future
  ) -> Future {
    let next = Promise<Value>(queue: queue)
    _whenComplete {
      switch self._value! {
      case .success(let value):
        // Skip over the callback if this future resolves in success
        next._resolve(.success(value))
      case .failure(let error):
        // Get the future from mapping the callback
        let innerFuture = transform(error)
        // Complete the promise when the created future completes
        innerFuture._whenCompleteWithValue { result in
          next._resolve(result)
        }
      }
    }
    return next.future
  }
  
  /// Run given callback providing a new `Future<Value>` when this future
  /// errors. The provided callback may optionally `throw`.
  ///
  /// This method mirrors the behavior of `Future<Value>.flatMapError(callback)`
  /// with the exception of hadling error that may be thrown when executing the
  /// callback.
  ///
  /// If the callback passed to the method throws, the returned `Future<Value>`
  /// will fail with the thrown error.
  ///
  /// - parameters:
  ///   - transform: Function that will receive the error value of this future
  ///     and return a new `Future<Value>` attempting to recover from the error.
  /// - returns: A new future, that will receive an eventual value.
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
  
  /// Run given transformation callback when this future completes returning
  /// a new, transformed result returned as a new `Future<NewValue>`.
  ///
  /// Operations executed as part of the given transformation callback should
  /// block, or they will block the entire dispatch queue tied to this future.
  /// Rather it should perform a simple data transformation that may
  /// potentionally error.
  ///
  ///     let f = networkRequest(args).future()
  ///       .map { try parse($0) }
  ///
  ///     f.whenSuccess { result in
  ///        print("Parsed result of the network call is \(result)")
  ///     }
  ///     f.whenError { error in
  ///       print("There was an error encountered \(error)")
  ///     }
  ///
  /// - parameters:
  ///   - transform: Function that will receive the result value of this future
  ///     and returns a transformed value of type `NewValue`.
  /// - returns: A new future, that will receive an eventual value.
  public func map<NewValue>(
    _ transform: @escaping (Value) throws -> NewValue
  ) -> Future<NewValue> {
    return flatMap { value in
      Future<NewValue>(
        queue: self.queue,
        value: Result { try transform(value) })
    }
  }
  
  /// Run given callback providing a new `Value` when this future errors. The
  /// provided callback may optionally `throw`.
  ///
  /// Operations executed as part of the given transformation callback should
  /// block, or they will block the entire dispatch queue tied to this future.
  /// Rather it should perform a simple data transformation that may
  /// potentionally error.
  ///
  /// If the callback passed to the method throws, the returned `Future<Value>`
  /// will fail with the thrown error.
  ///
  /// - parameters:
  ///   - transform: Function that will receive the error value of this future
  ///     and return a new `Value` recovering from the error.
  /// - returns: A new future, that will receive an eventual value.
  public func mapError(
    _ transform: @escaping (Error) throws -> Value
  ) -> Future {
    return flatMapError { error in
      Future(queue: self.queue, value: Result { try transform(error) })
    }
  }
  
  /// Run given callback when the future completes with a result.
  ///
  /// The callback cannot return meaning this method cannot be chained from. If
  /// you with to create a chain of operations, consider using `map` and/or
  /// `flatMap` methods.
  ///
  /// - parameters:
  ///   - callback: Callback that is called when the future succeeds with a
  ///     result.
  public func whenSuccess(_ callback: @escaping (Value) -> Void) {
    _whenComplete {
      guard case .success(let value) = self._value! else { return }
      callback(value)
    }
  }
  
  /// Run given callback when the future completes with an error.
  ///
  /// The callback cannot return meaning this method cannot be chained from. If
  /// you with to create a chain of operations, consider using `mapError` and/or
  /// `flatMapError` methods.
  ///
  /// - parameters:
  ///   - callback: Callback that is called when the future fails with an error.
  public func whenFail(_ callback: @escaping (Error) -> Void) {
    _whenComplete {
      guard case .failure(let error) = self._value! else { return }
      callback(error)
    }
  }
  
  /// Run given callback when the future completes with any result.
  ///
  /// The callback cannot return meaning this method cannot be chained from. The
  /// primary use case for this method is to perform any additional cleanup
  /// necessary after the completion of the asynchronous operation.
  ///
  /// - parameters:
  ///   - callback: Callback that is called when the future completes.
  public func whenComplete(
    _ callback: @escaping (Result<Value, Error>) -> Void
  ) {
    _whenComplete {
      callback(self._value!)
    }
  }
}

extension Future {
  /// Adds a callback to the list of callbacks that shall be run when the future
  /// completes with a result.
  ///
  /// If the value is present, schedule the callback to be executed on the tied
  /// queue immediately.
  internal func _whenComplete(_ callback: @escaping () -> Void) {
    // Ensure synchronous access to `_value` and `_callbacks`.
    lock.withLock {
      switch self._value {
      // If value was received before calling _whenComplete, invoke the callback
      // directly without appending it.
      case .some: self.queue.async { callback() }
      // Otherwise just append to the list of the callbacks.
      case .none: self._callbacks.append(callback)
      }
    }
  }
  
  internal func _whenCompleteWithValue(
    _ callback: @escaping (Result<Value, Error>) -> Void
  ) {
    _whenComplete { callback(self._value!) }
  }
  
  /// Sets the value of the future returning callabacks assocaited to this
  /// future.
  internal func _setValue(_ value: Result<Value, Error>) -> [Callback] {
    // Ensure synchronous access to `_value` and `_callbacks`.
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
}

// MARK: - and

extension Future {
  /// Return a new `Future` that succeeds if this future *and* another provided
  /// `Future` both succeed.
  ///
  /// The result of the future is a tuple of type `(Value, OtherValue)`, where
  /// the first value of type `Value` is the result of this `Future<Value>` and
  /// the second value of type `OtherValue` is result of the provided future
  /// `Future<OtherValue>`.
  ///
  /// This can be used to perform two asynchronous operations in parallel
  /// continueing only if both of them succeed.
  ///
  /// For example:
  ///
  ///     let f1 = netowrkRequest(args).future()
  ///     let f2 = networkRequest(args).future()
  ///     let f3 = f1.and(f2)
  ///     f3.whenSuccess { (results: (T, U)) in
  ///       let (result1, result2) = results
  ///       /* Perform operation with both of the requests */
  ///       print("Result of first request is \(result1)")
  ///       print("Result of second request is \(result2)")
  ///     }
  ///
  /// In case of failure of either of the futures, the resulting future will
  /// fail with the first error encountered.
  ///
  /// The returned `Future<(Value, OtherValue)>` will be tied to the same
  /// dispatch queue as this future.
  ///
  /// - parameters:
  ///   - other: Another future that shall be combined with this one in the
  ///     resulting future.
  /// - returns: A new future, that will receive an eventual value of type
  ///   `(Value, OtherValue)`.
  public func and<OtherValue>(
    _ other: Future<OtherValue>
  ) -> Future<(Value, OtherValue)> {
    let promise = queue.makePromise(of: (Value, OtherValue).self)
    var lhs: Value? = nil
    var rhs: OtherValue? = nil
    
    _whenComplete {
      switch (self._value!, rhs) {
      case (.failure(let error), _) where !promise.future.isComplete:
        promise._resolve(.failure(error))
      case (.success(let lhs), .some(let rhs)):
        promise._resolve(.success((lhs, rhs)))
      case (.success(let value), .none):
        lhs = value
      case (.failure, _):
        break
      }
    }
    
    // Ensure execution on the same dispatch queue
    other.hop(to: queue)._whenComplete {
      switch (other._value!, lhs) {
      case (.failure(let error), _) where !promise.future.isComplete:
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
  
  /// Returns a new `Future` that that succeeds if this future succeeds with
  /// result of this future "and" the provided value.
  ///
  /// This method is just a convenience wrapper around `and` method so one can
  /// write:
  ///
  ///     future.and(value)
  ///
  /// instead of:
  ///
  ///     future.and(queue.makeSucceededFuture(value))
  ///
  /// - parameters:
  ///   - other: Another value that shall be combined with this future in the
  ///     resulting future.
  /// - returns: A new future, that will receive an eventual value of type
  ///   `(Value, OtherValue)`.
  public func and<OtherValue>(
    _ value: OtherValue
  ) -> Future<(Value, OtherValue)> {
    return and(queue.makeSucceededFuture(value))
  }
}

// MARK: - fold

extension Future {
  /// Returns a new `Future<Value>` that completes successfully only when this
  /// future and all the provided `futures` complete successfully.
  ///
  /// The eventual value of the future is the eventual value of this future
  /// folded over all the `futures` applying `nextPartialResult` function.
  ///
  /// The returned `Future<Value>` will fail as soon as a fail is encountered.
  ///
  /// - parameters:
  ///   - futures: List of `Future<OtherValue>` futures to folder over.
  ///   - nextPartialResult: The function that will be used to fold the values
  ///   `futures`.
  /// - returns: A new future, that will receive an eventual value.
  public func fold<OtherValue>(
    _ futures: [Future<OtherValue>],
    with nextPartialResult: @escaping (Value, OtherValue) -> Future<Value>
  ) -> Future<Value> {
    return futures.reduce(self) { f1, f2 in
      return f1.and(f2).flatMap { nextPartialResult($0.0, $0.1) }
    }
  }
}

// MARK: cascade

extension Future {
  /// Completes the given `Promise<Value>` with the result of this
  /// `Future<Value>`.
  ///
  /// This methods allows third parties to provide promises for you to complete.
  ///
  /// For example:
  ///
  ///     doWork().flatMap {
  ///         doMoreWork($0)
  ///       }.flatMap {
  ///         doYetMoreWork($0)
  ///       }.flatMapError {
  ///         recoverFromError($0)
  ///       }.map {
  ///         try transformData($0)
  ///       }.cascade(to: userPromise)
  ///
  /// - parameter:
  ///   - promise: The `Promise<Value>` that is to be completed with the result
  ///     of this future.
  public func cascade(to promise: Promise<Value>) {
    whenComplete { result in
      switch result {
      case .success(let value): promise.success(value)
      case .failure(let error): promise.fail(error)
      }
    }
  }
  
  /// Completes the given `Promise<Value>` only when this `Future<Value>`
  /// completes successfully.
  ///
  /// - parameters:
  ///   - promise: The `Promise<Value>` that is to be completed with the
  ///     successful result of this future.
  public func cascadeSuccess(to promise: Promise<Value>) {
    whenSuccess { promise.success($0)  }
  }
  
  /// Completes the given `Promise<NewValue>` only when this `Future<Value>`
  /// fails with an error.
  ///
  /// - parameters:
  ///   - promise: The `Promise<NewValue>` that is to be completed with the
  ///     error that caused this future to fail.
  public func cascadeFailure<NewValue>(to promise: Promise<NewValue>) {
    whenFail { promise.fail($0) }
  }
}

// MARK: wait

extension Future {
  /// Wait for the completion of this future by *blocking* the current thread
  /// until the future completed.
  ///
  /// If the `Future<Value>` completes successfully with a value, the value is
  /// returned from the method. If the `Future<Value>` fails with an error
  /// however, the method will throw the error instead.
  ///
  /// - returns: The value of the `Future<Value>` when it successfully
  ///   completes.
  /// - throws: The error value of `Future<Value>` when it fails.
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

// MARK: hop

extension Future {
  /// Returns a new `Future<Value>` that completes when this future completes
  /// with the same results, but executes all of its callbacks on the `target`
  /// queue.
  ///
  /// A common use case to want to `hop` between the dispatch queues would be
  /// synchronization of the future passed as an argument. For example:
  ///
  ///     func doSomethingWithFuture(_ future: Future<Value>) {
  ///       let f1 = future.hop(to: queue)
  ///       f1.whenSuccess { doAction($0) }
  ///     }
  ///
  /// - parameters:
  ///   - target: The `DispatchQueue` that the returned `Future<Value>` will be
  ///     tied to.
  /// - returns: A new future, that will receive an eventual value, which
  ///   callbacks will run on the `target` queue.
  public func hop(to target: DispatchQueue) -> Future<Value> {
    guard target !== queue else {
      // We are already on the target dispatch queue
      return self
    }
    let promise = target.makePromise(of: Value.self)
    cascade(to: promise)
    return promise.future
  }
}

// MARK: - reduce, fail fast

extension Future {
  /// Returns a new `Future<Result>` that completes when all of the futures
  /// complete folding the `initialResult` over all results of `futures`.
  ///
  /// This function is equivalent to `Sequence.reduce()`, requireing copies of
  /// the partial result being made. If this is of consern to you, consider
  /// using `reduce<Result>(into:).
  ///
  /// The returned `Future<Value>` will fail as soon as a fail is encountered.
  ///
  /// - parameters:
  ///   - initialResult: The value to use as the initial accumulating value.
  ///   - futures: List of the futures to reduce.
  ///   - queue: A `DispatchQueue` to tie the new future to.
  ///   - nextPartialResult: A closure that combines an accumulating value and
  ///     an element of the sequence into a new accumulating value.
  /// - returns: A new `Future<Result>` with an eventual reduced value.
  public static func reduce<Result>(
    _ initialResult: Result,
    _ futures: [Future<Value>],
    on queue: DispatchQueue,
    _ nextPartialResult: @escaping (Result, Value) -> Result
  ) -> Future<Result> {
    let result = queue.makeSucceededFuture(initialResult)
    // Fold the result over all of the futures
    return result.fold(futures) { lhs, rhs in
      return queue.makeSucceededFuture(nextPartialResult(lhs, rhs))
    }
  }
  
  /// Returns a new `Future<Result>` that completes when all of the futures
  /// complete folding the `initialResult` over all results of `futures`.
  ///
  /// This function is equivalent to `Sequence.reduce(into:)`, which does not
  /// make copies of the result type for each `Future`.
  ///
  /// The returned `Future<Value>` will fail as soon as a fail is encountered.
  ///
  /// - parameters:
  ///   - initialResult: The value to use as the initial accumulating value.
  ///   - futures: List of the futures to reduce.
  ///   - queue: A `DispatchQueue` to tie the new future to.
  ///   - nextPartialResult: A closure that updates the accumulating value with
  ///     a result of the next `Future<Value>` in the `futures` array.
  /// - returns: A new `Future<Result>` with an eventual reduced value.
  public static func reduce<Result>(
    into initialResult: Result,
    _ futures: [Future<Value>],
    on queue: DispatchQueue,
    _ updateAccumulatingValue: @escaping (inout Result, Value) -> Void
  ) -> Future<Result> {
    let promise = queue.makePromise(of: Result.self)
    var accumulator = initialResult
    
    // Use an empty future as a iterator for folding
    let f0 = queue.makeSucceededFuture(())
    // Fold over all of the futures updating the accumulator
    let future = f0.fold(futures) { _, nextValue in
      updateAccumulatingValue(&accumulator, nextValue)
      // Return another empty future, as if we returned plain Void
      return queue.makeSucceededFuture(())
    }
    // Complete successfully with accumulator upon completion of the fold
    future.whenSuccess { promise.success(accumulator) }
    // Fail with an error if an error is encountered during the fold
    future.whenFail { promise.fail($0) }
    return promise.future
  }
  
  /// Returns a new `Future<Value>` that succeeds only if all of the provided
  /// futures succeed.
  ///
  /// The new `Future<Value>` will contain all of the values resolved by the
  /// futures in the same order, the futures were passed in.
  ///
  /// The returned `Future<Value>` will fail as soon as a fail is encountered.
  ///
  /// - parameters:
  ///   - futures: An array of `Future<Value>`s to wait on for resolved values.
  ///   - queue: The `DispatchQueue` to which the new `Future` will be tied.
  /// - returns: A new `Future<Value>` with all the resolved results of the
  ///   provided futures.
  public static func whenAllSucceed(
    _ futures: [Future<Value>],
    on queue: DispatchQueue
  ) -> Future<[Value]> {
    let promise = queue.makePromise(of: Void.self)
    // An array of eventual values
    var results: [Value?] = .init(repeating: nil, count: futures.count)
    // Number of remaining futures
    var remaining = futures.count
    
    // Handles `value` being resolved by the `index`th future
    func completion(_ index: Int, _ value: Value) {
      // Assign the value
      results[index] = value
      remaining -= 1
      guard remaining == 0 else { return }
      // Succeed the the returned future iff all of the futures completed
      promise.success(())
    }
    
    for (index, future) in futures.enumerated() {
      // Ensure we hop to the the given `queue` first
      future.hop(to: queue).whenComplete { result in
        switch result {
        case .success(let value):
          completion(index, value)
        // When first fialure encountered, fail the promise
        case .failure(let error) where !promise.future.isComplete:
          promise.fail(error)
        // Ignore all subsequent failures
        case .failure:
          break
        }
      }
    }
    
    return promise.future.map {
      assert(results.allSatisfy { $0 != nil })
      return results.map { $0! }
    }
  }
}

// MARK: - Completion all

extension Future {
  /// Returns a new `Future` that succeeds when all of the provided `Future`s
  /// complete. The new `Future` will contain an array of results, maintaining
  /// ordering for each of the `Future`s.
  ///
  /// The returned `Future` always succeeds, regardless of any failures from the
  /// waiting futures.
  ///
  /// - parameters:
  ///   - futures: An array of `Future<Value>`s to gather results from.
  ///   - queue: The `DispatchQueue` to which the new `Future` will be tied.
  /// - returns: A new `Future` with all the results of the provided futures.
  public static func whenAllComplete(
    _ futures: [Future<Value>],
    on queue: DispatchQueue
  ) -> Future<[Result<Value, Error>]> {
    let promise = queue.makePromise(of: Void.self)
    // An array of the evnetial result values
    var results: [Result<Value, Error>?] =
      .init(repeating: nil, count: futures.count)
    // Number of remaining futures
    var remaining = futures.count
    
    // Handles `result` of `index`th future
    func completion(_ index: Int, _ result: Result<Value, Error>) {
      // Assign the result
      results[index] = result
      remaining -= 1
      guard remaining == 0 else { return }
      // Succeed the the returned future iff all of the futures completed
      promise.success(())
    }
    
    for (index, future) in futures.enumerated() {
      // Ensure we hop to the the given `queue` first
      future.hop(to: queue).whenComplete { result in
        completion(index, result)
      }
    }
    
    return promise.future.map { _ in
      assert(results.allSatisfy { $0 != nil })
      return results.map { $0! }
    }
  }
}
