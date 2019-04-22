//
//  SimpleSagaExecutor.swift
//  LocalSagas
//
//  Created by Peter Matta on 4/15/19.
//

import CoreSaga
import Foundation

public func register(
  definition: SagaDefinition,
  using payload: Data? = nil,
  with completion: @escaping (Result<Data?, Error>) -> Void
) {
  let saga = SimpleSaga(definition: definition, payload: payload)
  SimpleSagaExecutor.shared.register(saga: saga, with: completion)
}

public final class SimpleSagaExecutor
  : BaseSagaExecutor<SimpleSaga, SimpleSagaExecutionFactory>
{
  private static let _shared: SimpleSagaExecutor = SimpleSagaExecutor()
  public static var shared: SimpleSagaExecutor {
    return _shared
  }
  
  fileprivate init() {
    super.init(factory: .shared)
  }
}
