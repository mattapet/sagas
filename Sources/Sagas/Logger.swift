public protocol Logger {
  func log(_ message: Message)
  func logStart(_ saga: Saga)
  func logAbort(_ saga: Saga)
  func logEnd(_ saga: Saga)
}
