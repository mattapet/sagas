//
//  CollectionExtension.swift
//  Run
//
//  Created by Peter Matta on 3/14/19.
//


extension Collection where Index == Int {
  var randomElement: Element {
    return self[Int.random(in: startIndex..<endIndex)]
  }
}
