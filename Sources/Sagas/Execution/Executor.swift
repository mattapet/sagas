import Dispatch
import Basic

public class Executor<KeyType: Hashable> {
  public typealias SagaId = String
  public typealias Payload = Message<KeyType>.Payload

  private let mutex = PThreadMutex()
  private var _sagasSynchronized: [SagaId:Saga<KeyType>]
  var sagas: [SagaId:Saga<KeyType>] {
    get {
      return _sagasSynchronized
    }
    set {
      mutex.sync(execute: { _sagasSynchronized = newValue })
    }
  }

  var completions: [SagaId:ActionDisposable]
  public let logger: Logger

  public init(logger: Logger) {
    self._sagasSynchronized = [:]
    self.completions = [:]
    self.logger = logger
  }

  public func register(
    _ definition: SagaDefinition<KeyType>,
    with completion: @escaping () -> ()
  ) {
    let saga = Saga(definition: definition)
    sagas[saga.ctx.id] = saga
    completions[saga.ctx.id] = ActionDisposable(action: completion)
    start(sagaId: saga.ctx.id)
  }
}

extension Executor {
  func start(sagaId: SagaId) {
    guard let saga = sagas[sagaId] else { return }
    let ctx = saga.ctx
    assert(ctx.state == .`init`)
    logger.logStart(saga)
    saga.ctx.state = .started
    DispatchQueue.global().async { [weak self] in
      for step in ctx.steps.values where step.deps.isEmpty {
        self?.dispatch(.requestStart(step: step))
      }
    }
  }

  func compensate(sagaId: SagaId) {
    guard let saga = sagas[sagaId] else { return }
    let ctx = saga.ctx
    assert(ctx.state == .started, "State is \(ctx.state)")
    logger.logAbort(saga)
    saga.ctx.state = .aborted
    for step in ctx.steps.values where step.compDeps.isEmpty {
      dispatch(.compensationStart(step: step))
    }
  }

  func end(sagaId: SagaId) {
    func shouldComplete(_ ctx: SagaContext<KeyType>) -> Bool {
      switch ctx.state {
      case .`init`: return false
      case .done: return false
      case .started: return ctx.steps
        .values.allSatisfy({ $0.state == .done })
      case .aborted: return ctx.steps
        .values.allSatisfy({ $0.state != .started && $0.state != .done })
      }
    }
    guard let saga = sagas[sagaId] else { return }
    guard shouldComplete(saga.ctx) else { return }
    logger.logEnd(saga)
    saga.ctx.state = .done
    DispatchQueue.global().async { [weak self] in
      self?.completions[sagaId]?.dispose()
    }
  }
}

