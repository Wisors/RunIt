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
        
        print("Run component in queue " + (String(UTF8String: dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL)) ?? ""))
    }
    
    override func stop() {
        super.stop()
        
        print("Stop component " + (String(UTF8String: dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL)) ?? ""))
    }
}

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        RunIt.add(component: TestComponent(dispatch_queue_create("TestQueue", DISPATCH_QUEUE_CONCURRENT)))
        RunIt.add(component: TestComponent(), forKey: "Main queue")
        RunIt.add(component: TestComponent(dispatch_get_main_queue()), forKey: "Main queue posponed delete")
        RunIt.remove(componentForKey: "Main queue")
        RunIt.remove(TestComponent)
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC))), dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) { 
            RunIt.remove(componentForKey: "Main queue posponed delete")
        }
    }
}

