fileprivate var id: Int = 0

public enum SagaState {
  case `init`, started, aborted, done
}

public struct SagaContext<KeyType: Hashable> {
  public let id: String
  public var state: SagaState
  public var steps: [KeyType:Step<KeyType>]

  public init(id: String) {
    self.id = id
    self.state = .`init`
    self.steps = [:]
  }
}

public class Saga<KeyType: Hashable> {
  public var ctx: SagaContext<KeyType>
  public let name: String
  public let reqSucc: [KeyType:[KeyType]]
  public let compSucc: [KeyType:[KeyType]]

  public init(
    ctx: SagaContext<KeyType>,
    name: String,
    reqSucc: [KeyType:[KeyType]],
    compSucc: [KeyType:[KeyType]]
  ) {
    self.ctx = ctx
    self.name = name
    self.reqSucc = reqSucc
    self.compSucc = compSucc
  }

  public init(definition: SagaDefinition<KeyType>) {
    defer { id += 1}
    self.ctx = SagaContext(id: "\(id)")
    self.name = definition.name
    self.reqSucc = definition.requestSuccessors
    self.compSucc = definition.compensatingSuccessors

    let requestMap = definition.requestMap
    let compensationsMap = definition.compensationsMap

    let steps = definition.requests.compactMap { request -> Step<KeyType>? in
      let compDeps = (reqSucc[request.key] ?? [])
        .compactMap { requestMap[$0]?.key }
      guard let comp = compensationsMap[request.compensation]
        else { return nil }

      return Step<KeyType>(
        state: .`init`,
        sagaId: "\(id)",
        key: request.key,
        deps: request.dependencies,
        compDeps: compDeps,
        req: request.task,
        comp: comp.task
      )
    }
    self.ctx.steps = steps.reduce(into: [:]) { $0[$1.key] = $1 }
  }
}

extension SagaDefinition {
  fileprivate var requestMap: [KeyType:RequestType] {
    return requests.reduce(into: [:]) { $0[$1.key] = $1 }
  }

  fileprivate var compensationsMap: [KeyType:CompensationType] {
    return compensations.reduce(into: [:]) { $0[$1.key] = $1 }
  }

  fileprivate var requestSuccessors: [KeyType:[KeyType]] {
    let successors: [KeyType:Set<KeyType>] = requests
      .reduce(into: [:]) { result, next in
        next.dependencies.forEach {
          result[$0, default: []].insert(next.key)
        }
      }
    return successors.mapValues(Array.init)
  }

  fileprivate var compensatingSuccessors: [KeyType:[KeyType]] {
    let successors: [KeyType:Set<KeyType>] = requests
      .reduce(into: [:]) { result, next in
        next.dependencies.forEach {
          result[next.compensation, default: []].insert($0)
        }
      }
    return successors.mapValues(Array.init)
  }
}
