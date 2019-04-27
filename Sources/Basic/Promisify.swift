//
//  Promisify.swift
//  Basic
//
//  Created by Peter Matta on 4/26/19.
//

import Foundation

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

public func promisify<Arg1, ResultType, ErrorType>(
  on queue: DispatchQueue,
  _ body: @escaping (Arg1, @escaping (Result<ResultType, ErrorType>) -> Void) -> Void
) -> ((Arg1) -> Future<ResultType>) {
  return { arg1 in
    promisify(on: queue) { body(arg1, $0) }()
  }
}

public func promisify<Arg1, Arg2, ResultType, ErrorType>(
  on queue: DispatchQueue,
  _ body: @escaping (Arg1, Arg2, @escaping (Result<ResultType, ErrorType>) -> Void) -> Void
) -> (Arg1, Arg2) -> Future<ResultType> {
  return { arg1, arg2 in
    promisify(on: queue) { body(arg1, arg2, $0) }()
  }
}

public func promisify<Arg1, Arg2, Arg3, ResultType, ErrorType>(
  on queue: DispatchQueue,
  _ body: @escaping (Arg1, Arg2, Arg3, @escaping (Result<ResultType, ErrorType>) -> Void) -> Void
) -> (Arg1, Arg2, Arg3) -> Future<ResultType> {
  return { arg1, arg2, arg3 in
    promisify(on: queue) { body(arg1, arg2, arg3, $0) }()
  }
}

public func promisify<Arg1, Arg2, Arg3, Arg4, ResultType, ErrorType>(
  on queue: DispatchQueue,
  _ body: @escaping (Arg1, Arg2, Arg3, Arg4, @escaping (Result<ResultType, ErrorType>) -> Void) -> Void
) -> (Arg1, Arg2, Arg3, Arg4) -> Future<ResultType> {
  return { arg1, arg2, arg3, arg4 in
    promisify(on: queue) { body(arg1, arg2, arg3, arg4, $0) }()
  }
}

public func promisify<Arg1, Arg2, Arg3, Arg4, Arg5, ResultType, ErrorType>(
  on queue: DispatchQueue,
  _ body: @escaping (Arg1, Arg2, Arg3, Arg4, Arg5, @escaping (Result<ResultType, ErrorType>) -> Void) -> Void
) -> (Arg1, Arg2, Arg3, Arg4, Arg5) -> Future<ResultType> {
  return { arg1, arg2, arg3, arg4, arg5 in
    promisify(on: queue) { body(arg1, arg2, arg3, arg4, arg5, $0) }()
  }
}

public func promisify<Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, ResultType, ErrorType>(
  on queue: DispatchQueue,
  _ body: @escaping (Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, @escaping (Result<ResultType, ErrorType>) -> Void) -> Void
) -> (Arg1, Arg2, Arg3, Arg4, Arg5, Arg6) -> Future<ResultType> {
  return { arg1, arg2, arg3, arg4, arg5, arg6 in
    promisify(on: queue) { body(arg1, arg2, arg3, arg4, arg5, arg6, $0) }()
  }
}
