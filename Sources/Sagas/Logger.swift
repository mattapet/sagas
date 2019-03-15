public protocol Logger {
  func log<KeyType: Hashable>(_ message: Message<KeyType>)
}

extension Logger {
  public func log<KeyType>(_ message: Message<KeyType>) {
    print("[LOGGER]: \(message.sagaId):\(message.type):\(message.stepKey)")
  }

  public func logStart<KeyType>(_ saga: Saga<KeyType>) {
    print("[LOGGER]: SAGA START \(saga.name):\(saga.ctx.id)")
  }

  public func logAbort<KeyType>(_ saga: Saga<KeyType>) {
    print("[LOGGER]: SAGA ABORT \(saga.name):\(saga.ctx.id)")
  }

  public func logEnd<KeyType>(_ saga: Saga<KeyType>) {
    print("[LOGGER]: SAGA END \(saga.name):\(saga.ctx.id)")
  }
}
