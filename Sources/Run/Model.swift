//
//  Model.swift
//  Run
//
//  Created by Peter Matta on 3/15/19.
//

import Basic
import Foundation

fileprivate var _lock: Lock = Lock()
fileprivate var _storage: [String:AnyObject] = [:]

/// Prints all storages.
///
/// - description:
///     This operation is thread safe.
func dumpStorage() {
  _lock.withLock {
    for (key, value) in _storage {
      print("Key: \(key)")
      print(value.description!)
    }
  }
}

func addFilters<K: Hashable, V>(to storage: Storage<K, V>) {
  storage.addLoadFilter { (_, next) in
    // Adds latency
    usleep(500_000)
    next(.success(nil))
  }
  storage.addSaveFilter { (_, _, next) in
    // Adds latency
    usleep(500_000)
    next(.success(nil))
  }
  storage.addSaveFilter { (_, _, next) in
    // Adds 50% error rate
    if Int.random(in: 0..<10) < 5 {
      next(.success(nil))
    } else {
      next(.failure(StorageError.internalFailue))
    }
  }
}

/// Lazy initiation style storage getter for the given type
///
/// - description:
///     Each type is guaranteed to retrieve it's own, unique storage instance.
///     When creating a new storage instance, the `addFilters(to:)` method is
///     used to modify it.
///     This function guarantees thread safety of the storage access.
func storage<T: Model>(for modelType: T.Type) -> Storage<T.Key, T> {
  // Get name of the type
  let type = "\(modelType.self)"
  // Make sure we're thread safe
  return _lock.withLock {
    guard let storage = _storage[type] else {
      let storage = Storage<T.Key, T>()
      // Apply storage filters
      addFilters(to: storage)
      _storage[type] = storage
      return storage
    }
    return storage as! Storage<T.Key, T>
  }
}

/// Protocol that any entity that wishes to be stored must conform to.
///
/// - description:
///     `Model` protocol provides default operations for storing and looking up
///     instances of the entity models. By default all of the methods are
///     synchronous.
///
/// - see:
///     `AsyncModel`
public protocol Model {
  associatedtype Key: Hashable
  
  var key: Key { get }
  
  /// Saved the model entity synchronously.
  func saveSync() throws -> Self?
  
  /// Loads an entity by the given key synchronously.
  static func loadSync(byKey key: Key) throws -> Self?
}

public protocol AsyncModel: Model {
  /// Saved the model entity asynchronously.
  func save(with completion: @escaping (Result<Self?, Error>) -> Void)
  
  /// Loads an entity by the given key asynchronously.
  static func load(
    byKey key: Key,
    with completion: @escaping (Result<Self?, Error>) -> Void
  )
}

extension Model {
  @discardableResult
  public func saveSync() throws -> Self? {
    let result = storage(for: Self.self).saveSync(self, forKey: key)
    switch result {
    case .success(let payload): return payload
    case .failure(let error): throw error
    }
  }
  
  public static func loadSync(byKey key: Key) throws -> Self? {
    let result = storage(for: Self.self).loadSync(byKey: key)
    switch result {
    case .success(let payload): return payload
    case .failure(let error): throw error
    }
  }
}

/// Protocol that any entity that wishes to be stored in asynchronous fashion
/// must conform to.
///
/// - description:
///     `AsyncModel` protocol provides default operations for storing and
///     looking up instances of the entity models *asynchronously* . This
///     protocol extends `Model` protocol, that provides basic synchronous API.
///
/// - see:
///     `Model`
extension AsyncModel {
  public func save(with completion: @escaping (Result<Self?, Error>) -> Void) {
    return storage(for: Self.self).save(self, forKey: key, with: completion)
  }
  
  public static func load(
    byKey key: Key,
    with completion: @escaping (Result<Self?, Error>) -> Void
  ) {
    return storage(for: Self.self).load(byKey: key, with: completion)
  }
}
