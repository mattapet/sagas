import Foundation

public enum MessageType: String, Codable {
  case transactionStart
  case transactionAbort
  case transactionEnd
  case compensationStart
  case compensationEnd
}

public struct Message: Codable {
  public let type: MessageType
  public let sagaId: String
  public let stepKey: String
  public let payload: Data?
}

extension Message {
  public static func transactionStart(
    sagaId: String,
    stepKey: String,
    payload: Data? = nil
  ) -> Message {
    return Message(
      type: .transactionStart,
      sagaId: sagaId,
      stepKey: stepKey,
      payload: payload
    )
  }
  
  public static func transactionAbort(
    sagaId: String,
    stepKey: String,
    payload: Data? = nil
  ) -> Message {
    return Message(
      type: .transactionAbort,
      sagaId: sagaId,
      stepKey: stepKey,
      payload: payload
    )
  }
  
  public static func transactionEnd(
    sagaId: String,
    stepKey: String,
    payload: Data? = nil
  ) -> Message {
    return Message(
      type: .transactionEnd,
      sagaId: sagaId,
      stepKey: stepKey,
      payload: payload
    )
  }
  
  public static func compensationStart(
    sagaId: String,
    stepKey: String,
    payload: Data? = nil
  ) -> Message {
    return Message(
      type: .compensationStart,
      sagaId: sagaId,
      stepKey: stepKey,
      payload: payload
    )
  }
  
  public static func compensationEnd(
    sagaId: String,
    stepKey: String,
    payload: Data? = nil
  ) -> Message {
    return Message(
      type: .compensationEnd,
      sagaId: sagaId,
      stepKey: stepKey,
      payload: payload
    )
  }
}

