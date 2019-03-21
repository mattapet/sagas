import Foundation

public protocol Task {
  func execute(
    using payload: Data?,
    with completion: (Result<Data?, Error>) -> Void
  )
}
