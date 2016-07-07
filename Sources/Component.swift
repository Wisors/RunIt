//
//  RunItComponent.swift
//  RunIt
//
//  Created by Alex Nikishin on 07/07/2016.
//  Copyright © 2016 Alex Nikishin. All rights reserved.
//

import Foundation

public protocol Component {}

public protocol Runable {
    
    var isRunning: Bool {get}
    
    func run()
    func stop()
}