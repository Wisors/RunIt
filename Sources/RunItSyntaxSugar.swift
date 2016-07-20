//
//    Copyright (c) 2015 Nikishin Alexander https://twitter.com/wisdors
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

import Foundation

public extension RunIt {
    
    public static var runComponentOnAdd: Bool {
        set { RunIt.manager.runComponentOnAdd = newValue }
        get { return RunIt.manager.runComponentOnAdd }
    }
    public static var stopComponentOnRemove: Bool {
        set { RunIt.manager.stopComponentOnRemove = newValue }
        get { return RunIt.manager.stopComponentOnRemove }
    }
    public static var syncQueue: dispatch_queue_t {
        set { RunIt.manager.syncQueue = newValue }
        get { return RunIt.manager.syncQueue }
    }
    public static var runOperationQueue: NSOperationQueue {
        return RunIt.manager.runOperationQueue
    }
    
    // MARK: - Add -
    public static func add(component component: Component) {
        RunIt.manager.add(component: component)
    }
    
    public static func add(component component: Component, forKey key: String) {
        RunIt.manager.add(component: component, forKey: key)
    }
    
    // MARK: - Get -
    public static func get<T: Component>() -> T? {
        return RunIt.manager.get()
    }
    
    public static func get<T: Component>(comoponentType: T.Type) -> T? {
        return RunIt.manager.get(componentForKey: String(comoponentType))
    }
    
    public static func get<T : Component>(componentForKey key: String) -> T? {
        return RunIt.manager.get(componentForKey: key)
    }
    
    // MARK: - Remove -
    public static func remove<T: Component>(component component: T) -> Bool {
        return RunIt.manager.remove(component: component)
    }
    
    public static func remove<T: Component>(comoponentType: T.Type) -> Bool {
        return RunIt.manager.remove(componentForKey: String(comoponentType))
    }
    
    public static func remove(componentForKey key: String) -> Bool {
        return RunIt.manager.remove(componentForKey: key)
    }
}