public protocol Disposable {
  var isDisposed: Bool { get }

  func dispose()
}

public final class ActionDisposable: Disposable {
  private var action: (() -> ())?

  public var isDisposed: Bool {
    return action == nil
  }

  public init(action: @escaping (() -> ())) {
    self.action = action
  }

  public func dispose() {
    self.action?()
    self.action = nil
  }
}
