//
//  Promisify.swift
//  Basic
//
//  Created by Peter Matta on 4/26/19.
//

import Foundation

/// Transforms given function from a callback-based API to a promise-future
/// based API binding futures to the given `queue`.
///
/// This is a convenience function that creates a wrapper around the functions
/// with a standard callback-based API. The `promisify` function  produces a
/// version of the original function, that instead of taking a callback as the
/// last argument, returns a `Future<Value>`.
///
/// Consider an example `networkCall` function:
///
///     func netowrkCall(
///       _ args: Any,
///       _ completion: @escaping (Result<Value, Error>) -> Void
///     ) -> Void {
///       DispatchQueue.global().async {
///         /* Perform an anctual network call */
///         // In case of success
///         completion(.success(response))
///         // In case of failure
///         completion(.failure(error))
///       }
///     }
///
/// Then typical usage of such `networkCall` function would look something like:
///
///     networkCall(args) { result in
///       queue.async {
///         switch result {
///         case .success(let value):
///           // Consume value, perform another netowork call, ...
///         case .failure(let error):
///           // Handle error, perform recovery, ...
///       }
///     }
///
/// However `promisify` allows you to do something like:
///
///     let networkCallAsync = promisify(on: queue, netowrkCall)
///     let future = networkCallAsync(args)
///     /* Call any map, flatMap methods */
///     future.whenSucceed { result in
///       // Consume value
///     }
///     future.whenFailed { error in
///       // Consume error
///     }
///
/// Note that `promisify` all of the `Futures` to the given dispatch queue.
///
/// Note that `promisify` should be mainly used to convert public APIs of third
/// parties, such as libraries, frameworks, which you cannot change yourself, to
/// make integration easier.
///
/// ### Limitations
///
/// Because of the swift type system, currently `promisify` supports only
/// functions with 0-6 additional arguments.
///
/// To allow any number of arguments the swift compiler required some kind of
/// variadic types, which have not been introduced yet.
///
/// Also, 6 as maximum number of arguments is arbitraty. It was chosen because
/// it is somewhat unlikely for a function to have 7 or more argument.
/// Furthe more it is considered a bad API deisgn by the swift API guildlines.
///
/// - parameters:
///   - queue: Dispatch queue to be used to tie all of the `Futured` to.
///   - body: fundtion that is to be wrapped.
/// - returns: A promisified funtion that mirrors the interface of `body` with
///   exception of callback omittion and returning `Future<ResultType>`.
/// - seealso: `Promise<Value>`, `Future<Value>`
public func promisify<ResultType, ErrorType>(
  on queue: DispatchQueue,
  _ body: @escaping (@escaping (Result<ResultType, ErrorType>) -> Void) -> Void
) -> () -> Future<ResultType> {
  return {
    let promise = queue.makePromise(of: ResultType.self)
    body { result in
      switch result {
      case .success(let value): promise.success(value)
      case .failure(let error): promise.fail(error)
      }
    }
    return promise.future
  }
}

/// Transforms given function from a callback-based API to a promise-future
/// based API binding futures to the given `queue`.
///
/// This is a specialization of `promisify` for funtios with 1 argument. For
/// the full description see `promisify`.
///
/// - parameters:
///   - queue: Dispatch queue to be used to tie all of the `Futured` to.
///   - body: fundtion that is to be wrapped.
/// - returns: A promisified funtion that mirrors the interface of `body` with
///   exception of callback omittion and returning `Future<ResultType>`.
public func promisify<Arg1, ResultType, ErrorType>(
  on queue: DispatchQueue,
  _ body: @escaping (Arg1, @escaping (Result<ResultType, ErrorType>) -> Void) -> Void
) -> (Arg1) -> Future<ResultType> {
  return { arg1 in
    promisify(on: queue) { body(arg1, $0) }()
  }
}

/// Transforms given function from a callback-based API to a promise-future
/// based API binding futures to the given `queue`.
///
/// This is a specialization of `promisify` for funtios with 2 arguments. For
/// the full description see `promisify`.
///
/// - parameters:
///   - queue: Dispatch queue to be used to tie all of the `Futured` to.
///   - body: fundtion that is to be wrapped.
/// - returns: A promisified funtion that mirrors the interface of `body` with
///   exception of callback omittion and returning `Future<ResultType>`.
public func promisify<Arg1, Arg2, ResultType, ErrorType>(
  on queue: DispatchQueue,
  _ body: @escaping (Arg1, Arg2, @escaping (Result<ResultType, ErrorType>) -> Void) -> Void
) -> (Arg1, Arg2) -> Future<ResultType> {
  return { arg1, arg2 in
    promisify(on: queue) { body(arg1, arg2, $0) }()
  }
}

