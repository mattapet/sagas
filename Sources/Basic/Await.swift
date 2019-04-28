//
//  Await.swift
//  Basic
//
//  Created by Peter Matta on 3/21/19.
//

import Dispatch

/// Converts an asynchronous method having callback using `Result` enum to
/// synchronous.
///
/// - parameters:
///   - body: The async function must be called inside this body and closure
///     provided in the parameter should be passed to the async method's
///     completion handler.
/// - returns: The value wrapped by the async method's result.
/// - throws: The error wrapped by the async method's result.
@discardableResult
public func await<ResultType, ErrorType>(
  _ body: (@escaping (Result<ResultType, ErrorType>) -> Void) -> Void
) throws -> ResultType {
  let lock = Lock()
  let group = DispatchGroup()
  var result: Result<ResultType, ErrorType>? = nil
  group.enter()
  body { theResult in
    lock.withLock {
      result = theResult
      group.leave()
    }
  }
  group.wait()
  return try result!.get()
}

@discardableResult
public func await<ResultType, ErrorType, Arg1>(
  _ arg1: Arg1,
  _ body: (Arg1, @escaping (Result<ResultType, ErrorType>) -> Void) -> Void
) throws -> ResultType {
  return try await { body(arg1, $0) }
}

@discardableResult
public func await<ResultType, ErrorType, Arg1, Arg2>(
  _ arg1: Arg1, _ arg2: Arg2,
  _ body: (Arg1, Arg2, @escaping (Result<ResultType, ErrorType>) -> Void) -> Void
) throws -> ResultType {
  return try await { body(arg1, arg2, $0) }
}

@discardableResult
public func await<ResultType, ErrorType, Arg1, Arg2, Arg3>(
  _ arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3,
  _ body: (Arg1, Arg2, Arg3, @escaping (Result<ResultType, ErrorType>) -> Void) -> Void
) throws -> ResultType {
  return try await { body(arg1, arg2, arg3, $0) }
}

@discardableResult
public func await<ResultType, ErrorType, Arg1, Arg2, Arg3, Arg4>(
  _ arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3, _ arg4: Arg4,
  _ body: (Arg1, Arg2, Arg3, Arg4, @escaping (Result<ResultType, ErrorType>) -> Void) -> Void
) throws -> ResultType {
  return try await { body(arg1, arg2, arg3, arg4, $0) }
}

@discardableResult
public func await<ResultType, ErrorType, Arg1, Arg2, Arg3, Arg4, Arg5>(
  _ arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3, _ arg4: Arg4, _ arg5: Arg5,
  _ body: (Arg1, Arg2, Arg3, Arg4, Arg5, @escaping(Result<ResultType, ErrorType>) -> Void) -> Void
) throws -> ResultType {
  return try await { body(arg1, arg2, arg3, arg4, arg5, $0) }
}

@discardableResult
public func await<ResultType, ErrorType, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6>(
  _ arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3, _ arg4: Arg4, _ arg5: Arg5, _ arg6: Arg6,
  _ body: (Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, @escaping (Result<ResultType, ErrorType>) -> Void) -> Void
) throws -> ResultType {
  return try await { body(arg1, arg2, arg3, arg4, arg5, arg6, $0) }
}

