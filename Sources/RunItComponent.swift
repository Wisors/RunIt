//
//  RunItComponent.swift
//  RunIt
//
//  Created by Alex Nikishin on 07/07/2016.
//  Copyright © 2016 Alex Nikishin. All rights reserved.
//

import Foundation

public class RunItComponent: Component, Runnable {
    
    private(set) public var isRunning: Bool
    
    public init() {
        isRunning = false
    }
    
    public func run() {
        isRunning = true
    }
    
    public func stop() {
        isRunning = false
    }
}