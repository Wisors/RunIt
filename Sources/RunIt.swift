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
    
    public var runComponentOnAdd: Bool = true
    public var stopComponentOnRemove: Bool = true
    /// Dispatch queue where access is synced. Custom concurrent queue by default. Usually no need to change it.
    lazy public var syncQueue: dispatch_queue_t = dispatch_queue_create("RunIt.Queue", DISPATCH_QUEUE_CONCURRENT)
    /// Dispatch queue where components will be executed if not specified per component queue. MainQueue by default.
    lazy public var runQueue: dispatch_queue_t = dispatch_get_main_queue()
    
    private var components: [String: Component] = [:]
    
    #if DEBUG
    public var suppressAssert: Bool = false
    #endif
    
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
        
        #if DEBUG
        assert(suppressAssert == false && components[key] != nil, "WARNING! Trying to reassign component with new one! Possible data loss situation.")
        #endif
        dispatch_barrier_async(syncQueue) {
            
            self.components[key] = component
            self.postNotification(RunItDidAddComponentNotification, component: component, key: key)
            
            if self.runComponentOnAdd, let runnable = component as? Runnable where runnable.isRunning == false {
                
                let runQueue = runnable.runQueue ?? self.runQueue
                dispatch_async(runQueue, {
                    
                    var stillThere: Bool = false
                    dispatch_sync(self.syncQueue, {
                        if let _ = self.components[key] {
                            stillThere = true
                        }
                    })
                    if stillThere {
                        
                        runnable.run()
                        self.postNotification(RunItDidRunComponentNotification, component: component, key: key)
                    }
                })
            }
        }
    }
    
    // MARK: - Get methods -
    public static func get<T: Component>() -> T? {
        return RunIt.manager.get()
    }
    
    public static func get<T: Component>(comoponentType: T.Type) -> T? {
        return RunIt.manager.get(componentForKey: String(comoponentType))
    }
    
    public static func get<T : Component>(componentForKey key: String) -> T? {
        return RunIt.manager.get(componentForKey: key)
    }
    
    public func get<T: Component>() -> T? {
        
        let key = String(T.Type)
        return get(componentForKey: key)
    }
        
    public func get<T: Component>(comoponentType: T.Type) -> T? {
        return get(componentForKey: String(comoponentType))
    }
    
    public func get<T : Component>(componentForKey key: String) -> T? {
        
        var component: T? = nil
        dispatch_sync(syncQueue) {
            component = self.components[key] as? T
        }
        return component
    }
    
    // MARK - Remove methods -
    public static func remove<T: Component>(component component: T) -> Bool {
        return RunIt.manager.remove(component: component)
    }
    
    public static func remove<T: Component>(comoponentType: T.Type) -> Bool {
        return RunIt.manager.remove(componentForKey: String(comoponentType))
    }
    
    public static func remove(componentForKey key: String) -> Bool {
        return RunIt.manager.remove(componentForKey: key)
    }
    
    public func remove<T: Component>(component component: T) -> Bool {

        let key = String(component.dynamicType)
        return remove(componentForKey: key)
    }
    
    public func remove<T: Component>(comoponentType: T.Type) -> Bool {
        return remove(componentForKey: String(comoponentType))
    }
    
    public func remove(componentForKey key: String) -> Bool {
        
        var result: Component? = nil
        dispatch_sync(syncQueue) {
            result = self.components.removeValueForKey(key)
        }
        if let component = result {
            
            NSNotificationCenter.defaultCenter().postNotificationName(RunItDidRemoveComponentNotification, object: component as? AnyObject, userInfo: [RunItDidRemoveComponentNotification : key])
            if self.stopComponentOnRemove, let runnable = result as? Runnable where runnable.isRunning {
                
                let runQueue = runnable.runQueue ?? self.runQueue
                dispatch_async(runQueue) {
                    
                    runnable.stop()
                    self.postNotification(RunItDidStopComponentNotification, component: component, key: key)
                }
            }
            return true
        }
        return false
    }
    
    // MARK: - Post events - 
    private func postNotification(name: String, component: Component, key: String) {
        
        dispatch_async(dispatch_get_main_queue(), {
            NSNotificationCenter.defaultCenter().postNotificationName(name, object: component as? AnyObject, userInfo: [RunItNotificaionComponentKeyKey : key])
        })
    }
}
