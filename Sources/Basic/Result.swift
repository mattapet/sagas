//
//  Result.swift
//  CoreSaga
//
//  Created by Peter Matta on 4/11/19.
//

import Foundation

extension Result {
  @discardableResult
  public func lift(action: @escaping (Failure) -> Void) -> Result {
    switch self {
    case .success: return self
    case let .failure(error):
      action(error)
      return self
    }
  }
  
  @discardableResult
  public func peek(action: @escaping (Success) -> Void) -> Result {
    switch self {
    case let .success(result):
      action(result)
      return self
    case .failure: return self
    }
  }
}
