//
//  ExecutionFactory.swift
//  CoreSaga
//
//  Created by Peter Matta on 4/15/19.
//

import Foundation

public protocol ExecutionFactory {
  associatedtype SagaType
  associatedtype ExecutionType: Execution
    where SagaType == ExecutionType.SagaType
  
  func create(from: SagaType) -> ExecutionType
}

