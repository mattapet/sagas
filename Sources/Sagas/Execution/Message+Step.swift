extension Message {
  public static func requestStart<KeyType: Hashable>(
    step: Step<KeyType>,
    payload: Payload? = nil
  ) -> Message<KeyType> {
    return Message<KeyType>(
      type: .reqStart,
      stepKey: step.key,
      sagaId: step.sagaId,
      payload: payload
    )
  }
  
  public static func requestAbort<KeyType: Hashable>(
    step: Step<KeyType>,
    payload: Payload? = nil
    ) -> Message<KeyType> {
    return Message<KeyType>(
      type: .reqAbort,
      stepKey: step.key,
      sagaId: step.sagaId,
      payload: payload
    )
  }
  
  public static func requestEnd<KeyType: Hashable>(
    step: Step<KeyType>,
    payload: Payload? = nil
    ) -> Message<KeyType> {
    return Message<KeyType>(
      type: .reqEnd,
      stepKey: step.key,
      sagaId: step.sagaId,
      payload: payload
    )
  }
  
  public static func compensationStart<KeyType: Hashable>(
    step: Step<KeyType>,
    payload: Payload? = nil
    ) -> Message<KeyType> {
    return Message<KeyType>(
      type: .compStart,
      stepKey: step.key,
      sagaId: step.sagaId,
      payload: payload
    )
  }
  
  public static func compensationEnd<KeyType: Hashable>(
    step: Step<KeyType>,
    payload: Payload? = nil
    ) -> Message<KeyType> {
    return Message<KeyType>(
      type: .compEnd,
      stepKey: step.key,
      sagaId: step.sagaId,
      payload: payload
    )
  }
}

