//
//  RunItComponent.swift
//  RunIt
//
//  Created by Alex Nikishin on 07/07/2016.
//  Copyright © 2016 Alex Nikishin. All rights reserved.
//

import Foundation

class RunItComponent: Component, Runnable {
    
    var isRunning: Bool = false
    
    func run() {
        isRunning = true
    }
    
    func stop() {
        isRunning = false
    }
}