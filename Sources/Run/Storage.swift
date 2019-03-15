//
//  Storage.swift
//  Run
//
//  Created by Peter Matta on 3/14/19.
//

import Basic
import Foundation
import Dispatch

public enum StorageError: Error {
  case valueForKeyNotFound
  case internalFailue
}

public class Storage<Key: Hashable, Value> {
  public typealias NextFuntion = (Result<Value?, Error>) -> ()
  public typealias LoadFilter = (Key, NextFuntion) -> ()
  public typealias SaveFilter = (Key, Value, NextFuntion) -> ()
  
  private var _mutex: PThreadMutex
  private var _storage: [Key:Value]
  private var loadFilters: [LoadFilter] = []
  private var saveFilters: [SaveFilter] = []
  
  public init() {
    self._mutex = PThreadMutex()
    self._storage = [:]
  }
}

// MARK: - Base filter and save implementation -- Private

extension Storage {
  private func load(_ key: Key, _ next: NextFuntion) {
    next(Result { [weak self] in
      try self?._mutex.sync { [weak self] () throws -> Value in
        guard let value = self?._storage[key] else {
          throw StorageError.valueForKeyNotFound
        }
        return value
      }
    })
  }
  
  private func save(_ key: Key, _ value: Value, _ next: NextFuntion) {
    next(Result { [weak self] in
      try self?._mutex.sync { [weak self] () throws -> Value? in
        return self?._storage.updateValue(value, forKey: key)
      }
    })
  }
}

// MARK: - Filter methods

extension Storage {
  public func addLoadFilter(_ filter: @escaping LoadFilter) {
    loadFilters.append(filter)
  }
  
  public func addSaveFilter(_ filter: @escaping SaveFilter) {
    saveFilters.append(filter)
  }
}

// MARK: - Load methods

extension Storage {
  public func load(
    byKey key: Key,
    with completion: @escaping (Result<Value?, Error>) -> ()
  ) {
    DispatchQueue.global().async { [weak self] in
      self?.loadImpl(byKey: key, with: completion)
    }
  }
  
  public func loadSync(byKey key: Key) -> Result<Value?, Error> {
    var result: Result<Value?, Error> = .failure(StorageError.internalFailue)
    loadImpl(byKey: key) { result = $0 }
    return result
  }
  
  private func loadImpl(
    byKey key: Key,
    with completion: @escaping (Result<Value?, Error>) -> ()
  ) {
    var iterator = loadFilters.reversed().makeIterator()
    
    func apply() {
      if let filter = iterator.next() {
        return filter(key) { result in
          switch result {
          case .success(let result):
            guard let res = result else { return apply() }
            return completion(.success(res))
          case .failure(let error): return completion(.failure(error))
          }
        }
      }
      load(key, completion)
    }
    apply()
  }
  
}

// MARK: - Save methods

extension Storage {
  public func save(
    _ value: Value,
    forKey key: Key,
    with completion: @escaping (Result<Value?, Error>) -> ()
  ) {
    DispatchQueue.global().async { [weak self] in
      self?.saveImpl(value, forKey: key, with: completion)
    }
  }
  
  public func saveSync(
    _ value: Value,
    forKey key: Key
  ) -> Result<Value?, Error> {
    var result: Result<Value?, Error> = .failure(StorageError.internalFailue)
    self.saveImpl(value, forKey: key) { result = $0 }
    return result
  }
  
  private func saveImpl(
    _ value: Value,
    forKey key: Key,
    with completion: @escaping (Result<Value?, Error>) -> ()
  ) {
    var iterator = saveFilters.reversed().makeIterator()
    func apply() {
      if let filter = iterator.next() {
        return filter(key, value) { result in
          switch result {
          case .success(let result):
            guard let res = result else { return apply() }
            return completion(.success(res))
          case .failure(let error): return completion(.failure(error))
          }
        }
      }
      save(key, value, completion)
    }
    apply()
  }
}

