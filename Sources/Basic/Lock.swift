//
//  Lock.swift
//  Run
//
//  Created by Peter Matta on 3/14/19.
//

import Foundation

/// A threading lock based on `libpthread`.
///
/// This object provides a lock on top of a single `pthread_mutex_t`.
public final class Lock {
  fileprivate let mutex: UnsafeMutablePointer<pthread_mutex_t> =
    UnsafeMutablePointer.allocate(capacity: 1)
  
  /// Create a new lock.
  public init() {
    let err = pthread_mutex_init(mutex, nil)
    precondition(err == 0)
  }
  
  deinit {
    let err = pthread_mutex_destroy(mutex)
    precondition(err == 0)
    mutex.deallocate()
  }
  
  /// Aquire a lock.
  ///
  /// Direct usage of `lock()` method is discouraged. Consider using `withLock`
  /// method instead to simplify locking.
  public func lock() {
    let err = pthread_mutex_lock(mutex)
    precondition(err == 0)
  }
  
  /// Release the lock.
  ///
  /// Direct usage of `unlock()` method is discouraged. Consider using
  /// `withLock` method instead to simplify locking.
  public func unlock() {
    let err = pthread_mutex_unlock(mutex)
    precondition(err == 0)
  }
}

extension Lock {
  /// Acquire the lock for the duration of the given block.
  ///
  /// This convenience method should be preferred to `lock` and `unlock` in
  /// most situations, as it ensures that the lock will be released regardless
  /// of how `body` exits.
  ///
  /// - parameters:
  ///   - body: The block to execute while holding the lock.
  /// - returns: The value returned by the block.
  public func withLock<ResultValue>(
    execute body: () throws -> ResultValue
  ) rethrows -> ResultValue {
    lock()
    defer { unlock() }
    return try body()
  }
}
