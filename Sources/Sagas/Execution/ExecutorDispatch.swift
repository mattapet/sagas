import Foundation

extension Executor {
  public func dispatch(_ message: Message<KeyType>) {
    print("[DISPATCHING: \(message)]")
    guard let saga = sagas[message.sagaId] else { return }
    guard let step = saga.ctx.steps[message.stepKey] else { return }

    switch (message.type, step.state) {
    case (.reqStart, .`init`):
      logger.log(message)
      let step = step.withState(.started)
      saga.ctx.steps[message.stepKey] = step
      start(step, using: message.payload)

    case (.reqAbort, .started):
      logger.log(message)
      let step = step.withState(.aborted)
      saga.ctx.steps[message.stepKey] = step
      abort(step)

    case (.reqEnd, .started):
      logger.log(message)
      let step = step.withState(.done)
      saga.ctx.steps[message.stepKey] = step
      end(step, with: message.payload)

    case (.compStart, .`init`), (.compStart, .aborted):
      // If the request did not succeed or have not started,
      // delegate compensation
      print("Skipping")
      skipCompensate(step)
      break

    case (.compStart, .done), (.compStart, .started):
      logger.log(message)
      compensate(step, with: message.payload)

    case (.compEnd, .done), (.compEnd, .started):
      logger.log(message)
      endComp(step, with: message.payload)

    default: fatalError("Unreachable state \(message.type):\(step.state)")
    }
  }

  func execute(
    _ task: Task,
    using payload: Data,
    with completion: (Result<Data, Error>) -> Void
  ) {
    task.execute(using: payload, with: completion)
  }

  func start(_ step: Step<KeyType>, using payload: Data) {
    assert(step.state == .started)
    execute(step.reqTask, using: payload) { result in
      switch result {
      case .success(let response):
        dispatch(.requestEnd(step: step, payload: response))
      case .failure(let error):
        print(error)
        dispatch(.requestAbort(step: step, payload: Data()))
      }
    }
  }

  func abort(_ step: Step<KeyType>) {
    assert(step.state == .aborted)
    compensate(sagaId: step.sagaId)
  }

  func end(_ step: Step<KeyType>, with payload: Data) {
    assert(step.state == .done)
    guard let saga = sagas[step.sagaId] else { return }

    let successors = saga.reqSucc[step.key] ?? []
    // Get all dependents
    for succ in successors {
      guard let succ = saga.ctx.steps[succ] else { continue }
      // If all of the dependencies of successor are done
      if succ.deps.allSatisfy({ saga.ctx.steps[$0]?.state == .done }) {
        dispatch(.requestStart(step: succ, payload: payload))
      }
    }
  }

  func compensate(_ step: Step<KeyType>, with payload: Data) {
    assert(step.state == .done || step.state == .started)
    execute(step.compTask, using: payload) { result in
      switch result {
      case .success(let payload):
        dispatch(.compensationEnd(step: step, payload: payload))
      case .failure:
        dispatch(.compensationStart(step: step, payload: payload))
      }
    }
  }

  func skipCompensate(_ step: Step<KeyType>) {
    assert(step.state == .`init` || step.state == .aborted)
    guard let saga = sagas[step.sagaId] else { return }

    let successors = saga.compSucc[step.key] ?? []
    print("Compensation successors \(successors)")
    // Get all dependents
    for succ in successors {
      guard let succ = saga.ctx.steps[succ] else { continue }
      func shouldCompensate(_ key: KeyType) -> Bool {
        guard let step = saga.ctx.steps[key] else { return false }
        switch step.state {
        case .done, .started: return true
        case .compensated, .`init`, .aborted: return false
        }
      }

      // If all of the dependencies of successor are done
      if succ.compDeps.allSatisfy(shouldCompensate) {
        print("Successor to be compensated \(succ)")
        dispatch(.compensationStart(step: succ, payload: Data()))
      }
    }
  }

  func endComp(_ step: Step<KeyType>, with payload: Data) {
    assert(step.state == .compensated)
    guard let saga = sagas[step.sagaId] else { return }

    let successors = saga.compSucc[step.key] ?? []
    // Get all dependents
    for succ in successors {
      guard let succ = saga.ctx.steps[succ] else { continue }
      func shouldCompensate(_ key: KeyType) -> Bool {
        guard let step = saga.ctx.steps[key] else { return false }
        switch step.state {
        case .compensated, .`init`, .aborted: return true
        case .done, .started: return false
        }
      }

      // If all of the dependencies of successor are done
      if succ.compDeps.allSatisfy(shouldCompensate) {
        dispatch(.compensationStart(step: succ, payload: payload))
      }
    }
  }
}

extension Step {
  func withState(_ state: StepState) -> Step<KeyType> {
    return Step<KeyType>(
      state: state,
      sagaId: self.sagaId,
      key: self.key,
      deps: self.deps,
      compDeps: self.compDeps,
      req: self.req,
      comp: self.comp
    )
  }

  var reqTask: Task {
    return req.init()
  }

  var compTask: Task {
    return comp.init()
  }
}


