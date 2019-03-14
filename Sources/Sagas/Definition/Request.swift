public struct Request<KeyType: Hashable> {
  public let key: KeyType
  public let dependencies: [KeyType]
  public let compensation: KeyType
  public let task: Task.Type
}
