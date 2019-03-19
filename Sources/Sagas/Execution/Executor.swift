import Dispatch
import Basic

/// Class that manager saga execution.
///
/// - description:
///   Executor is (or at least should be...) a thread safe class responsible for
///   correct execution of each saga.
///
/// - see:
///    `Message`
public class Executor<KeyType: Hashable> {
  public typealias SagaId = String
  public typealias Payload = Message<KeyType>.Payload

  private let lock: Lock
  private var _sagasSynchronized: [SagaId:Saga<KeyType>]
  var sagas: [SagaId:Saga<KeyType>] {
    get { return lock.withLock { _sagasSynchronized } }
    set { lock.withLock { _sagasSynchronized = newValue } }
  }

  var completions: [SagaId:ActionDisposable]
  public let logger: Logger

  public init(logger: Logger) {
    self.lock = Lock()
    self._sagasSynchronized = [:]
    self.completions = [:]
    self.logger = logger
  }
}

extension Executor {
  public func register(
    _ definition: SagaDefinition<KeyType>,
    using payload: Saga<KeyType>.Payload? = nil,
    with completion: @escaping () -> ()
  ) {
    let saga = Saga(definition: definition, payload: payload)
    sagas[saga.ctx.id] = saga
    completions[saga.ctx.id] = ActionDisposable(action: completion)
    start(sagaId: saga.ctx.id)
  }
}

extension Executor {
  func start(sagaId: SagaId) {
    guard let saga = sagas[sagaId] else { return }
    let payload = saga.payload
    let ctx = saga.ctx
    assert(ctx.state == .`init`)
    logger.logStart(saga)
    saga.ctx.state = .started
    for step in ctx.steps.values where step.deps.isEmpty {
      dispatch(.requestStart(step: step, payload: payload))
    }
  }

  func compensate(sagaId: SagaId) {
    guard let saga = sagas[sagaId] else { return }
    let payload = saga.payload
    let ctx = saga.ctx
    assert(ctx.state == .started, "State is \(ctx.state)")
    logger.logAbort(saga)
    saga.ctx.state = .aborted
    for step in ctx.steps.values where step.compDeps.isEmpty {
      dispatch(.compensationStart(step: step, payload: payload))
    }
  }

  func end(sagaId: SagaId) {
    func shouldComplete(_ ctx: SagaContext<KeyType>) -> Bool {
      // Saga is done iff
      switch ctx.state {
      case .`init`: return false
      case .done: return false
      // Saga is `started` and all of the steps are complete (`.done`)
      case .started: return ctx.steps
        .values.allSatisfy({ $0.state == .done })
      // Or saga is `aborted` and none of the steps remain `started` or `done`
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

