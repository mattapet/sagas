import Foundation

public enum MessageType {
  case reqStart, reqAbort, reqEnd
  case compStart, compEnd
}

public struct Message<KeyType: Hashable> {
  public let type: MessageType
  public let stepKey: KeyType
  public let sagaId: String
  public let payload: Data
}
