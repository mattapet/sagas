import Foundation

public enum MessageType: String {
  case transactionStart
  case transactionAbort
  case transactionEnd
  case compensationStart
  case compensationEnd
}

public struct Message {
  public let type: MessageType
  public let sagaId: String
  public let stepKey: String
}

extension Message {
  public static func transactionStart(
    sagaId: String,
    stepKey: String
  ) -> Message {
    return Message(
      type: .transactionStart,
      sagaId: sagaId,
      stepKey: stepKey
    )
  }
  
  public static func transactionAbort(
    sagaId: String,
    stepKey: String
  ) -> Message {
    return Message(
      type: .transactionAbort,
      sagaId: sagaId,
      stepKey: stepKey
    )
  }
  
  public static func transactionEnd(
    sagaId: String,
    stepKey: String
  ) -> Message {
    return Message(
      type: .transactionEnd,
      sagaId: sagaId,
      stepKey: stepKey
    )
  }
  
  public static func compensationStart(
    sagaId: String,
    stepKey: String
  ) -> Message {
    return Message(
      type: .compensationStart,
      sagaId: sagaId,
      stepKey: stepKey
    )
  }
  
  public static func compensationEnd(
    sagaId: String,
    stepKey: String
  ) -> Message {
    return Message(
      type: .compensationEnd,
      sagaId: sagaId,
      stepKey: stepKey
    )
  }
}

