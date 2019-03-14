import Foundation

public class Executor<KeyType: Hashable> {
  public typealias SagaId = String

  var sagas: [SagaId:Saga<KeyType>]
  public let logger: Logger

  public init(logger: Logger) {
    self.sagas = [:]
    self.logger = logger
  }

  public func register(_ definition: SagaDefinition<KeyType>) {
    let saga = Saga(definition: definition)
    sagas[saga.ctx.id] = saga
    start(sagaId: saga.ctx.id)
  }
}

extension Executor {
  func start(sagaId: SagaId) {
    guard let saga = sagas[sagaId] else { return }
    assert(saga.ctx.state == .`init`)
    logger.logStart(saga)
    saga.ctx.state = .started
    for step in saga.ctx.steps.values where step.deps.isEmpty {
      dispatch(.requestStart(step: step, payload: Data()))
    }
  }

  func compensate(sagaId: SagaId) {
    guard let saga = sagas[sagaId] else { return }
    assert(saga.ctx.state == .started)
    logger.logAbort(saga)
    saga.ctx.state = .aborted
    for step in saga.ctx.steps.values where step.compDeps.isEmpty {
      dispatch(.compensationStart(step: step, payload: Data()))
    }
  }

  func end(sagaId: SagaId) {
    guard let saga = sagas[sagaId] else { return }
    assert(saga.ctx.state == .started || saga.ctx.state == .aborted)
    logger.logEnd(saga)
    saga.ctx.state = .done
  }
}

extension Message {
  public static func requestStart<KeyType: Hashable>(
    step: Step<KeyType>,
    payload: Data
  ) -> Message<KeyType> {
    return Message<KeyType>(
      type: .reqStart,
      stepKey: step.key,
      sagaId: step.sagaId,
      payload: payload
    )
  }

  public static func requestAbort<KeyType: Hashable>(
    step: Step<KeyType>,
    payload: Data
  ) -> Message<KeyType> {
    return Message<KeyType>(
      type: .reqAbort,
      stepKey: step.key,
      sagaId: step.sagaId,
      payload: payload
    )
  }

  public static func requestEnd<KeyType: Hashable>(
    step: Step<KeyType>,
    payload: Data
  ) -> Message<KeyType> {
    return Message<KeyType>(
      type: .reqEnd,
      stepKey: step.key,
      sagaId: step.sagaId,
      payload: payload
    )
  }

  public static func compensationStart<KeyType: Hashable>(
    step: Step<KeyType>,
    payload: Data
  ) -> Message<KeyType> {
    return Message<KeyType>(
      type: .compStart,
      stepKey: step.key,
      sagaId: step.sagaId,
      payload: payload
    )
  }

  public static func compensationEnd<KeyType: Hashable>(
    step: Step<KeyType>,
    payload: Data
  ) -> Message<KeyType> {
    return Message<KeyType>(
      type: .compEnd,
      stepKey: step.key,
      sagaId: step.sagaId,
      payload: payload
    )
  }
}

