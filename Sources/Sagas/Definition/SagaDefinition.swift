public struct SagaDefinition<KeyType: Hashable> {
  public typealias RequestType = Request<KeyType>
  public typealias CompensationType = Compensation<KeyType>

  public let name: String
  public let requests: [RequestType]
  public let compensations: [CompensationType]

  public init(
    name: String,
    requests: [RequestType],
    compensations: [CompensationType]
  ) {
    self.name = name
    self.requests = requests
    self.compensations = compensations
  }
}

extension Request {
  public static func request<KeyType: Hashable>(
    key: KeyType,
    dependencies: [KeyType],
    compensation: KeyType,
    task: Task.Type
  ) -> Request<KeyType> {
    return Request<KeyType>(
      key: key,
      dependencies: dependencies,
      compensation: compensation,
      task: task
    )
  }

  public static func request<KeyType: Hashable>(
    key: KeyType,
    compensation: KeyType,
    task: Task.Type
  ) -> Request<KeyType> {
    return Request<KeyType>(
      key: key,
      dependencies: [],
      compensation: compensation,
      task: task
    )
  }
}

extension Compensation {
  public static func compensation<KeyType: Hashable>(
    key: KeyType,
    task: Task.Type
  ) -> Compensation<KeyType> {
    return Compensation<KeyType>(
      key: key,
      task: task
    )
  }
}
