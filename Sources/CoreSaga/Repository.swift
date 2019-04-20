//
//  Repository.swift
//  CoreSaga
//
//  Created by Peter Matta on 4/4/19.
//

import Basic
import Foundation

public protocol Repository {
  associatedtype SagaType: AnySaga
  
  func query(_ saga: SagaType) throws -> SagaType
  func execute(_ command: Command, on saga: SagaType) throws -> SagaType
}
