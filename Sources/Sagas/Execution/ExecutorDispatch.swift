import Foundation

extension Executor {
  public func dispatch(_ message: Message<KeyType>) {
    DispatchQueue.global().async { [weak self] in
//      print("[DISPATCHER]: \(message.type):\(message.stepKey)")
      guard let saga = self?.sagas[message.sagaId] else { return }
      let ctx = saga.ctx
      guard let step = ctx.steps[message.stepKey] else { return }
      
      switch (ctx.state, message.type, step.state) {
      case (.started, .reqStart, .`init`):
        self?.logger.log(message)
        let step = step.withState(.started)
        saga.ctx.steps[message.stepKey] = step
        self?.startStep(step, using: message.payload)
        
      case (.started, .reqAbort, .started):
        self?.logger.log(message)
        let step = step.withState(.aborted)
        saga.ctx.steps[message.stepKey] = step
        self?.abortStep(step)
        
      case (.started, .reqEnd, .started):
        self?.logger.log(message)
        let step = step.withState(.done)
        saga.ctx.steps[message.stepKey] = step
        self?.endStep(step, with: message.payload)
        
      case (.aborted, .compStart, .`init`),
           (.aborted, .compStart, .aborted):
        // If the request did not succeed or have not started yet,
        // delegate compensation
        self?.skipCompensateStep(step)
        
      case (.aborted, .compStart, .done),
           (.aborted, .compStart, .started):
        self?.logger.log(message)
        self?.compensateStep(step, with: message.payload)
        
      case (.aborted, .compEnd, .done),
           (.aborted, .compEnd, .started):
        self?.logger.log(message)
        let step = step.withState(.compensated)
        saga.ctx.steps[message.stepKey] = step
        self?.endCompensateStep(step, with: message.payload)
        
      default: print(
        "Ignoring message \(ctx.state):\(message.type):\(message.stepKey)"
        )
      }
    }
  }

  func execute(
    _ task: Task,
    using payload: Data?,
    with completion: (Result<Data?, Error>) -> Void
  ) {
    task.execute(using: payload, with: completion)
  }

  func startStep(
    _ step: Step<KeyType>,
    using payload: Message<KeyType>.Payload?
  ) {
    assert(step.state == .started)
    execute(step.reqTask, using: payload) { result in
      switch result {
      case .success(let response):
        dispatch(.requestEnd(step: step, payload: response))
      case .failure:
        dispatch(.requestAbort(step: step))
      }
    }
  }

  func abortStep(_ step: Step<KeyType>) {
    assert(step.state == .aborted)
    compensate(sagaId: step.sagaId)
  }

  func endStep(_ step: Step<KeyType>, with payload: Data? = nil) {
    assert(step.state == .done)
    guard let saga = sagas[step.sagaId] else { return }
    let payload = saga.payload
    let ctx = saga.ctx

    let successors = saga.reqSucc[step.key] ?? []
    // Get all dependents
    for succ in successors {
      guard let succ = ctx.steps[succ] else { continue }
      let steps = ctx.steps
      // If all of the dependencies of successor are done
      if succ.deps.allSatisfy({ steps[$0]?.state == .done }) {
        dispatch(.requestStart(step: succ, payload: payload))
      }
    }
    end(sagaId: ctx.id)
  }

  func compensateStep(_ step: Step<KeyType>, with payload: Data? = nil) {
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

  func skipCompensateStep(_ step: Step<KeyType>) {
    assert(step.state == .`init` || step.state == .aborted)
    guard let saga = sagas[step.sagaId] else { return }
    let payload = saga.payload
    let ctx = saga.ctx
    
    let successors = saga.compSucc[step.key] ?? []
    // Get all dependents
    for succ in successors {
      guard let succ = ctx.steps[succ] else { continue }
      dispatch(.compensationStart(step: succ, payload: payload))
    }
    end(sagaId: ctx.id)
  }

  func endCompensateStep(_ step: Step<KeyType>, with payload: Data? = nil) {
    assert(step.state == .compensated)
    guard let saga = sagas[step.sagaId] else { return }
    let payload = saga.payload
    let ctx = saga.ctx

    let successors = saga.compSucc[step.key] ?? []
    // Get all dependents
    for succ in successors {
      guard let succ = ctx.steps[succ] else { continue }
      dispatch(.compensationStart(step: succ, payload: payload))
    }
    end(sagaId: ctx.id)
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
