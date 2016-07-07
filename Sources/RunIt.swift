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

public class RunIt: Manager, Component {
    
    public static let manager: RunIt = RunIt()
    
    public var runComponentsOnAdd: Bool = true
    public var suppressAssert: Bool = false
    
    private var components: [String: Component] = [:]
    private var syncQueue: dispatch_queue_t = dispatch_queue_create("RunIt.Queue", DISPATCH_QUEUE_CONCURRENT)
    
    // MARK: - Add methods -
    public static func add(component component: Component) {
        RunIt.manager.add(component: component)
    }
    
    public static func add(component component: Component, forKey key: String) {
        RunIt.manager.add(component: component, forKey: key)
    }
    
    public func add(component component: Component) {
        
        let key = String(component.dynamicType)
        add(component: component, forKey: key)
    }
    
    public func add(component component: Component, forKey key: String) {
        
        assert(suppressAssert == false && components[key] != nil, "WARNING! Trying to reassign component with new one! Possible data loss situation.")
        dispatch_barrier_async(syncQueue) {
            
            self.components[key] = component
            
            guard self.runComponentsOnAdd, let runable = component as? Runable else { return }
            runable.run()
        }
    }
    
    // MARK: - Get methods -
    public static func get<T: Component>() -> T? {
        return RunIt.manager.get()
    }
    
    public static func get<T : Component>(componentForKey key: String) -> T? {
        return RunIt.manager.get(componentForKey: key)
    }
    
    func get<T: Component>() -> T? {
        
        let key = String(T.Type)
        return get(componentForKey: key)
    }
    
    func get<T : Component>(componentForKey key: String) -> T? {
        
        var component: T? = nil
        dispatch_sync(syncQueue) {
            component = self.components[key] as? T
        }
        return component
    }
    
    // MARK - Remove methods -
    public static func remove(component component: Component) -> Bool {
        return RunIt.manager.remove(component: component)
    }
    
    public static func remove(componentForKey key: String) -> Bool {
        return RunIt.manager.remove(componentForKey: key)
    }
    
    func remove(component component: Component) -> Bool {
        
        let key = String(component.dynamicType)
        return remove(componentForKey: key)
    }
    
    func remove(componentForKey key: String) -> Bool {
        
        var result: Component? = nil
        dispatch_sync(syncQueue) {
            result = self.components.removeValueForKey(key)
        }
        return result != nil
    }
}