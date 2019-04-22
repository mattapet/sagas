//
//  HttpJob.swift
//  HttpSagas
//
//  Created by Peter Matta on 4/21/19.
//

import CoreSaga
import Foundation

public enum HttpError: Error {
  case unknown
  case errorResponse(Int, HTTPURLResponse)
}

public final class HttpJob {
  public let url: URL
  public let httpMethod: String
  
  public init(url: URL, httpMethod: String) {
    self.url = url
    self.httpMethod = httpMethod
  }
}

extension HttpJob: Job {
  public func execute(
    using payload: Data?,
    with completion: @escaping (Result<Data?, Error>) -> Void
  ) {
    var req = URLRequest(url: url)
    req.httpMethod = httpMethod
    req.httpBody = payload
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    URLSession.shared.dataTask(with: req) { data, response, error in
      completion(Result {
        if let error = error { print("THROWING"); throw error }
        guard let response = response as? HTTPURLResponse else {
          throw HttpError.unknown
        }
        guard (200...299) ~= response.statusCode else {
          throw HttpError.errorResponse(response.statusCode, response)
        }
        return data
      })
    }.resume()
  }
}
