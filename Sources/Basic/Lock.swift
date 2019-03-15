//
//  Lock.swift
//  Run
//
//  Created by Peter Matta on 3/14/19.
//

import Foundation

public class Lock {
  private var mutex: PThreadMutex
  
  public init(mutex: PThreadMutex) {
    self.mutex = mutex
    pthread_mutex_lock(&mutex.mutex)
  }
  
  deinit {
    pthread_mutex_unlock(&mutex.mutex)
  }
}
