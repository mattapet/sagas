public protocol Disposable {
  var disposed: Bool { get }

  func dispose()
}

public final class ActionDisposable: Disposable {
  private var action: (() -> ())?

  public var disposed: Bool {
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
