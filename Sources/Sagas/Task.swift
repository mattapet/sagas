import Foundation

public protocol Task {
  init()

  func execute(
    using payload: Data?,
    with completion: (Result<Data?, Error>) -> Void
  )
}
