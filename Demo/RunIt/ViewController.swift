//
//    Copyright (c) 2015-2017 Nikishin Alexander https://twitter.com/wisdors
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy of
//    this software and associated documentation files (the "Software"), to deal in
//    the Software without restriction, including without limitation the rights to
//    use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//    the Software, and to permit persons to whom the Software is furnished to do so,
//    subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//    FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//    COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//    IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//    CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

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

