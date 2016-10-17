//
//  ViewController.swift
//  RunIt
//
//  Created by Alex Nikishin on 07/07/2016.
//  Copyright © 2016 Alex Nikishin. All rights reserved.
//

import UIKit

class TestComponent: RunItComponent {
    
    override func run() {
        super.run()
        
        print("Run component in queue " + DispatchQueue.currentLabel)
    }
    
    override func stop() {
        super.stop()
        
        print("Stop component in queue " + DispatchQueue.currentLabel)
    }
}

extension DispatchQueue {
    
    class var currentLabel: String {
        return String(validatingUTF8: __dispatch_queue_get_label(nil)) ?? "Unknown queue"
    }
}

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        RunIt.add(component: TestComponent(runQueue: DispatchQueue(label: "TestQueue", attributes: DispatchQueue.Attributes.concurrent)))
        RunIt.add(component: TestComponent(), forKey: "Main queue")
        RunIt.add(component: TestComponent(runQueue: DispatchQueue.main), forKey: "Main queue posponed delete")
        RunIt.remove(componentForKey: "Main queue")
        RunIt.remove(TestComponent.self)
        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).asyncAfter(deadline: DispatchTime.now() + .seconds(1)) {
            RunIt.remove(componentForKey: "Main queue posponed delete")
        }
    }
}