/// Transforms given function from a callback-based API to a promise-future
/// based API binding futures to the given `queue`.
///
/// This is a specialization of `promisify` for funtios with 3 arguments. For
/// the full description see `promisify`.
///
/// - parameters:
///   - queue: Dispatch queue to be used to tie all of the `Futured` to.
///   - body: fundtion that is to be wrapped.
/// - returns: A promisified funtion that mirrors the interface of `body` with
///   exception of callback omittion and returning `Future<ResultType>`.
public func promisify<Arg1, Arg2, Arg3, ResultType, ErrorType>(
  on queue: DispatchQueue,
  _ body: @escaping (Arg1, Arg2, Arg3, @escaping (Result<ResultType, ErrorType>) -> Void) -> Void
) -> (Arg1, Arg2, Arg3) -> Future<ResultType> {
  return { arg1, arg2, arg3 in
    promisify(on: queue) { body(arg1, arg2, arg3, $0) }()
  }
}

/// Transforms given function from a callback-based API to a promise-future
/// based API binding futures to the given `queue`.
///
/// This is a specialization of `promisify` for funtios with 4 arguments. For
/// the full description see `promisify`.
///
/// - parameters:
///   - queue: Dispatch queue to be used to tie all of the `Futured` to.
///   - body: fundtion that is to be wrapped.
/// - returns: A promisified funtion that mirrors the interface of `body` with
///   exception of callback omittion and returning `Future<ResultType>`.
public func promisify<Arg1, Arg2, Arg3, Arg4, ResultType, ErrorType>(
  on queue: DispatchQueue,
  _ body: @escaping (Arg1, Arg2, Arg3, Arg4, @escaping (Result<ResultType, ErrorType>) -> Void) -> Void
) -> (Arg1, Arg2, Arg3, Arg4) -> Future<ResultType> {
  return { arg1, arg2, arg3, arg4 in
    promisify(on: queue) { body(arg1, arg2, arg3, arg4, $0) }()
  }
}

/// Transforms given function from a callback-based API to a promise-future
/// based API binding futures to the given `queue`.
///
/// This is a specialization of `promisify` for funtios with 5 arguments. For
/// the full description see `promisify`.
///
/// - parameters:
///   - queue: Dispatch queue to be used to tie all of the `Futured` to.
///   - body: fundtion that is to be wrapped.
/// - returns: A promisified funtion that mirrors the interface of `body` with
///   exception of callback omittion and returning `Future<ResultType>`.
public func promisify<Arg1, Arg2, Arg3, Arg4, Arg5, ResultType, ErrorType>(
  on queue: DispatchQueue,
  _ body: @escaping (Arg1, Arg2, Arg3, Arg4, Arg5, @escaping (Result<ResultType, ErrorType>) -> Void) -> Void
) -> (Arg1, Arg2, Arg3, Arg4, Arg5) -> Future<ResultType> {
  return { arg1, arg2, arg3, arg4, arg5 in
    promisify(on: queue) { body(arg1, arg2, arg3, arg4, arg5, $0) }()
  }
}

/// Transforms given function from a callback-based API to a promise-future
/// based API binding futures to the given `queue`.
///
/// This is a specialization of `promisify` for funtios with 6 arguments. For
/// the full description see `promisify`.
///
/// - parameters:
///   - queue: Dispatch queue to be used to tie all of the `Futured` to.
///   - body: fundtion that is to be wrapped.
/// - returns: A promisified funtion that mirrors the interface of `body` with
///   exception of callback omittion and returning `Future<ResultType>`.
public func promisify<Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, ResultType, ErrorType>(
  on queue: DispatchQueue,
  _ body: @escaping (Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, @escaping (Result<ResultType, ErrorType>) -> Void) -> Void
) -> (Arg1, Arg2, Arg3, Arg4, Arg5, Arg6) -> Future<ResultType> {
  return { arg1, arg2, arg3, arg4, arg5, arg6 in
    promisify(on: queue) { body(arg1, arg2, arg3, arg4, arg5, arg6, $0) }()
  }
}
