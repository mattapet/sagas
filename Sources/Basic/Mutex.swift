import Foundation

public class PThreadMutex {
  var mutex: pthread_mutex_t

  public init() {
    mutex = pthread_mutex_t()
  }

  public func sync<Result>(execute: () throws -> Result) rethrows -> Result {
    pthread_mutex_lock(&mutex)
    defer { pthread_mutex_unlock(&mutex) }
    return try execute()
  }
}
