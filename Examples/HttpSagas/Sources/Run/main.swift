//
//  main.swift
//  Run
//
//  Created by Peter Matta on 4/21/19.
//

import Basic
import HttpSagas
import CoreSaga
import Foundation

let tripSaga = SagaDefinition(
  name: "trip-saga",
  requests: [
    .request(
      key: "hotel",
      compensation: "hotel-cancel",
      url: "http://localhost:3001/trip"),
    .request(
      key: "car",
      compensation: "car-cancel",
      url: "http://localhost:3002/trip"),
    .request(
      key: "plane",
      compensation: "plane-cancel",
      url: "http://localhost:3003/trip"),
    .request(
      key: "payment",
      dependencies: ["hotel", "car", "plane"],
      compensation: "payment-cancel",
      url: "http://localhost:3004/trip"),
  ],
  compensations: [
    .compensation(
      key: "hotel-cancel",
      url: "http://localhost:3001/trip/cancel"),
    .compensation(
      key: "car-cancel",
      url: "http://localhost:3002/trip/cancel"),
    .compensation(
      key: "plane-cancel",
      url: "http://localhost:3003/trip/cancel"),
    .compensation(
      key: "payment-cancel",
      url: "http://localhost:3004/trip/cancel"),
  ])

public final class SagaExecutor
  : BaseSagaExecutor<HttpSaga, HttpSagaExecutionFactory<KeyValueStore>>
{}

//let executor = HttpExecutor()
let store = try KeyValueStore(filename: "http-sagas.json")
let repository = HttpRepository(store: store)
let factory =
  HttpSagaExecutionFactory(executor: HttpExecutor(), repository: repository)
let executor = SagaExecutor(factory: factory)

let saga = HttpSaga(definition: tripSaga)
try store.setValue(SagaEntry(definition: tripSaga), forKey: saga.sagaId)

try await(saga, executor.register)
print("Done.")
