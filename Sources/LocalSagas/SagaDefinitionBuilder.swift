//
//  SagaDefinitionBuilder.swift
//  LocalSagas
//
//  Created by Peter Matta on 3/21/19.
//

import Sagas
import Foundation

public final class SagaDefinitionBuilder {
  private let name: String
  private var requests: [Request]
  private var compensations: [Compensation]
  
  public init(name: String) {
    self.name = name
    self.requests = []
    self.compensations = []
  }
  
  public func build() -> SagaDefinition {
    return SagaDefinition(
      name: name,
      requests: requests,
      compensations: compensations
    )
  }
}

extension SagaDefinitionBuilder {
  public func with(
    name: String = UUID().uuidString,
    transaction: @escaping (Data?, (Result<Data?, Error>) -> Void) -> Void,
    compensation: @escaping (Data?, (Result<Data?, Error>) -> Void) -> Void
  ) -> SagaDefinitionBuilder {
    guard let previous = requests.last else {
      return self
        .with(compensation: .compensation(task: compensation))
        .with(request:
          .request(
            key: name,
            compensation: compensations.last!.key,
            task: LocalTask(closure: transaction)
          )
      )
    }
    return with(
      name: name,
      previous: previous.key,
      transaction: transaction,
      compensation: compensation
    )
  }
  
  public func with(
    name: String = UUID().uuidString,
    previous: String,
    transaction: @escaping (Data?, (Result<Data?, Error>) -> Void) -> Void,
    compensation: @escaping (Data?, (Result<Data?, Error>) -> Void) -> Void
  ) -> SagaDefinitionBuilder {
    return self
      .with(compensation: .compensation(task: compensation))
      .with(request:
        .request(
          key: name,
          dependencies: [previous],
          compensation: compensations.last!.key,
          task: LocalTask(closure: transaction)
        )
    )
  }
  
  public func with(request: Request) -> SagaDefinitionBuilder {
    requests.append(request)
    return self
  }
  
  public func with(compensation: Compensation) -> SagaDefinitionBuilder {
    compensations.append(compensation)
    return self
  }
}

// MARK: - Builder operators

infix operator |>: AdditionPrecedence

public func |> (
  _ lhs: SagaDefinitionBuilder.TransactionPair,
  _ rhs: SagaDefinitionBuilder.TransactionPair
) -> SagaDefinitionBuilder {
  let name = UUID().uuidString
  return SagaDefinitionBuilder(name: name) |> lhs |> rhs
}

public func |> (
  _ lhs: SagaDefinitionBuilder.NamedTransactionPair,
  _ rhs: SagaDefinitionBuilder.TransactionPair
) -> SagaDefinitionBuilder {
  let name = UUID().uuidString
  return SagaDefinitionBuilder(name: name) |> lhs |> rhs
}

public func |> (
  _ lhs: SagaDefinitionBuilder.TransactionPair,
  _ rhs: SagaDefinitionBuilder.NamedTransactionPair
) -> SagaDefinitionBuilder {
  let name = UUID().uuidString
  return SagaDefinitionBuilder(name: name) |> lhs |> rhs
}

public func |> (
  _ lhs: SagaDefinitionBuilder.NamedTransactionPair,
  _ rhs: SagaDefinitionBuilder.NamedTransactionPair
) -> SagaDefinitionBuilder {
  let name = UUID().uuidString
  return SagaDefinitionBuilder(name: name) |> lhs |> rhs
}

extension SagaDefinitionBuilder {
  public typealias TransactionPair = (
    request: (Data?, (Result<Data?, Error>) -> Void) -> Void,
    compensation: (Data?, (Result<Data?, Error>) -> Void) -> Void
  )
  public typealias NamedTransactionPair = (
    name: String,
    request: (Data?, (Result<Data?, Error>) -> Void) -> Void,
    compensation: (Data?, (Result<Data?, Error>) -> Void) -> Void
  )
  
  public static func |> (
    _ lhs: SagaDefinitionBuilder,
    _ rhs: TransactionPair
  ) -> SagaDefinitionBuilder {
    return lhs.with(
      transaction: rhs.request,
      compensation: rhs.compensation
    )
  }
  
  public static func |> (
    _ lhs: SagaDefinitionBuilder,
    _ rhs: NamedTransactionPair
  ) -> SagaDefinitionBuilder {
    return lhs.with(
      name: rhs.name,
      transaction: rhs.request,
      compensation: rhs.compensation
    )
  }
}

// MARK: - Defintion extensions

extension SagaDefinition {
  public init(builder: SagaDefinitionBuilder) {
    self = builder.build()
  }
  
  public init(builderClosure: () -> SagaDefinitionBuilder) {
    self = builderClosure().build()
  }
}

extension Request {
  fileprivate static func request(
    dependencies: [String],
    compensation: String,
    task: @escaping (Data?, (Result<Data?, Error>) -> Void) -> Void
  ) -> Request {
    let key = UUID().uuidString
    return request(
      key: key,
      dependencies: dependencies,
      compensation: compensation,
      task: LocalTask(closure: task)
    )
  }
  
  fileprivate static func request(
    compensation: String,
    task: @escaping (Data?, (Result<Data?, Error>) -> Void) -> Void
  ) -> Request {
    let key = UUID().uuidString
    return request(
      key: key,
      compensation: compensation,
      task: LocalTask(closure: task)
    )
  }
}

extension Compensation {
  fileprivate static func compensation(
    task: @escaping (Data?, (Result<Data?, Error>) -> Void) -> Void
  ) -> Compensation {
    let key = UUID().uuidString
    return compensation(
      key: key,
      task: LocalTask(closure: task)
    )
  }
}
