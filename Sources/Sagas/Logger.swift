public protocol Logger {
  func log(_ message: Message)
}

extension Logger {
  public func log(_ message: Message) {
    print("[LOGGER]: \(message.sagaId):\(message.type):\(message.stepKey)")
  }

  public func logStart(_ saga: Saga) {
    print("[LOGGER]: SAGA START \(saga.name):\(saga.sagaId)")
  }

  public func logAbort(_ saga: Saga) {
    print("[LOGGER]: SAGA ABORT \(saga.name):\(saga.sagaId)")
  }

  public func logEnd(_ saga: Saga) {
    print("[LOGGER]: SAGA END \(saga.name):\(saga.sagaId)")
  }
}
