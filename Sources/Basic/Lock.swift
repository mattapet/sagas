//
//  Lock.swift
//  Run
//
//  Created by Peter Matta on 3/14/19.
//

import Foundation

public final class Lock {
  fileprivate let mutex: UnsafeMutablePointer<pthread_mutex_t> =
    UnsafeMutablePointer.allocate(capacity: 1)
  
  public init() {
    let err = pthread_mutex_init(mutex, nil)
    precondition(err == 0)
  }
  
  deinit {
    let err = pthread_mutex_destroy(mutex)
    precondition(err == 0)
    mutex.deallocate()
  }
  
  public func lock() {
    let err = pthread_mutex_lock(mutex)
    precondition(err == 0)
  }
  
  public func unlock() {
    let err = pthread_mutex_unlock(mutex)
    precondition(err == 0)
  }
}

extension Lock {
  public func withLock<ResultValue>(
    execute body: () throws -> ResultValue
  ) rethrows -> ResultValue {
    lock()
    defer { unlock() }
    return try body()
  }
}
