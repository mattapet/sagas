//
//  KeyValueStore.swift
//  Run
//
//  Created by Peter Matta on 4/22/19.
//

import Foundation

fileprivate let encoder = JSONEncoder()
fileprivate let decoder = JSONDecoder()

public enum KeyValueStoreError: Error {
  case keyNotExists(String)
}

public final class KeyValueStore {
  private var store: [String:Data]
  private let filename: String
  
  public init(filename: String) throws {
    let fileUrl = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
      .appendingPathComponent(filename)

    self.filename = filename
    if FileManager.default.fileExists(atPath: fileUrl.absoluteString) {
      let data = try Data(contentsOf: fileUrl)
      self.store = try decoder.decode([String:Data].self, from: data)
    } else {
      self.store = [:]
    }
  }
  
  private func save() throws {
    let fileUrl = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
      .appendingPathComponent(filename)
    try encoder.encode(store).write(to: fileUrl)
  }
}

extension KeyValueStore {
  public var keys: [String] {
    return Array(store.keys)
  }
  
  public var values: [Data] {
    return Array(store.values)
  }
}

extension KeyValueStore {
  public func setValue<Value: Encodable>(
    _ value: Value,
    forKey key: String
  ) throws {
    let data = try encoder.encode(value)
    store.updateValue(data, forKey: key)
    try save()
  }
  
  public func loadValue<Value: Decodable>(
    forKey key: String,
    as type: Value.Type
  ) throws -> Value {
    guard let data = store[key] else {
      throw KeyValueStoreError.keyNotExists(key)
    }
    return try decoder.decode(type, from: data)
  }
}
