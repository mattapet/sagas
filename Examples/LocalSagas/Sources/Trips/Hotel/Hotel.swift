//
//  Hotel.swift
//  Run
//
//  Created by Peter Matta on 3/14/19.
//

import Foundation

public struct Hotel: Codable {
  public let hotelId: Int
  public let room: String
  public let checkin: Date
  public let checkout: Date
  public let notes: String?
}
