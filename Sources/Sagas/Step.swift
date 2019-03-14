public enum StepState {
  case `init`, started, aborted, done
  case compensated
}

public struct Step<KeyType: Hashable> {
  public typealias SagaId = String

  public let state: StepState
  public let sagaId: SagaId
  public let key: KeyType
  public let deps: [KeyType]
  public let compDeps: [KeyType]
  public let req: Task.Type
  public let comp: Task.Type
}
