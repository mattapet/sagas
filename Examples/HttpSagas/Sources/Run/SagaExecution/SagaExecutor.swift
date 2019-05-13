//
//  SagaExecutor.swift
//  Run
//
//  Created by Peter Matta on 5/6/19.
//

import CoreSaga
import HttpSagas

final class SagaExecutor
  : BaseSagaExecutor<HttpSaga, HttpSagaExecutionFactory<Store>> {}
