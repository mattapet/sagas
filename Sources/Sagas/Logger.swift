public protocol Logger {
  func log(_ message: Message)
  func logRegisterd(_ definition: SagaDefinition)
  func logStart(_ saga: Saga)
  func logAbort(_ saga: Saga)
  func logEnd(_ saga: Saga)
}

public protocol PersistentLogger: Logger {
  func loadDefinitions() -> [SagaDefinition]
  func loadSagas() -> [String]
  func loadMessages(for sagaId: String) -> [Message]
}
